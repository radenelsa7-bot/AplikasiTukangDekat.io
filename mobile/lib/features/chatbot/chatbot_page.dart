import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/api_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/site_footer.dart';
import '../../shared/widgets/site_header.dart';

class ChatbotPage extends ConsumerStatefulWidget {
  const ChatbotPage({super.key});

  @override
  ConsumerState<ChatbotPage> createState() => _ChatbotPageState();
}

class ChatbotMessage {
  const ChatbotMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class _ChatbotPageState extends ConsumerState<ChatbotPage> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatbotMessage> _messages = [];
  bool _isSending = false;
  bool _isRateLimited = false;
  int _rateLimitSeconds = 0;
  String? _errorMessage;
  Timer? _rateLimitTimer;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _rateLimitTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isSending = true;
      _messages.add(ChatbotMessage(text: message, isUser: true));
      _messageController.clear();
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.sendChatbotMessage(message: message);
      final assistant = response['assistant_message']?.toString() ??
          response['assistant']?.toString() ??
          'Maaf, tidak ada balasan dari chatbot.';

      if (mounted) {
        setState(() {
          _messages.add(ChatbotMessage(text: assistant, isUser: false));
          _errorMessage = null;
        });
        _scrollToBottom();
      }
    } on DioException catch (error) {
      if (mounted) {
        if (error.response?.statusCode == 429) {
          _activateRateLimit(30);
          setState(() {
            _errorMessage =
                'Terlalu banyak permintaan. Coba lagi dalam $_rateLimitSeconds detik.';
            _messages.add(const ChatbotMessage(
              text:
                  'Permintaan Anda dibatasi. Silakan tunggu beberapa saat sebelum mencoba lagi.',
              isUser: false,
            ));
          });
        } else {
          setState(() {
            _errorMessage = 'Gagal mengirim pesan. Silakan coba lagi.';
            _messages.add(const ChatbotMessage(
              text: 'Gagal mengirim pesan. Silakan coba lagi.',
              isUser: false,
            ));
          });
          messenger.showSnackBar(
            SnackBar(
              content: Text('Chatbot error: ${error.message}'),
            ),
          );
        }
        _scrollToBottom();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal mengirim pesan. Silakan coba lagi.';
          _messages.add(const ChatbotMessage(
            text: 'Gagal mengirim pesan. Silakan coba lagi.',
            isUser: false,
          ));
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text('Chatbot error: $error'),
          ),
        );
        _scrollToBottom();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _activateRateLimit(int seconds) {
    _rateLimitTimer?.cancel();
    _isRateLimited = true;
    _rateLimitSeconds = seconds;

    _rateLimitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_rateLimitSeconds <= 1) {
        timer.cancel();
        setState(() {
          _isRateLimited = false;
          _rateLimitSeconds = 0;
          _errorMessage = null;
        });
        return;
      }

      setState(() {
        _rateLimitSeconds -= 1;
        _errorMessage =
            'Terlalu banyak permintaan. Coba lagi dalam $_rateLimitSeconds detik.';
      });
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TukangDekatHeader(title: Text('Chatbot Customer Service')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        'Ketik pesan dan kirim untuk mulai chat dengan asisten kami.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return Align(
                          alignment: message.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                            ),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: message.isUser
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              message.text,
                              style: TextStyle(
                                color: message.isUser
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    controller: _messageController,
                    label: 'Tulis pesan Anda',
                    hintText: 'Contoh: Bagaimana cara membayar pesanan saya?',
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Pesan tidak boleh kosong';
                      }
                      if (value.trim().length > 1000) {
                        return 'Pesan maksimal 1000 karakter';
                      }
                      return null;
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  AppButton(
                    label: _isRateLimited
                        ? 'Tunggu $_rateLimitSeconds detik'
                        : _isSending
                            ? 'Mengirim...'
                            : 'Kirim Pesan',
                    isLoading: _isSending,
                    onPressed: (_isSending || _isRateLimited) ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const TukangDekatFooter(),
    );
  }
}
