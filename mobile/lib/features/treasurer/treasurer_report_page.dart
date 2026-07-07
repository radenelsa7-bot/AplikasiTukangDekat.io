import 'dart:convert';
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
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  Future<void> _pickDate({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _startDate : _endDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (start) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    final api = ref.read(apiServiceProvider);
    try {
      final data = await api.getTreasurerReport(
        queryParameters: {
          'start_date': _startDate.toIso8601String().split('T').first,
          'end_date': _endDate.toIso8601String().split('T').first,
          'export': 'json',
        },
      );
      final pretty = const JsonEncoder.withIndent('  ').convert(data);
      setState(() => _output = pretty);
    } catch (e) {
      setState(() => _output = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Laporan Bendahara',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(start: true),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        'Mulai: ${_startDate.toIso8601String().split('T').first}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(start: false),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        'Selesai: ${_endDate.toIso8601String().split('T').first}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _loadReport,
                  icon: const Icon(Icons.insights_rounded),
                  label: Text(_loading ? 'Memuat...' : 'Tampilkan Laporan'),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _output.isEmpty ? 'Belum ada laporan' : _output,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
