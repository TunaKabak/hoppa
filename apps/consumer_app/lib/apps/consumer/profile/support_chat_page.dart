import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:core_shared/shared/models/order.dart';
import 'package:consumer_app/apps/consumer/repositories/consumer_order_repository.dart';
import 'package:consumer_app/apps/consumer/repositories/support_repository.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:consumer_app/apps/consumer/widgets/hoppa_header.dart';

class ChatOption {
  final String id;
  final String label;

  ChatOption({required this.id, required this.label});
}

class MessageModel {
  final String text;
  final bool isUser;
  final DateTime time;
  final List<ChatOption>? options;

  MessageModel({
    required this.text,
    required this.isUser,
    required this.time,
    this.options,
  });
}

class SupportChatPage extends ConsumerStatefulWidget {
  const SupportChatPage({super.key});

  @override
  ConsumerState<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends ConsumerState<SupportChatPage> {
  final List<MessageModel> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  Order? _activeOrder;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(
      MessageModel(
        text: "Merhaba sevgili dostum! Ben Hoppa Asistan. Sana nasıl yardımcı olabilirim?",
        isUser: false,
        time: DateTime.now(),
      ),
    );
    _findActiveOrder();
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      await _speech.initialize(
        onStatus: (status) => debugPrint('Speech status: $status'),
        onError: (errorNotification) => debugPrint('Speech error: $errorNotification'),
      );
    } catch (e) {
      debugPrint('Speech init failed: $e');
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _inputController.text = result.recognizedWords;
            });
          },
          localeId: 'tr_TR', // Turkish language support
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _findActiveOrder() {
    final ordersAsync = ref.read(consumerOrdersProvider);
    if (ordersAsync.value != null && ordersAsync.value!.isNotEmpty) {
      for (var o in ordersAsync.value!) {
        // Active orders: pending, preparing, onWay, readyForPickup
        if (o.status == 'pending' || 
            o.status == 'preparing' || 
            o.status == 'on_way' || 
            o.status == 'ready_for_pickup') {
          setState(() {
            _activeOrder = o;
          });
          return;
        }
      }
      // Fallback: Default to the most recent order (delivered or cancelled)
      setState(() {
        _activeOrder = ordersAsync.value!.first;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = MessageModel(
      text: text,
      isUser: true,
      time: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      final repository = ref.read(supportRepositoryProvider);
      final response = await repository.sendMessageToAssistant(
        message: text,
        activeOrderId: _activeOrder?.id,
      );

      final reply = response['reply'] as String? ?? "Şu anda yanıt veremiyorum.";
      final optionsData = response['options'] as List<dynamic>?;
      List<ChatOption>? options;
      if (optionsData != null) {
        options = optionsData.map((opt) => ChatOption(
          id: opt['id'] as String,
          label: opt['label'] as String,
        )).toList();
      }
      
      if (mounted) {
        setState(() {
          _messages.add(
            MessageModel(
              text: reply,
              isUser: false,
              time: DateTime.now(),
              options: options,
            ),
          );
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            MessageModel(
              text: "Üzgünüm, şu an bağlantıda bir sorun yaşıyorum. Lütfen tekrar deneyin.",
              isUser: false,
              time: DateTime.now(),
            ),
          );
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF00A651);
    final timeFormat = DateFormat('HH:mm');
    final ordersAsync = ref.watch(consumerOrdersProvider);

    // Auto-select first order if none is selected yet
    if (_activeOrder == null && ordersAsync.value != null && ordersAsync.value!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _activeOrder == null) {
          _findActiveOrder();
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE95D22), // Hoppa Orange
              Color(0xFFFF8C00), // Orange-Yellow
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Column(
          children: [
            HoppaHeader(
              height: 70,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: const Icon(Icons.support_agent, color: Colors.white),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Hoppa Asistan",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Akıllı Destek",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FBF9),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: Column(
                    children: [
                      // Sipariş seçim listesi (Çoklu sipariş desteği için)
                      _buildOrderSelectionList(ordersAsync.value),

                      // Active Order context info banner if exists
                      if (_activeOrder != null)
                        Container(
                          color: brandGreen.withOpacity(0.08),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.shopping_bag_outlined, color: brandGreen, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Sipariş Bağlantısı Kuruldu: ${_activeOrder!.businessName ?? 'İşletme'} (#${_activeOrder!.id.substring(0, math.min(8, _activeOrder!.id.length))})",
                                  style: const TextStyle(
                                    color: brandGreen,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length + (_isTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length && _isTyping) {
                              return _buildTypingBubble();
                            }
                            
                            final msg = _messages[index];
                            return _buildMessageBubble(msg, timeFormat);
                          },
                        ),
                      ),

                      // Quick Replies Row
                      _buildQuickRepliesRow(),

                      // Chat input field
                      _buildInputRow(brandGreen),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, DateFormat timeFormat) {
    const brandGreen = Color(0xFF00A651);
    final isUser = msg.isUser;
    final ordersAsync = ref.watch(consumerOrdersProvider);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? brandGreen : const Color(0xFFEFEFEF),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg.text,
                  style: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeFormat.format(msg.time),
                  style: TextStyle(
                    color: isUser ? Colors.white.withOpacity(0.7) : Colors.grey[500],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          
          // Render interactive options buttons under AI message bubble
          if (!isUser && msg.options != null && msg.options!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12, top: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: msg.options!.map((opt) {
                  return OutlinedButton(
                    onPressed: () {
                      // 1. Link selected order
                      if (ordersAsync.value != null) {
                        try {
                          final selectedOrder = ordersAsync.value!.firstWhere((o) => o.id == opt.id);
                          setState(() {
                            _activeOrder = selectedOrder;
                          });
                        } catch (_) {}
                      }
                      // 2. Trigger message send
                      _sendMessage("${opt.label} hakkında yardım istiyorum.");
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: brandGreen,
                      side: const BorderSide(color: brandGreen, width: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: Text(
                      opt.label,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: const BoxDecoration(
          color: Color(0xFFEFEFEF),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Hoppa Asistan yazıyor",
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            SizedBox(width: 8),
            BouncingDotsIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRepliesRow() {
    final replies = [
      {"label": "Siparişim Nerede? 📍", "text": "Aktif siparişim nerede?"},
      {"label": "Eksik Ürün Geldi 🍎", "text": "Siparişimde eksik ürün var."},
      {"label": "İptal Etmek İstiyorum ❌", "text": "Siparişimi iptal etmek istiyorum."},
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: replies.length,
        itemBuilder: (context, index) {
          final reply = replies[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              backgroundColor: Colors.white,
              elevation: 1,
              shadowColor: Colors.black12,
              surfaceTintColor: Colors.white,
              side: BorderSide(color: Colors.grey[200]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              label: Text(
                reply["label"]!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: _isTyping ? null : () => _sendMessage(reply["text"]!),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputRow(Color brandGreen) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: "Mesajınızı yazın...",
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                fillColor: const Color(0xFFF7F7F7),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : Colors.grey,
                  ),
                  onPressed: _listen,
                ),
              ),
              onSubmitted: (val) => _sendMessage(val),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: brandGreen,
            radius: 22,
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(_inputController.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSelectionList(List<Order>? orders) {
    if (orders == null || orders.isEmpty) return const SizedBox.shrink();
    
    // Take the 5 most recent orders to keep the selection simple
    final recentOrders = orders.take(5).toList();
    if (recentOrders.isEmpty) return const SizedBox.shrink();

    const brandGreen = Color(0xFF00A651);

    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Destek Almak İstediğiniz Sipariş:",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: recentOrders.length,
              itemBuilder: (context, index) {
                final o = recentOrders[index];
                final isSelected = _activeOrder?.id == o.id;
                final isDelivered = o.status == 'delivered';
                final isCancelled = o.status == 'cancelled';
                
                Color statusColor = Colors.orange;
                if (isDelivered) statusColor = brandGreen;
                if (isCancelled) statusColor = Colors.red;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeOrder = o;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? brandGreen.withOpacity(0.08) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? brandGreen : Colors.grey[200]!,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDelivered 
                              ? Icons.check_circle_outline 
                              : (isCancelled ? Icons.cancel_outlined : Icons.pedal_bike),
                          size: 14,
                          color: isSelected ? brandGreen : statusColor,
                        ),
                        const SizedBox(width: 6),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.businessName ?? "İşletme",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? brandGreen : Colors.black87,
                              ),
                            ),
                            Text(
                              "${isDelivered ? 'Teslim Edildi' : (isCancelled ? 'İptal Edildi' : 'Aktif')} • ${DateFormat('dd.MM HH:mm').format(o.createdAt)}",
                              style: TextStyle(
                                fontSize: 8,
                                color: isSelected ? brandGreen.withOpacity(0.8) : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BouncingDotsIndicator extends StatefulWidget {
  const BouncingDotsIndicator({super.key});

  @override
  State<BouncingDotsIndicator> createState() => _BouncingDotsIndicatorState();
}

class _BouncingDotsIndicatorState extends State<BouncingDotsIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Calculate a staggered sine wave for each dot
            final double progress = (_controller.value * 2 * math.pi) - (index * 0.8);
            final double offset = math.sin(progress) * 3.0; // Bouncing between -3 and 3
            
            return Transform.translate(
              offset: Offset(0, offset),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
