import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hoppa/shared/models/order.dart';
import 'package:hoppa/apps/consumer/repositories/consumer_order_repository.dart';
import 'package:hoppa/apps/consumer/repositories/support_repository.dart';

class MessageModel {
  final String text;
  final bool isUser;
  final DateTime time;

  MessageModel({
    required this.text,
    required this.isUser,
    required this.time,
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
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _findActiveOrder() {
    final ordersAsync = ref.read(consumerOrdersProvider);
    if (ordersAsync.value != null) {
      for (var o in ordersAsync.value!) {
        // Active orders: pending, preparing, onWay, readyForPickup
        if (o.status == 'pending' || 
            o.status == 'preparing' || 
            o.status == 'on_way' || 
            o.status == 'ready_for_pickup') {
          setState(() {
            _activeOrder = o;
          });
          break;
        }
      }
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
      
      if (mounted) {
        setState(() {
          _messages.add(
            MessageModel(
              text: reply,
              isUser: false,
              time: DateTime.now(),
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

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: brandGreen.withOpacity(0.1),
                  child: const Icon(Icons.support_agent, color: brandGreen),
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
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Hoppa Asistan",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Akıllı Destek",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Container(
        color: const Color(0xFFF9FBF9), // Soft background color
        child: Column(
          children: [
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
                        "Aktif Sipariş Bağlantısı Kuruldu: #${_activeOrder!.id.substring(0, math.min(8, _activeOrder!.id.length))}",
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

            // Message History List
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
    );
  }

  Widget _buildMessageBubble(MessageModel msg, DateFormat timeFormat) {
    const brandGreen = Color(0xFF00A651);
    final isUser = msg.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
