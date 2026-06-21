import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/core/services/api_service.dart';
import 'package:mobile/features/chatbot/chatbot_page.dart';

class FakeChatApiService extends ApiService {
  FakeChatApiService() : super(dio: Dio());

  @override
  Future<Map<String, dynamic>> sendChatbotMessage({
    required String message,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return {'assistant_message': 'Halo! Ini balasan dari chatbot.'};
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Chatbot integration test: send and receive message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiServiceProvider.overrideWithValue(FakeChatApiService())],
        child: const MaterialApp(home: ChatbotPage()),
      ),
    );

    expect(find.text('Chatbot Customer Service'), findsOneWidget);
    expect(
      find.text('Ketik pesan dan kirim untuk mulai chat dengan asisten kami.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextFormField), 'Halo sistem');
    await tester.tap(find.text('Kirim Pesan'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Halo sistem'), findsOneWidget);
    expect(find.text('Halo! Ini balasan dari chatbot.'), findsOneWidget);
  });
}
