import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';

class SessionLoginPage extends ConsumerStatefulWidget {
  const SessionLoginPage({super.key});

  @override
  ConsumerState<SessionLoginPage> createState() => _SessionLoginPageState();
}

class _SessionLoginPageState extends ConsumerState<SessionLoginPage> {
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  String _output = '';
  bool _loading = false;

  Future<void> _doLogin() async {
    setState(() => _loading = true);
    final api = ref.read(apiServiceProvider);
    try {
      final res = await api.sessionLogin(
        email: _emailCtl.text.trim(),
        password: _passCtl.text.trim(),
      );
      setState(() => _output = res.toString());
    } catch (e) {
      setState(() => _output = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _checkSession() async {
    setState(() => _loading = true);
    final api = ref.read(apiServiceProvider);
    try {
      final user = await api.getUserSession();
      setState(() => _output = user?.toString() ?? 'No session');
    } catch (e) {
      setState(() => _output = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session Login (example)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailCtl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passCtl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _loading ? null : _doLogin,
                  child: const Text('Session Login'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _checkSession,
                  child: const Text('Get Session'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(child: SelectableText(_output)),
            ),
          ],
        ),
      ),
    );
  }
}
