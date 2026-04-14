import 'dart:async';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/app_data.dart';
import '../widgets/sidebar_widget.dart';
import '../widgets/topbar_widget.dart';
import '../widgets/dashboard_widgets.dart';
import 'produk_screen.dart';
import 'penjualan_screen.dart';
import 'buat_transaksi_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  NavItem _selectedNav = NavItem.dashboard;
  bool _showBuatTransaksi = false;
  Produk? _initialProdukForTransaksi;
  final AppStore _store = AppStore();

  // ── Sample data ─────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _bestSellers {
    final productSales = <String, int>{};
    final now = DateTime.now();
    for (final t in _store.transaksiList) {
      if (t.tanggal.year == now.year && t.tanggal.month == now.month && t.tanggal.day == now.day) {
        for (final item in t.items) {
          productSales[item.produk.id] = (productSales[item.produk.id] ?? 0) + item.jumlah;
        }
      }
    }
    final sorted = productSales.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final List<Map<String, dynamic>> result = [];
    for (var e in sorted) {
      final pIndex = _store.produkList.indexWhere((p) => p.id == e.key);
      if (pIndex != -1) {
        final p = _store.produkList[pIndex];
        result.add({'name': p.nama, 'icon': p.icon, 'color': p.warna, 'sold': e.value});
        if (result.length >= 3) break;
      }
    }
    return result;
  }

  // ─── Nav handler ────────────────────────────────────────────────────────────
  void _onNavSelected(NavItem item) {
    setState(() {
      _selectedNav = item;
      _showBuatTransaksi = false;
      _initialProdukForTransaksi = null;
    });
  }

  // ─── Page body ──────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_showBuatTransaksi) {
      return BuatTransaksiScreen(
        initialProduk: _initialProdukForTransaksi,
        onTransaksiSelesai: () {
          setState(() {
            _showBuatTransaksi = false;
            _initialProdukForTransaksi = null;
            _selectedNav = NavItem.penjualan;
          });
        },
      );
    }
    switch (_selectedNav) {
      case NavItem.produk:
        return const ProdukScreen();
      case NavItem.penjualan:
        return const PenjualanScreen();
      default:
        return _buildDashboardBody();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────────────────
          SidebarWidget(
            selectedItem: _selectedNav,
            onItemSelected: _onNavSelected,
          ),

          // ── Main area ────────────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                TopBarWidget(
                  pageTitle: _getPageTitle(),
                ),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ],
      ),

      // FAB hanya di dashboard
      floatingActionButton: (!_showBuatTransaksi && _selectedNav == NavItem.dashboard)
          ? _BuatTransaksiButton(onTap: () => setState(() {
              _initialProdukForTransaksi = null;
              _showBuatTransaksi = true;
            }))
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  String _getPageTitle() {
    if (_showBuatTransaksi) return 'Buat Transaksi';
    switch (_selectedNav) {
      case NavItem.produk: return 'Produk';
      case NavItem.penjualan: return 'Penjualan';
      default: return 'Dashboard';
    }
  }

  // ─── Dashboard body ──────────────────────────────────────────────────────────
  Widget _buildDashboardBody() {
    final now = DateTime.now();
    final chartData = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      final dayTransactions = _store.transaksiList.where((t) =>
          t.tanggal.day == date.day &&
          t.tanggal.month == date.month &&
          t.tanggal.year == date.year);
      final total = dayTransactions.fold(0, (sum, t) => sum + t.totalBayar);
      return total;
    });
    final maxValue = chartData.isEmpty ? 0 : chartData.reduce((a, b) => a > b ? a : b);
    final normalizedValues = chartData.map((v) => maxValue == 0 ? 0.0 : v / maxValue).toList();
    final tooltipValues = chartData.map((v) => 'Rp ${v.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}').toList();
    final labels = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Ming'][date.weekday - 1];
    });

    final lowStock = _store.lowStockProduk
        .map((p) => {'name': p.nama, 'stock': p.stok, 'icon': p.icon})
        .toList();

    final productGrid = _store.produkList
        .map((p) => {'id': p.id, 'name': p.nama, 'price': p.hargaFormatted, 'icon': p.icon, 'color': p.warna})
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeHeader(),
          const SizedBox(height: 20),

          // Top summary row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 210,
                child: SalesSummaryCard(
                  totalRevenue: _store.totalPendapatanFormatted,
                  transactionCount: _store.transaksiList.length,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: BestSellerCard(products: _bestSellers),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: WeeklyChartCard(values: normalizedValues, labels: labels, tooltipValues: tooltipValues),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Product grid + low stock
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: ProductGridCard(
                  products: productGrid,
                  onProductTap: (productMap) {
                    final pId = productMap['id'] as String;
                    final p = _store.produkList.firstWhere((prod) => prod.id == pId);
                    setState(() {
                      _initialProdukForTransaksi = p;
                      _showBuatTransaksi = true;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 230,
                child: LowStockCard(items: lowStock),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─── Welcome Header ───────────────────────────────────────────────────────────
class _WelcomeHeader extends StatefulWidget {
  const _WelcomeHeader();

  @override
  State<_WelcomeHeader> createState() => _WelcomeHeaderState();
}

class _WelcomeHeaderState extends State<_WelcomeHeader> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _formattedDateTime {
    const weekdays = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final dayName = weekdays[_now.weekday - 1];
    final monthName = months[_now.month - 1];
    final time = '${_twoDigits(_now.hour)}:${_twoDigits(_now.minute)}:${_twoDigits(_now.second)}';
    return '$dayName, ${_now.day} $monthName ${_now.year} • $time';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selamat Datang',
                style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 2),
            Text('Berikut ringkasan toko Anda hari ini.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryLighter,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  color: AppColors.primary, size: 14),
              const SizedBox(width: 6),
              Text(_formattedDateTime,
                  style: const TextStyle(
                    color: AppColors.primary, fontSize: 12,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Buat Transaksi FAB ───────────────────────────────────────────────────────
class _BuatTransaksiButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BuatTransaksiButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryLight, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Buat Transaksi',
                style: TextStyle(
                  color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w700, letterSpacing: 0.5,
                )),
          ],
        ),
      ),
    );
  }
}
