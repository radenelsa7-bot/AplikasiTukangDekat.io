import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/theme/app_theme.dart';
import 'landing/landing_screen.dart';
import 'features/chat/chatbot_screen.dart';
import 'features/auth/session_login_page.dart';
import 'features/treasurer/treasurer_report_page.dart';
import 'core/http/dio_provider.dart' as dio_provider;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load();

  // Enable persistent cookies (creates storage dir). If you prefer in-memory,
  // comment out the next line.
  await dio_provider.enablePersistCookies();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TukangDekat',
      theme: AppTheme.light(),
      home: const LandingScreen(),
      routes: {
        '/login': (_) => const SessionLoginPage(),
        '/session-login': (_) => const SessionLoginPage(),
        '/treasurer-report': (_) => const TreasurerReportPage(),
        '/chatbot': (_) => const ChatbotScreen(),
      },
    );
  }
}
