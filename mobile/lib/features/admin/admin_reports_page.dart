import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../shared/utils/download_helper.dart';

class AdminReportsPage extends ConsumerStatefulWidget {
  const AdminReportsPage({super.key});

  @override
  ConsumerState<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends ConsumerState<AdminReportsPage> {
  String _groupBy = 'day';
  DateTimeRange? _dateRange;
  Map<String, dynamic>? _reportData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getAdminReportSummary(
        groupBy: _groupBy,
        startDate: _dateRange?.start.toIso8601String().substring(0, 10),
        endDate: _dateRange?.end.toIso8601String().substring(0, 10),
      );
      if (mounted) {
        setState(() {
          _reportData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exportReport(String format) async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final params = <String, dynamic>{'export': format};
      if (_dateRange != null) {
        params['start_date'] = _dateRange!.start.toIso8601String().substring(0, 10);
        params['end_date'] = _dateRange!.end.toIso8601String().substring(0, 10);
      }

      final bytes = await api.getAdminPaymentReport(queryParameters: params);
      await downloadFile(bytes, format);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export $format berhasil'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Laporan Keuangan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ringkasan transaksi per periode (fungsi bendahara)',
            style: TextStyle(fontSize: 13, color: AppTheme.grey600),
          ),
          const SizedBox(height: 16),
          _buildFilters(),
          const SizedBox(height: 16),
          _buildExportButtons(),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          if (_error != null)
            Card(
              color: AppTheme.danger.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.danger),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.danger),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadReport,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          if (_reportData != null && !_isLoading) _buildReportTable(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Kelompokkan:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SegmentedButton<String>(
              selected: {_groupBy},
              segments: const [
                ButtonSegment(value: 'day', label: Text('Harian')),
                ButtonSegment(value: 'week', label: Text('Mingguan')),
                ButtonSegment(value: 'month', label: Text('Bulanan')),
              ],
              onSelectionChanged: (v) {
                setState(() => _groupBy = v.first);
                _loadReport();
              },
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith(
                  (s) => s.contains(WidgetState.selected)
                      ? Colors.white
                      : AppTheme.navy,
                ),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (s) => s.contains(WidgetState.selected)
                      ? AppTheme.orange
                      : Colors.transparent,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now(),
                  initialDateRange: _dateRange,
                );
                if (picked != null) {
                  setState(() => _dateRange = picked);
                  _loadReport();
                }
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                _dateRange != null
                    ? '${_dateRange!.start.toString().substring(0, 10)} - ${_dateRange!.end.toString().substring(0, 10)}'
                    : 'Pilih Periode',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            if (_dateRange != null)
              IconButton(
                onPressed: () {
                  setState(() => _dateRange = null);
                  _loadReport();
                },
                icon: const Icon(Icons.clear, size: 18),
                tooltip: 'Hapus filter tanggal',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButtons() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _exportReport('csv'),
          icon: const Icon(Icons.file_download, size: 18),
          label: const Text('Export CSV'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _exportReport('xls'),
          icon: const Icon(Icons.file_download, size: 18),
          label: const Text('Export Excel'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.info),
        ),
      ],
    );
  }

  Widget _buildReportTable() {
    final report = List<Map<String, dynamic>>.from(
      (_reportData?['report'] as List?)?.map(
            (e) => Map<String, dynamic>.from(e),
          ) ??
          [],
    );

    if (report.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('Belum ada data transaksi untuk periode ini'),
          ),
        ),
      );
    }

    // Summary totals
    double totalDp = 0, totalFinal = 0, totalRevenue = 0;
    int totalCount = 0;
    for (final r in report) {
      totalDp += double.tryParse(r['total_dp']?.toString() ?? '0') ?? 0;
      totalFinal += double.tryParse(r['total_final']?.toString() ?? '0') ?? 0;
      totalRevenue +=
          double.tryParse(r['total_revenue']?.toString() ?? '0') ?? 0;
      totalCount +=
          int.tryParse(r['transaction_count']?.toString() ?? '0') ?? 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Totals bar
        Card(
          margin: EdgeInsets.zero,
          color: AppTheme.navy,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildTotalItem(
                  'Total DP',
                  _formatCurrency(totalDp),
                  AppTheme.info,
                ),
                _buildTotalItem(
                  'Total Pelunasan',
                  _formatCurrency(totalFinal),
                  AppTheme.warning,
                ),
                _buildTotalItem(
                  'Total Pendapatan',
                  _formatCurrency(totalRevenue),
                  AppTheme.success,
                ),
                _buildTotalItem(
                  'Transaksi',
                  totalCount.toString(),
                  AppTheme.orange,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.grey100),
              columns: const [
                DataColumn(
                  label: Text(
                    'Periode',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'DP',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    'Pelunasan',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    'Jumlah',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  numeric: true,
                ),
              ],
              rows: report
                  .map(
                    (r) => DataRow(
                      cells: [
                        DataCell(
                          Text(
                            r['period'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(r['total_dp']),
                            style: const TextStyle(color: AppTheme.info),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(r['total_final']),
                            style: const TextStyle(color: AppTheme.warning),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(r['total_revenue']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.success,
                            ),
                          ),
                        ),
                        DataCell(Text('${r['transaction_count'] ?? 0}')),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }

  static String _formatCurrency(dynamic value) {
    final num = double.tryParse(value?.toString() ?? '0') ?? 0;
    final formatted = num.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $formatted';
  }
}