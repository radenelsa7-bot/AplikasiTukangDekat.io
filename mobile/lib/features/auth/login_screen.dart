import 'package:flutter/material.dart';
import 'login_page.dart';

/// Small wrapper named `LoginScreen` to satisfy FASE 4 requirement.
/// It delegates to the existing `LoginPage` implementation.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginPage();
  }
}
