import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:core_auth/core_auth.dart';
import 'dart:math' as math;

import 'package:permission_handler/permission_handler.dart';
import 'package:core_shared/shared/core/services/navigation_provider.dart';
import 'package:core_shared/shared/models/business_product.dart';
import 'package:core_shared/shared/models/cart_item.dart';
import 'package:consumer_app/apps/consumer/cart/cart_provider.dart';
import 'package:consumer_app/apps/consumer/repositories/consumer_shop_repository.dart';
import 'package:consumer_app/apps/consumer/business/business_provider.dart';
import 'package:consumer_app/apps/consumer/checkout/checkout_page.dart';
import 'package:consumer_app/apps/consumer/profile/support_chat_page.dart';
import 'package:consumer_app/apps/consumer/orders/order_history_page.dart';

class VoiceAssistantDialog extends ConsumerStatefulWidget {
  const VoiceAssistantDialog({super.key});

  @override
  ConsumerState<VoiceAssistantDialog> createState() => _VoiceAssistantDialogState();
}

class _VoiceAssistantDialogState extends ConsumerState<VoiceAssistantDialog>
    with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  late final AnimationController _pulseController;
  late final AnimationController _rotationController;

  bool _isListening = false;
  bool _isThinking = false;
  String _wordsSpoken = "";
  String _assistantReply = "Merhaba sevgili dostum! Sana nasıl yardımcı olabilirim? (Örn: 'sepetime süt ekle', 'sepetimi boşalt', 'lahmacun ara')";
  
  // Typewriter effect state
  String _displayedReply = "";
  Timer? _typewriterTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _startTypewriter(_assistantReply);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _pulseController.dispose();
    _rotationController.dispose();
    _typewriterTimer?.cancel();
    super.dispose();
  }

  void _startListening() async {
    if (_isThinking) return;
    _typewriterTimer?.cancel();
    setState(() {
      _isListening = true;
      _wordsSpoken = "";
      _displayedReply = "Mikrofon başlatılıyor...";
    });

    _pulseController.repeat(reverse: true);
    _rotationController.repeat();

    try {
      // Request microphone permission manually using permission_handler
      var permissionStatus = await Permission.microphone.status;
      if (!permissionStatus.isGranted) {
        if (permissionStatus.isPermanentlyDenied) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _displayedReply = "Mikrofon izni kalıcı olarak reddedilmiş. Lütfen ayarlardan izin verin.";
            });
            _pulseController.stop();
            _rotationController.stop();
          }
          await openAppSettings();
          return;
        }

        final requestedStatus = await Permission.microphone.request();
        if (!requestedStatus.isGranted) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _displayedReply = "Sesli komut kullanabilmek için mikrofon izni vermeniz gerekmektedir.";
            });
            _pulseController.stop();
            _rotationController.stop();
          }
          return;
        }
      }

      bool available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Voice STT Status: $status');
          if (mounted) {
            setState(() {
              _displayedReply = "Durum: $status\nKonuşmanızı bekliyorum...";
            });
          }
        },
        onError: (errorNotification) {
          debugPrint('Voice STT Error: $errorNotification');
          if (mounted) {
            setState(() {
              _isListening = false;
              _displayedReply = "Mikrofon Hatası: ${errorNotification.errorMsg}\n(Kalıcı mı: ${errorNotification.permanent})";
            });
            _pulseController.stop();
            _rotationController.stop();
          }
        },
      );

      if (available && mounted) {
        await _speech.listen(
          onResult: (result) {
            setState(() {
              _wordsSpoken = result.recognizedWords;
            });
            if (result.finalResult) {
              _onSpeechFinished();
            }
          },
          listenOptions: stt.SpeechListenOptions(
            localeId: 'tr_TR',
            listenMode: stt.ListenMode.confirmation,
            cancelOnError: false,
            partialResults: true,
          ),
        );
      } else if (mounted) {
        setState(() {
          _isListening = false;
          _displayedReply = "Mikrofon başlatılamadı. Cihazınızda ses tanıma hizmeti bulunamadı veya izin verilmedi.";
        });
      }
    } catch (e) {
      debugPrint("STT Listen error: $e");
      if (mounted) {
        setState(() {
          _isListening = false;
          _displayedReply = "Başlatılamadı: $e";
        });
      }
    }
  }

  void _onSpeechFinished() {
    if (!_isListening) return;
    _speech.stop();
    _pulseController.stop();
    _rotationController.stop();

    setState(() {
      _isListening = false;
    });

    if (_wordsSpoken.isNotEmpty) {
      _processCommand(_wordsSpoken);
    } else {
      setState(() {
        _assistantReply = "Herhangi bir komut algılanamadı sevgili dostum. Tekrar konuşmak için mikrofona dokunabilirsin.";
      });
      _startTypewriter(_assistantReply);
    }
  }

  void _processCommand(String command) async {
    setState(() {
      _isThinking = true;
      _assistantReply = "Düşünüyorum...";
      _displayedReply = "Düşünüyorum...";
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        '/api/consumer/support/voice-command',
        body: {'message': command},
      );

      final data = response['data'] as Map<String, dynamic>? ?? {};
      final action = data['action'] as String? ?? 'UNKNOWN';
      final parameters = data['parameters'] as Map<String, dynamic>? ?? {};
      final reply = data['reply'] as String? ?? 'Komutunuzu anlayamadım sevgili dostum.';

      if (mounted) {
        setState(() {
          _isThinking = false;
          _assistantReply = reply;
        });
        _startTypewriter(reply);
        
        // Execute the action with a slight delay so the user can read the reply
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) {
            _executeAction(action, parameters);
          }
        });
      }
    } catch (e) {
      debugPrint("Command process error: $e");
      if (mounted) {
        setState(() {
          _isThinking = false;
          _assistantReply = "Hata oluştu, lütfen tekrar deneyin.";
        });
        _startTypewriter(_assistantReply);
      }
    }
  }

  void _executeAction(String action, Map<String, dynamic> parameters) {
    final navProvider = p.Provider.of<NavigationProvider>(context, listen: false);
    final businessProvider = p.Provider.of<BusinessProvider>(context, listen: false);

    switch (action) {
      case 'ADD_TO_CART':
        final activeBusiness = businessProvider.selectedBusiness;
        if (activeBusiness == null) {
          setState(() {
            _assistantReply = "Sepete ürün eklemek için lütfen önce bir dükkan seçin sevgili dostum.";
          });
          _startTypewriter(_assistantReply);
          return;
        }

        final productName = parameters['productName'] as String? ?? '';
        final quantity = parameters['quantity'] as num? ?? 1;

        if (productName.isEmpty) {
          setState(() {
            _assistantReply = "Eklemek istediğiniz ürün adını anlayamadım.";
          });
          _startTypewriter(_assistantReply);
          return;
        }

        final productsAsync = ref.read(shopProductsProvider(activeBusiness.id));
        final products = productsAsync.value ?? [];
        final match = products.firstWhere(
          (p) => p.product.name.toLowerCase().contains(productName.toLowerCase()),
          orElse: () => null as dynamic,
        ) as BusinessProduct?;

        if (match == null) {
          setState(() {
            _assistantReply = "$productName bu dükkanda bulunamadı sevgili dostum.";
          });
          _startTypewriter(_assistantReply);
        } else {
          try {
            for (int i = 0; i < quantity.toInt(); i++) {
              ref.read(cartProvider.notifier).addToCart(match);
            }
            Navigator.pop(context); // Close assistant
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$quantity adet ${match.product.name} sepete eklendi.")),
            );
          } catch (e) {
            setState(() {
              _assistantReply = e.toString().replaceAll("Exception: ", "");
            });
            _startTypewriter(_assistantReply);
          }
        }
        break;

      case 'REMOVE_FROM_CART':
        final productName = parameters['productName'] as String? ?? '';
        if (productName.isEmpty) return;

        final cart = ref.read(cartProvider);
        final CartItem? item = cart.items.firstWhere(
          (i) => i.businessProduct.product.name.toLowerCase().contains(productName.toLowerCase()),
          orElse: () => null as dynamic,
        );

        if (item == null) {
          setState(() {
            _assistantReply = "Sepetinizde $productName bulunamadı.";
          });
          _startTypewriter(_assistantReply);
        } else {
          ref.read(cartProvider.notifier).removeFromCart(item.businessProduct.id);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${item.businessProduct.product.name} sepetten çıkarıldı.")),
          );
        }
        break;

      case 'CLEAR_CART':
        ref.read(cartProvider.notifier).clearCart();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sepetiniz temizlendi.")),
        );
        break;

      case 'SEARCH_PRODUCT':
        final query = parameters['query'] as String? ?? '';
        if (query.isNotEmpty) {
          ref.read(catalogSearchQueryProvider.notifier).state = query;
          navProvider.setIndex(1); // Go to Search tab
          Navigator.pop(context);
        }
        break;

      case 'NAVIGATE':
        final target = parameters['target'] as String? ?? '';
        if (target == 'home') {
          navProvider.setIndex(0);
          Navigator.pop(context);
        } else if (target == 'cart') {
          navProvider.setIndex(2);
          Navigator.pop(context);
        } else if (target == 'profile') {
          navProvider.setIndex(3);
          Navigator.pop(context);
        } else if (target == 'orders') {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OrderHistoryPage()),
          );
        } else if (target == 'support') {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SupportChatPage()),
          );
        }
        break;

      case 'CHECKOUT':
        final cart = ref.read(cartProvider);
        if (cart.items.isEmpty) {
          setState(() {
            _assistantReply = "Sepetiniz boş olduğu için ödemeye geçemiyorum sevgili dostum.";
          });
          _startTypewriter(_assistantReply);
        } else {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CheckoutPage()),
          );
        }
        break;

      case 'CONFIRM_ORDER':
        // Guides user to complete checkout visually for safety
        setState(() {
          _assistantReply = "Siparişinizi tamamlamak için lütfen ekranın altındaki Sipariş Ver butonuna dokunun.";
        });
        _startTypewriter(_assistantReply);
        break;

      default:
        // Do nothing, just display explanation
        break;
    }
  }

  void _startTypewriter(String text) {
    _typewriterTimer?.cancel();
    setState(() {
      _displayedReply = "";
    });
    int charIndex = 0;
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (charIndex < text.length) {
        if (mounted) {
          setState(() {
            _displayedReply += text[charIndex];
          });
        }
        charIndex++;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 460),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FF66).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.keyboard_voice_rounded,
                            color: Color(0xFF00FF66),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Hoppa Sesli Asistan",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFEEEEEE)),

              // Content Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Assistant Bubble
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[100]!),
                        ),
                        child: Text(
                          _displayedReply,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),

                      // User Speech Preview Bubble (if speaking)
                      if (_wordsSpoken.isNotEmpty || _isListening)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(left: 30),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _wordsSpoken.isEmpty ? "Dinleniyor..." : _wordsSpoken,
                              style: TextStyle(
                                fontSize: 14,
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom Pulsing Mic Action Area
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_isListening) {
                          _onSpeechFinished();
                        } else {
                          _startListening();
                        }
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Rotating Dual-Color Aura
                          AnimatedBuilder(
                            animation: _rotationController,
                            builder: (context, child) {
                              final scale = 1.0 + (_pulseController.value * 0.15);
                              final angle = _rotationController.value * 2 * math.pi;
                              final dx = 8 * math.cos(angle);
                              final dy = 8 * math.sin(angle);
                              return Transform.scale(
                                scale: _isListening ? scale : 1.0,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: _isListening
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF00FF66).withValues(alpha: 0.4),
                                              blurRadius: 16,
                                              offset: Offset(dx, dy),
                                            ),
                                            BoxShadow(
                                              color: const Color(0xFFFF7043).withValues(alpha: 0.4),
                                              blurRadius: 16,
                                              offset: Offset(-dx, -dy),
                                            ),
                                          ]
                                        : [],
                                  ),
                                ),
                              );
                            },
                          ),
                          // Microphone Button Circle
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _isListening
                                    ? [const Color(0xFF00FF66), const Color(0xFF02C39A)]
                                    : [primaryColor, primaryColor.withValues(alpha: 0.85)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Icon(
                              _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isListening
                          ? "Sizi Dinliyorum..."
                          : _isThinking
                              ? "Düşünüyorum..."
                              : "Dokun ve Konuş",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _isListening ? const Color(0xFF00FF66) : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
