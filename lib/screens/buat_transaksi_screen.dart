import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/app_data.dart';

class BuatTransaksiScreen extends StatefulWidget {
  final VoidCallback? onTransaksiSelesai;
  final Produk? initialProduk;

  const BuatTransaksiScreen({
    super.key, 
    this.onTransaksiSelesai,
    this.initialProduk,
  });

  @override
  State<BuatTransaksiScreen> createState() => _BuatTransaksiScreenState();
}

class _BuatTransaksiScreenState extends State<BuatTransaksiScreen> {
  final AppStore _store = AppStore();
  final List<ItemTransaksi> _keranjang = [];
  String _searchQuery = '';
  int _bayar = 0;
  final _bayarCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialProduk != null) {
      if (widget.initialProduk!.stok > 0) {
        _keranjang.add(ItemTransaksi(produk: widget.initialProduk!, jumlah: 1));
      }
    }
  }

  List<Produk> get _filteredProduk {
    if (_searchQuery.isEmpty) return _store.produkList;
    return _store.produkList.where((p) =>
        p.nama.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  int get _totalHarga =>
      _keranjang.fold(0, (sum, item) => sum + item.subtotal);

  int get _kembalian => _bayar - _totalHarga;

  void _tambahKeKeranjang(Produk p) {
    setState(() {
      final idx = _keranjang.indexWhere((i) => i.produk.id == p.id);
      if (idx >= 0) {
        if (_keranjang[idx].jumlah < p.stok) {
          _keranjang[idx].jumlah++;
        }
      } else {
        if (p.stok > 0) {
          _keranjang.add(ItemTransaksi(produk: p, jumlah: 1));
        }
      }
    });
  }

  void _kurangiDariKeranjang(ItemTransaksi item) {
    setState(() {
      if (item.jumlah > 1) {
        item.jumlah--;
      } else {
        _keranjang.remove(item);
      }
    });
  }

  void _hapusDariKeranjang(ItemTransaksi item) {
    setState(() => _keranjang.remove(item));
  }

  void _prosesBayar() {
    if (_keranjang.isEmpty) return;
    if (_bayar < _totalHarga) {
      _showSnack('Uang bayar kurang!', isError: true);
      return;
    }

    final trx = Transaksi(
      id: 'TRX-${(_store.transaksiList.length + 1).toString().padLeft(3, '0')}',
      tanggal: DateTime.now(),
      items: List.from(_keranjang),
      totalBayar: _totalHarga,
      kasir: 'Kasir',
    );

    _store.tambahTransaksi(trx);
    _showStrukDialog(trx);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.accentRed : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showStrukDialog(Transaksi t) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _StrukDialog(
        transaksi: t,
        bayar: _bayar,
        kembalian: _kembalian,
        onSelesai: () {
          Navigator.pop(context);
          setState(() {
            _keranjang.clear();
            _bayar = 0;
            _bayarCtrl.clear();
          });
          widget.onTransaksiSelesai?.call();
          _showSnack('Transaksi berhasil disimpan!');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Product picker (kiri) ────────────────────────────────────────────
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Buat Transaksi',
                            style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            )),
                        Text('Pilih produk untuk ditambah ke keranjang',
                            style: TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLighter,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2, color: AppColors.primary, size: 14),
                          const SizedBox(width: 4),
                          Text('${_store.produkList.length} Produk',
                              style: const TextStyle(
                                color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari produk...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Products grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _filteredProduk.length,
                    itemBuilder: (_, i) {
                      final p = _filteredProduk[i];
                      final inCart = _keranjang.firstWhere(
                        (item) => item.produk.id == p.id,
                        orElse: () => ItemTransaksi(produk: p, jumlah: 0),
                      ).jumlah;
                      return _ProdukCard(
                        produk: p,
                        inCartCount: inCart,
                        onTap: () => _tambahKeKeranjang(p),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),

        // ── Keranjang (kanan) ────────────────────────────────────────────────
        Container(
          width: 320,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(-4, 0)),
            ],
          ),
          child: Column(
            children: [
              // Cart header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    const Text('Keranjang',
                        style: TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${_keranjang.length} item',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

              // Cart items
              Expanded(
                child: _keranjang.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined,
                                size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            Text('Keranjang kosong',
                                style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _keranjang.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFF0F0F0)),
                        itemBuilder: (_, i) => _KeranjangItem(
                          item: _keranjang[i],
                          onAdd: () => setState(() {
                            if (_keranjang[i].jumlah < _keranjang[i].produk.stok) {
                              _keranjang[i].jumlah++;
                            }
                          }),
                          onReduce: () => _kurangiDariKeranjang(_keranjang[i]),
                          onDelete: () => _hapusDariKeranjang(_keranjang[i]),
                        ),
                      ),
              ),

              // Summary & payment
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  children: [
                    _SummaryLine('Subtotal', AppStore.formatRupiah(_totalHarga)),
                    const SizedBox(height: 4),
                    _SummaryLine('Diskon', 'Rp 0',
                        valueColor: AppColors.accentRed),
                    const Divider(height: 16),
                    _SummaryLine('Total',
                        AppStore.formatRupiah(_totalHarga),
                        isBold: true, valueColor: AppColors.primary),
                    const SizedBox(height: 14),

                    // Input bayar
                    Row(
                      children: [
                        const Text('Uang Bayar',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        SizedBox(
                          width: 160,
                          height: 36,
                          child: TextField(
                            controller: _bayarCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              hintText: '0',
                              prefixText: 'Rp ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                            ),
                            style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                            onChanged: (v) {
                              setState(() => _bayar = int.tryParse(v) ?? 0);
                            },
                          ),
                        ),
                      ],
                    ),

                    if (_bayar > 0) ...[
                      const SizedBox(height: 8),
                      _SummaryLine('Kembalian',
                          AppStore.formatRupiah(_kembalian < 0 ? 0 : _kembalian),
                          valueColor: _kembalian < 0
                              ? AppColors.accentRed
                              : AppColors.accentBlue),
                    ],

                    // Quick amount buttons
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _QuickBtn(label: '10.000', onTap: () {
                          final cur = int.tryParse(_bayarCtrl.text) ?? 0;
                          _bayarCtrl.text = '${cur + 10000}';
                          setState(() => _bayar = cur + 10000);
                        }),
                        const SizedBox(width: 6),
                        _QuickBtn(label: '20.000', onTap: () {
                          final cur = int.tryParse(_bayarCtrl.text) ?? 0;
                          _bayarCtrl.text = '${cur + 20000}';
                          setState(() => _bayar = cur + 20000);
                        }),
                        const SizedBox(width: 6),
                        _QuickBtn(label: 'Pas', onTap: () {
                          _bayarCtrl.text = '$_totalHarga';
                          setState(() => _bayar = _totalHarga);
                        }),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Process button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _keranjang.isNotEmpty ? _prosesBayar : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: Colors.grey.shade200,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                          shadowColor: AppColors.primary.withValues(alpha: 0.4),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline_rounded,
                                color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('Proses Pembayaran',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Clear button
                    if (_keranjang.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _keranjang.clear();
                          _bayarCtrl.clear();
                          _bayar = 0;
                        }),
                        icon: const Icon(Icons.delete_sweep_rounded,
                            color: AppColors.accentRed, size: 16),
                        label: const Text('Kosongkan Keranjang',
                            style: TextStyle(
                              color: AppColors.accentRed, fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Produk Card ──────────────────────────────────────────────────────────────
class _ProdukCard extends StatefulWidget {
  final Produk produk;
  final int inCartCount;
  final VoidCallback onTap;

  const _ProdukCard({
    required this.produk,
    required this.inCartCount,
    required this.onTap,
  });

  @override
  State<_ProdukCard> createState() => _ProdukCardState();
}

class _ProdukCardState extends State<_ProdukCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.produk;
    final isEmpty = p.stok == 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: isEmpty ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.inCartCount > 0
                  ? AppColors.primary
                  : _hovered
                      ? AppColors.primaryLight
                      : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : const Color(0x10000000),
                blurRadius: _hovered ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: p.warna.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(p.icon, color: p.warna, size: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(p.nama,
                        style: TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w700,
                          color: isEmpty ? Colors.grey : AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(p.hargaFormatted,
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800,
                          color: isEmpty ? Colors.grey : AppColors.primary,
                        )),
                    const SizedBox(height: 4),
                    Text('Stok: ${p.stok}',
                        style: TextStyle(
                          fontSize: 10,
                          color: p.stok <= 5 ? Colors.orange : Colors.grey.shade500,
                          fontWeight: p.stok <= 5 ? FontWeight.w700 : FontWeight.normal,
                        )),
                  ],
                ),
              ),

              // Badge cart count
              if (widget.inCartCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text('${widget.inCartCount}',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ),

              // Empty overlay
              if (isEmpty)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Habis',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 11, fontWeight: FontWeight.w700)),
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

// ─── Keranjang Item ───────────────────────────────────────────────────────────
class _KeranjangItem extends StatelessWidget {
  final ItemTransaksi item;
  final VoidCallback onAdd;
  final VoidCallback onReduce;
  final VoidCallback onDelete;

  const _KeranjangItem({
    required this.item,
    required this.onAdd,
    required this.onReduce,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.produk.warna.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(item.produk.icon, color: item.produk.warna, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.produk.nama,
                    style: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(AppStore.formatRupiah(item.subtotal),
                    style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
              ],
            ),
          ),
          // Qty control
          Row(
            children: [
              _QtyBtn(icon: Icons.remove, onTap: onReduce),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('${item.jumlah}',
                    style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800)),
              ),
              _QtyBtn(icon: Icons.add, onTap: onAdd),
            ],
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close_rounded, color: Colors.red, size: 16),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.primaryLighter,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: AppColors.primary, size: 14),
      ),
    );
  }
}

// ─── Summary Line ─────────────────────────────────────────────────────────────
class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _SummaryLine(this.label, this.value,
      {this.isBold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.normal,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
            )),
        const Spacer(),
        Text(value,
            style: TextStyle(
              fontSize: isBold ? 16 : 12,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            )),
      ],
    );
  }
}

// ─── Quick Amount Button ──────────────────────────────────────────────────────
class _QuickBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryLighter,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              )),
        ),
      ),
    );
  }
}

// ─── Struk Dialog ─────────────────────────────────────────────────────────────
class _StrukDialog extends StatelessWidget {
  final Transaksi transaksi;
  final int bayar;
  final int kembalian;
  final VoidCallback onSelesai;

  const _StrukDialog({
    required this.transaksi,
    required this.bayar,
    required this.kembalian,
    required this.onSelesai,
  });

  @override
  Widget build(BuildContext context) {
    final t = transaksi;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 12),
            const Text('Transaksi Berhasil!',
                style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                )),
            Text(t.id,
                style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 20),

            // Struk
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                children: [
                  const Text('— STRUK BELANJA —',
                      style: TextStyle(
                        fontSize: 11, letterSpacing: 2,
                        color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  ...t.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.produk.nama} x${item.jumlah}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(AppStore.formatRupiah(item.subtotal),
                            style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  )),
                  const Divider(height: 16),
                  _StrukRow('Total', AppStore.formatRupiah(t.totalBayar), bold: true),
                  _StrukRow('Bayar', AppStore.formatRupiah(bayar)),
                  _StrukRow('Kembalian', AppStore.formatRupiah(kembalian),
                      color: AppColors.accentBlue),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Print action - placeholder
                      onSelesai();
                    },
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Print'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSelesai,
                    icon: const Icon(Icons.check_rounded, color: Colors.white),
                    label: const Text('Selesai',
                        style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StrukRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const _StrukRow(this.label, this.value,
      {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
              fontSize: bold ? 13 : 12,
              fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
            )),
        const Spacer(),
        Text(value,
            style: TextStyle(
              fontSize: bold ? 14 : 12,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
              color: color,
            )),
      ],
    );
  }
}
