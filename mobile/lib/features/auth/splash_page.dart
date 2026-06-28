import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_controller.dart';
import '../home/home_page.dart';
import 'login_page.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(authControllerProvider.notifier).loadToken();
      if (!mounted) return;

      final isLoggedIn = ref.read(authControllerProvider).isLoggedIn;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => isLoggedIn ? const HomePage() : const LoginPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
