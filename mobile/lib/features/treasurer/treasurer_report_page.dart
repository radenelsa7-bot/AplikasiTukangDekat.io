import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';

class TreasurerReportPage extends ConsumerStatefulWidget {
  const TreasurerReportPage({super.key});

  @override
  ConsumerState<TreasurerReportPage> createState() =>
      _TreasurerReportPageState();
}

class _TreasurerReportPageState extends ConsumerState<TreasurerReportPage> {
  String _output = '';
  bool _loading = false;

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    final api = ref.read(apiServiceProvider);
    try {
      final data = await api.getTreasurerReport(
        queryParameters: {
          'start_date': '2026-05-01',
          'end_date': '2026-05-31',
          'export': 'json',
        },
      );
      setState(() => _output = data.toString());
    } catch (e) {
      setState(() => _output = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Treasurer Report (example)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _loadReport,
              child: const Text('Load Report'),
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
