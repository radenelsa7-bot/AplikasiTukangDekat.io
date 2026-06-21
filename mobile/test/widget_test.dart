// Basic Flutter widget tests for the chatbot UI in the mobile app.
// These tests cover screen rendering, form validation, API response handling,
// and rate-limit UX.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/api_service.dart';
import 'package:mobile/features/chatbot/chatbot_page.dart';

class FakeChatApiService extends ApiService {
  FakeChatApiService() : super(dio: Dio());

  @override
  Future<Map<String, dynamic>> sendChatbotMessage({required String message}) async {
    return {'assistant_message': 'Halo! Ini balasan dari chatbot.'};
  }
}

class RateLimitedChatApiService extends ApiService {
  RateLimitedChatApiService() : super(dio: Dio());

  @override
  Future<Map<String, dynamic>> sendChatbotMessage({required String message}) async {
    throw DioException(
      requestOptions: RequestOptions(path: '/api/chatbot/send'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/chatbot/send'),
        statusCode: 429,
        data: {'message': 'Too Many Requests'},
      ),
    );
  }
}

void main() {
  testWidgets('Chatbot page smoke test builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ChatbotPage()),
      ),
    );

    expect(find.text('Chatbot Customer Service'), findsOneWidget);
    expect(find.text('Ketik pesan dan kirim untuk mulai chat dengan asisten kami.'), findsOneWidget);
  });

  testWidgets('Chatbot page shows validation message for empty input', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ChatbotPage()),
      ),
    );

    await tester.tap(find.text('Kirim Pesan'));
    await tester.pump();

    expect(find.text('Pesan tidak boleh kosong'), findsOneWidget);
  });

  testWidgets('Chatbot page sends message and shows assistant response', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiServiceProvider.overrideWithValue(FakeChatApiService())],
        child: const MaterialApp(home: ChatbotPage()),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'Halo');
    await tester.tap(find.text('Kirim Pesan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Halo'), findsOneWidget);
    expect(find.text('Halo! Ini balasan dari chatbot.'), findsOneWidget);
  });

  testWidgets('Chatbot page handles rate limit 429 response', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiServiceProvider.overrideWithValue(RateLimitedChatApiService())],
        child: const MaterialApp(home: ChatbotPage()),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'Coba rate limit');
    await tester.tap(find.text('Kirim Pesan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Terlalu banyak permintaan'), findsWidgets);
    expect(find.text('Permintaan Anda dibatasi. Silakan tunggu beberapa saat sebelum mencoba lagi.'), findsOneWidget);
    expect(find.textContaining('Tunggu'), findsOneWidget);
  });
}
