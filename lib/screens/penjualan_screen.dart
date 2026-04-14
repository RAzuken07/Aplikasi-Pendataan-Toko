import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/app_data.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

enum FilterPeriod { hariIni, minggu, bulan, tahun }

class PenjualanScreen extends StatefulWidget {
  const PenjualanScreen({super.key});

  @override
  State<PenjualanScreen> createState() => _PenjualanScreenState();
}

class _PenjualanScreenState extends State<PenjualanScreen> {
  final AppStore _store = AppStore();
  String _searchQuery = '';
  FilterPeriod _filter = FilterPeriod.hariIni;

  List<Transaksi> get _filteredTransaksi {
    final now = DateTime.now();
    List<Transaksi> list = _store.transaksiList;
    switch (_filter) {
      case FilterPeriod.hariIni:
        list = list
            .where((t) =>
                t.tanggal.day == now.day &&
                t.tanggal.month == now.month &&
                t.tanggal.year == now.year)
            .toList();
        break;
      case FilterPeriod.minggu:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        list = list
            .where((t) => t.tanggal
                .isAfter(startOfWeek.subtract(const Duration(days: 1))))
            .toList();
        break;
      case FilterPeriod.bulan:
        list = list
            .where((t) =>
                t.tanggal.month == now.month && t.tanggal.year == now.year)
            .toList();
        break;
      case FilterPeriod.tahun:
        list = list.where((t) => t.tanggal.year == now.year).toList();
        break;
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((t) =>
              t.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.kasir.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return list;
  }

  List<_ChartDataPoint> get _chartData {
    switch (_filter) {
      case FilterPeriod.hariIni:
        final hours = List.generate(24, (i) => i);
        final totals = {for (var h in hours) h: 0};
        for (final t in _filteredTransaksi) {
          if (totals.containsKey(t.tanggal.hour)) {
            totals[t.tanggal.hour] = totals[t.tanggal.hour]! + t.totalBayar;
          }
        }
        return hours
            .map((hour) => _ChartDataPoint(
                '${hour.toString().padLeft(2, '0')}:00', totals[hour]!))
            .toList();
      case FilterPeriod.minggu:
        final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
        final totals = {for (var i = 1; i <= 7; i++) i: 0};
        for (final t in _filteredTransaksi) {
          totals[t.tanggal.weekday] =
              totals[t.tanggal.weekday]! + t.totalBayar;
        }
        return List.generate(days.length,
            (index) => _ChartDataPoint(days[index], totals[index + 1]!));
      case FilterPeriod.bulan:
        final totals = List.filled(4, 0);
        for (final t in _filteredTransaksi) {
          final weekIndex = ((t.tanggal.day - 1) / 7).floor().clamp(0, 3);
          totals[weekIndex] += t.totalBayar;
        }
        return List.generate(
            4, (index) => _ChartDataPoint('Mgg ${index + 1}', totals[index]));
      case FilterPeriod.tahun:
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
          'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
        ];
        final totals = List.filled(12, 0);
        for (final t in _filteredTransaksi) {
          totals[t.tanggal.month - 1] += t.totalBayar;
        }
        return List.generate(
            12, (index) => _ChartDataPoint(months[index], totals[index]));
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaksi = _filteredTransaksi;
    final totalFiltered =
        transaksi.fold<int>(0, (sum, t) => sum + t.totalBayar);
    final jumlahTransaksi = transaksi.length;
    final avgTransaksi =
        jumlahTransaksi > 0 ? totalFiltered ~/ jumlahTransaksi : 0;
    final chartData = _chartData;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 4,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Riwayat Penjualan',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Laporan & analitik transaksi',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              _OutlineButton(
                icon: Icons.file_download_rounded,
                label: 'Export Excel',
                onTap: _exportToExcel,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Summary Cards ──────────────────────────────────────────────────
          Row(
            children: [
              _SummaryCard(
                icon: Icons.payments_rounded,
                label: 'Total Pendapatan',
                value: AppStore.formatRupiah(totalFiltered),
                color: AppColors.primary,
                bgColor: AppColors.primaryLighter,
                trend: '+12%',
                trendUp: true,
              ),
              const SizedBox(width: 14),
              _SummaryCard(
                icon: Icons.receipt_long_rounded,
                label: 'Jumlah Transaksi',
                value: '$jumlahTransaksi',
                color: const Color(0xFF1565C0),
                bgColor: const Color(0xFFE3F2FD),
                trend: '+3',
                trendUp: true,
              ),
              const SizedBox(width: 14),
              _SummaryCard(
                icon: Icons.trending_up_rounded,
                label: 'Rata-rata Transaksi',
                value: AppStore.formatRupiah(avgTransaksi),
                color: const Color(0xFF6A1B9A),
                bgColor: const Color(0xFFF3E5F5),
                trend: '-5%',
                trendUp: false,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Trend Graph ────────────────────────────────────────────────────
          _TrendGraphCard(
            data: chartData,
            selectedFilter: _filter,
            onFilterChanged: (value) => setState(() => _filter = value),
          ),
          const SizedBox(height: 20),

          // ── Transaction List ───────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                const BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // List Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryLighter,
                        AppColors.primaryLighter.withValues(alpha: 0.3),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
  children: [
    // 1. Icon Container
    Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Icon(
        Icons.list_alt_rounded,
        color: AppColors.primary,
        size: 17,
      ),
    ),
    const SizedBox(width: 10),

    // 2. Judul 'Daftar Transaksi'
    const Text(
      'Daftar Transaksi',
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    ),

    // 3. Widget ini akan memakan semua ruang kosong di tengah
    const Spacer(), 

    // 4. Count badge (Sekarang berada di ujung kanan)
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${transaksi.length} transaksi',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  ],
),
                ),

                // Empty state
                if (transaksi.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLighter,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long_outlined,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada transaksi',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Transaksi akan muncul di sini',
                            style: TextStyle(
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: transaksi
                        .asMap()
                        .entries
                        .map((entry) => _TransactionListCard(
                              transaksi: entry.value,
                              index: entry.key,
                              onDetail: () =>
                                  _showDetail(context, entry.value),
                            ))
                        .toList(),
                  ),

                // Footer
                if (transaksi.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      border: Border(
                        top: BorderSide(color: Color(0xFFF0F0F0)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 13,
                          color: AppColors.textSecondary
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Menampilkan ${transaksi.length} transaksi',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Total: ${AppStore.formatRupiah(totalFiltered)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, Transaksi t) {
    showDialog(
      context: context,
      builder: (_) => _TransaksiDetailDialog(transaksi: t),
    );
  }

  void _exportToExcel() async {
    final excel = excel_pkg.Excel.createExcel();
    final sheet = excel['Sheet1'];

    sheet.appendRow([
      excel_pkg.TextCellValue('ID Transaksi'),
      excel_pkg.TextCellValue('Tanggal & Waktu'),
      excel_pkg.TextCellValue('Kasir'),
      excel_pkg.TextCellValue('Jumlah Item'),
      excel_pkg.TextCellValue('Total'),
    ]);

    for (final t in _filteredTransaksi) {
      sheet.appendRow([
        excel_pkg.TextCellValue(t.id),
        excel_pkg.TextCellValue(t.tanggalFormatted),
        excel_pkg.TextCellValue(t.kasir),
        excel_pkg.IntCellValue(t.totalItem),
        excel_pkg.IntCellValue(t.totalBayar),
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();
    final filePath =
        '${directory.path}/penjualan_${_filter.name}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('File disimpan di: $filePath'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─── Summary Card ──────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  final String trend;
  final bool trendUp;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.trend,
    required this.trendUp,
  });

  @override
  Widget build(BuildContext context) {
    final trendColor =
        trendUp ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final trendBg =
        trendUp ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            const BoxShadow(
              color: Color(0x06000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trendBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: trendColor,
                        size: 10,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: trendColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chart Data Point ──────────────────────────────────────────────────────────
class _ChartDataPoint {
  final String label;
  final int value;

  const _ChartDataPoint(this.label, this.value);
}

// ─── Trend Graph Card ──────────────────────────────────────────────────────────
class _TrendGraphCard extends StatelessWidget {
  final List<_ChartDataPoint> data;
  final FilterPeriod selectedFilter;
  final ValueChanged<FilterPeriod> onFilterChanged;

  const _TrendGraphCard({
    required this.data,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grafik Tren Penjualan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Visualisasi tren penjualan multi-waktu',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _FilterTabRow(
                  selected: selectedFilter,
                  onChanged: onFilterChanged,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Full-width chart
            SizedBox(
              height: 220,
              child: _TrendChart(data: data),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Tab Row ────────────────────────────────────────────────────────────
class _FilterTabRow extends StatelessWidget {
  final FilterPeriod selected;
  final ValueChanged<FilterPeriod> onChanged;

  const _FilterTabRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = {
      FilterPeriod.hariIni: 'Hari Ini',
      FilterPeriod.minggu: 'Minggu Ini',
      FilterPeriod.bulan: 'Bulan Ini',
      FilterPeriod.tahun: 'Tahun Ini',
    };

    return Row(
      children: FilterPeriod.values.map((period) {
        final isSelected = period == selected;
        return GestureDetector(
          onTap: () => onChanged(period),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(left: 6),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              labels[period]!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Trend Chart ──────────────────────────────────────────────────────────────
class _TrendChart extends StatelessWidget {
  final List<_ChartDataPoint> data;

  const _TrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada data untuk periode ini.',
          style:
              TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }
    return CustomPaint(
      painter: _TrendChartPainter(data: data),
      child: const SizedBox.expand(),
    );
  }
}

// ─── Trend Chart Painter ──────────────────────────────────────────────────────
class _TrendChartPainter extends CustomPainter {
  final List<_ChartDataPoint> data;

  _TrendChartPainter({required this.data});

  static const double _leftPad = 82.0;
  static const double _rightPad = 16.0;
  static const double _topPad = 28.0;
  static const double _bottomPad = 44.0;

  String _formatRupiah(double value) {
    if (value == 0) return 'Rp 0';
    final v = value.toInt();
    final s = v.toString();
    final buf = StringBuffer('Rp ');
    for (int i = 0; i < s.length; i++) {
      if (i != 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  TextPainter _tp(
    String text, {
    double fontSize = 10,
    Color color = const Color(0xFF9E9E9E),
    FontWeight weight = FontWeight.normal,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, color: color, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final chartW = size.width - _leftPad - _rightPad;
    final chartH = size.height - _topPad - _bottomPad;

    final values = data.map((d) => d.value.toDouble()).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final niceMax = maxVal == 0
        ? 60000.0
        : (((maxVal * 1.25) / 10000).ceil() * 10000).toDouble();

    // ── Grid + Y labels ────────────────────────────────────────────────────
    const gridCount = 4;
    final gridPaint = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..strokeWidth = 1;

    for (int i = 0; i <= gridCount; i++) {
      final y = _topPad + chartH - (i / gridCount) * chartH;
      canvas.drawLine(
          Offset(_leftPad, y), Offset(_leftPad + chartW, y), gridPaint);

      final yTp = _tp('[${_formatRupiah((i / gridCount) * niceMax)}]');
      yTp.paint(
          canvas, Offset(_leftPad - yTp.width - 6, y - yTp.height / 2));
    }

    // ── Rotated Y-axis title ───────────────────────────────────────────────
    // final yAxisTp = _tp('Sumbu Y (Nilai Pendapatan Rp)');
    // canvas.save();
    // canvas.translate(10, _topPad + chartH / 2 + yAxisTp.width / 2);
    // canvas.rotate(-3.14159265 / 2);
    // yAxisTp.paint(canvas, Offset.zero);
    // canvas.restore();

    // ── Point positions ────────────────────────────────────────────────────
    final positions = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = _leftPad +
          (data.length == 1 ? chartW / 2 : i * chartW / (data.length - 1));
      final y = _topPad +
          chartH -
          (values[i] / niceMax).clamp(0.0, 1.0) * chartH;
      positions.add(Offset(x, y));
    }

    // ── Gradient fill ──────────────────────────────────────────────────────
    final fillPath = Path()
      ..moveTo(positions.first.dx, _topPad + chartH);
    for (final p in positions) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath
      ..lineTo(positions.last.dx, _topPad + chartH)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.0),
          ],
        ).createShader(
            Rect.fromLTWH(_leftPad, _topPad, chartW, chartH)),
    );

    // ── Line ──────────────────────────────────────────────────────────────
    final linePath = Path()
      ..moveTo(positions.first.dx, positions.first.dy);
    for (int i = 1; i < positions.length; i++) {
      linePath.lineTo(positions[i].dx, positions[i].dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // ── Dots + value labels ────────────────────────────────────────────────
    for (int i = 0; i < positions.length; i++) {
      final p = positions[i];

      canvas.drawCircle(p, 6, Paint()..color = Colors.white);
      canvas.drawCircle(p, 4, Paint()..color = AppColors.primary);

      if (values[i] > 0) {
        final valTp = _tp(
          _formatRupiah(values[i]),
          fontSize: 10,
          color: AppColors.primary,
          weight: FontWeight.w700,
        );
        valTp.paint(
            canvas, Offset(p.dx - valTp.width / 2, p.dy - valTp.height - 8));
      }

      // X label
      final xTp = _tp('[${data[i].label}]');
      xTp.paint(
        canvas,
        Offset(p.dx - xTp.width / 2, _topPad + chartH + 10),
      );
    }

    // ── X-axis title ───────────────────────────────────────────────────────
    // final xAxisTp = _tp('Sumbu X (Waktu)');
    // xAxisTp.paint(
    //   canvas,
    //   Offset(
    //     _leftPad + chartW / 2 - xAxisTp.width / 2,
    //     size.height - xAxisTp.height - 2,
    //   ),
    //);
  }

  @override
  bool shouldRepaint(_TrendChartPainter old) => old.data != data;
}

// ─── Transaction List Card ─────────────────────────────────────────────────────
class _TransactionListCard extends StatefulWidget {
  final Transaksi transaksi;
  final int index;
  final VoidCallback onDetail;

  const _TransactionListCard({
    required this.transaksi,
    required this.index,
    required this.onDetail,
  });

  @override
  State<_TransactionListCard> createState() => _TransactionListCardState();
}

class _TransactionListCardState extends State<_TransactionListCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.transaksi;
    final isEven = widget.index % 2 == 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _hovered
              ? AppColors.primaryLighter.withValues(alpha: 0.6)
              : isEven
                  ? Colors.white
                  : const Color(0xFFFAFAFA),
          border: const Border(
              bottom: BorderSide(color: Color(0xFFF0F0F0))),
        ),
        child: InkWell(
          onTap: widget.onDetail,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                // ID + kasir
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Container(
                      //   padding: const EdgeInsets.symmetric(
                      //       horizontal: 8, vertical: 3),
                      //   decoration: BoxDecoration(
                      //     color: AppColors.primaryLighter,
                      //     borderRadius: BorderRadius.circular(6),
                      //   ),
                      //   child: Text(
                      //     t.id,
                      //     style: const TextStyle(
                      //       fontSize: 11,
                      //       fontWeight: FontWeight.w700,
                      //       color: AppColors.primary,
                      //     ),
                      //   ),
                      // ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              t.kasir.substring(0, 1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            t.kasir,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Tanggal
                Expanded(
                  flex: 3,
                  child: Text(
                    t.tanggalFormatted,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
                // Jumlah item
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${t.totalItem}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                  ),
                ),
                // Total
                Expanded(
                  flex: 2,
                  child: Text(
                    t.totalFormatted,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Detail button
                GestureDetector(
                  onTap: widget.onDetail,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLighter,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_rounded,
                              color: AppColors.primary, size: 13),
                          SizedBox(width: 4),
                          Text(
                            'Lihat',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ─── Transaksi Detail Dialog ──────────────────────────────────────────────────
class _TransaksiDetailDialog extends StatelessWidget {
  final Transaksi transaksi;

  const _TransaksiDetailDialog({required this.transaksi});

  @override
  Widget build(BuildContext context) {
    final t = transaksi;
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLighter,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                const Text('Detail Transaksi',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Divider(),
            const SizedBox(height: 8),
            _DetailRow('ID Transaksi', t.id),
            _DetailRow('Tanggal', t.tanggalFormatted),
            _DetailRow('Kasir', t.kasir),
            _DetailRow('Total Pembayaran', t.totalFormatted),
            const SizedBox(height: 16),
            if (t.items.isNotEmpty) ...[
              const Text('Item yang dibeli:',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: t.items
                      .map((item) => Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(item.produk.nama,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                const Spacer(),
                                Text(
                                    '${item.jumlah} x ${item.produk.hargaFormatted}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                                const SizedBox(width: 12),
                                Text(
                                    AppStore.formatRupiah(item.subtotal),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    )),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                      'Data item tidak tersedia untuk transaksi lama.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ),
              ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Tutup',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Detail Row ────────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Text(value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
        ],
      ),
    );
  }
}

// ─── Outline Button ────────────────────────────────────────────────────────────
class _OutlineButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlineButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.primaryLighter : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: AppColors.primary, size: 17),
              const SizedBox(width: 6),
              Text(widget.label,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}