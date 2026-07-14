import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app/theme/app_theme.dart';
import 'landing/landing_screen.dart';
import 'features/chat/chatbot_screen.dart';
import 'features/auth/session_login_page.dart';
import 'features/admin/admin_dashboard_page.dart';
import 'core/http/dio_provider.dart' as dio_provider;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  try {
    await dotenv.load();
  } catch (e) {
    debugPrint(
      '[main] dotenv.load() failed: $e (will use --dart-define or defaults)',
    );
  }

  // Enable persistent cookies (creates storage dir). If you prefer in-memory,
  // comment out the next line.
  await dio_provider.enablePersistCookies();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone 11 design size
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TukangDekat',
          theme: AppTheme.light(),
          home: child,
          routes: {
            '/login': (_) => const ScreenUtilInit(
              designSize: Size(375, 812),
              child: SessionLoginPage(),
            ),
            '/session-login': (_) => const ScreenUtilInit(
              designSize: Size(375, 812),
              child: SessionLoginPage(),
            ),
            '/admin': (_) => const ScreenUtilInit(
              designSize: Size(375, 812),
              child: AdminDashboardPage(),
            ),
            '/chatbot': (_) => const ScreenUtilInit(
              designSize: Size(375, 812),
              child: ChatbotScreen(),
            ),
          },
        );
      },
      child: const LandingScreen(),
    );
  }
}