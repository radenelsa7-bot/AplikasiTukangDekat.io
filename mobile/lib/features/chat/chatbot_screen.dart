import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../home/order_detail_page.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'from': 'bot',
      'text':
          'Halo! Saya asisten TukangDekat. Ada yang bisa saya bantu?\n\nAnda bisa bertanya tentang:\n• Status pesanan\n• Informasi pembayaran\n• Cara memesan jasa\n• Pembatalan pesanan',
      'actions': [],
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'from': 'user', 'text': text});
      _isLoading = true;
    });
    _ctrl.clear();
    _scrollToBottom();

    try {
      final api = ref.read(apiServiceProvider);
      final resp = await api.sendChatbotMessage(text);
      if (!mounted) return;
      final replyText = resp['reply']?.toString() ?? '';
      final actions = resp['actions'] is List ? resp['actions'] as List : [];
      setState(() {
        _messages.add({'from': 'bot', 'text': replyText, 'actions': actions});
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'from': 'bot',
          'text': 'Maaf, terjadi kesalahan. Silakan coba lagi.',
        });
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.navy,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 20,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asisten TukangDekat',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Online',
                  style: TextStyle(fontSize: 11, color: AppTheme.success),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                final m = _messages[index];
                final isUser = m['from'] == 'user';
                return Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    _buildMessageBubble(m, isUser),
                    if (!isUser) _buildBotActions(m),
                  ],
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isUser) {
    final text = message['text']?.toString() ?? '';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 10,
          left: isUser ? 60 : 0,
          right: isUser ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.navy : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : AppTheme.navy,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildBotActions(Map<String, dynamic> message) {
    final actions = message['actions'];
    if (actions == null || actions is! List || actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 12, right: 12),
      child: Wrap(
        spacing: 8,
        children: actions.map<Widget>((a) {
          final label = a['label']?.toString() ?? 'Aksi';
          final type = a['type']?.toString() ?? '';
          final payload = a['payload'];
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.navy,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final api = ref.read(apiServiceProvider);
              try {
                if (type == 'generate_qris') {
                  final pid = (payload is Map)
                      ? (payload['payment_id'] ??
                            payload['paymentId'] ??
                            payload['payment'])
                      : null;
                  final oid = (payload is Map)
                      ? (payload['order_id'] ?? payload['orderId'])
                      : null;

                  if (oid != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderDetailPage(
                          orderId: int.tryParse(oid.toString()) ?? 0,
                          autoOpenQris: true,
                          autoPaymentId: pid != null
                              ? int.tryParse(pid.toString())
                              : null,
                        ),
                      ),
                    );
                    return;
                  }

                  if (pid != null) {
                    // If only payment id is provided and no order id, generate QRIS directly as fallback
                    final q = await api.generateQRIS(
                      int.tryParse(pid.toString()) ?? 0,
                    );
                    final url =
                        q['checkout_url'] ??
                        q['checkoutUrl'] ??
                        q['checkout'] ??
                        q.toString();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('QRIS dibuat: $url')),
                    );
                    return;
                  }
                }

                if (type == 'open_order') {
                  final oid = (payload is Map)
                      ? (payload['order_id'] ?? payload['orderId'])
                      : null;
                  if (oid != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderDetailPage(
                          orderId: int.tryParse(oid.toString()) ?? 0,
                        ),
                      ),
                    );
                    return;
                  }

                  final info = payload is Map && payload['order_code'] != null
                      ? 'Order: ${payload['order_code']}'
                      : payload?.toString() ?? '';
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('$label — $info')));
                  return;
                }

                if (type == 'view_payment') {
                  final oid = (payload is Map)
                      ? (payload['order_id'] ?? payload['orderId'])
                      : null;
                  if (oid != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderDetailPage(
                          orderId: int.tryParse(oid.toString()) ?? 0,
                        ),
                      ),
                    );
                    return;
                  }
                }

                // Default behavior
                final info = payload is Map && payload['order_code'] != null
                    ? 'Order: ${payload['order_code']}'
                    : payload?.toString() ?? '';
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('$label — $info')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal menjalankan aksi: $label')),
                );
              }
            },
            child: Text(label),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, right: 60),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + index * 200),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.grey400,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.grey100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _ctrl,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    hintText: 'Tulis pesan...',
                    hintStyle: TextStyle(color: AppTheme.grey400),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.orange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.orange.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _isLoading ? null : _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
