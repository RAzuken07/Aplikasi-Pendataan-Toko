import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/app_data.dart';

class ProdukScreen extends StatefulWidget {
  const ProdukScreen({super.key});

  @override
  State<ProdukScreen> createState() => _ProdukScreenState();
}

class _ProdukScreenState extends State<ProdukScreen> {
  final AppStore _store = AppStore();
  String _searchQuery = '';
  String _selectedKategori = 'Semua';
  String _sortBy = 'nama';

  final List<String> _kategoris = ['Semua', 'Makanan', 'Minuman', 'Snack', 'Kebutuhan'];

  List<Produk> get _filteredProduk {
    List<Produk> list = _store.produkList;
    if (_selectedKategori != 'Semua') {
      list = list.where((p) => p.kategori == _selectedKategori).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where((p) =>
          p.nama.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    list = List.from(list);
    switch (_sortBy) {
      case 'harga':
        list.sort((a, b) => a.harga.compareTo(b.harga));
        break;
      case 'stok':
        list.sort((a, b) => a.stok.compareTo(b.stok));
        break;
      default:
        list.sort((a, b) => a.nama.compareTo(b.nama));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ───────────────────────────────────────────────────────────
        _buildHeader(),

        // ── Filters ──────────────────────────────────────────────────────────
        _buildFilters(),

        // ── Table ────────────────────────────────────────────────────────────
        Expanded(child: _buildTable()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Manajemen Produk',
                  style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  )),
              Text('${_store.produkList.length} produk terdaftar',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            ],
          ),
          const Spacer(),
          _GreenButton(
            icon: Icons.add_rounded,
            label: 'Tambah Produk',
            onTap: () => _showProdukDialog(context, null),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Search
          Expanded(
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
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Kategori filter
          _FilterDropdown(
            label: 'Kategori',
            value: _selectedKategori,
            items: _kategoris,
            onChanged: (v) => setState(() => _selectedKategori = v!),
          ),
          const SizedBox(width: 12),

          // Sort
          _FilterDropdown(
            label: 'Urutkan',
            value: _sortBy,
            items: const ['nama', 'harga', 'stok'],
            onChanged: (v) => setState(() => _sortBy = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    final produk = _filteredProduk;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.primaryLighter,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 48),
                  Expanded(flex: 3, child: _TableHeader('Nama Produk')),
                  Expanded(flex: 2, child: _TableHeader('Kategori')),
                  Expanded(flex: 2, child: _TableHeader('Harga')),
                  Expanded(flex: 1, child: _TableHeader('Stok')),
                  SizedBox(width: 100, child: _TableHeader('Aksi')),
                ],
              ),
            ),

            // Table rows
            Expanded(
              child: produk.isEmpty
                  ? const Center(
                      child: Text('Tidak ada produk ditemukan.',
                          style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.separated(
                      itemCount: produk.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      itemBuilder: (context, i) =>
                          _ProdukRow(
                            produk: produk[i],
                            onEdit: () => _showProdukDialog(context, produk[i]),
                            onDelete: () => _confirmDelete(context, produk[i]),
                          ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProdukDialog(BuildContext context, Produk? existing) {
    showDialog(
      context: context,
      builder: (_) => _ProdukDialog(
        existing: existing,
        onSave: (p) {
          setState(() {
            if (existing == null) {
              _store.produkList.add(p);
            }
          });
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Produk p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Produk'),
        content: Text('Hapus produk "${p.nama}"? Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              setState(() => _store.produkList.remove(p));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Table Widgets ─────────────────────────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: AppColors.primary,
        ));
  }
}

class _ProdukRow extends StatefulWidget {
  final Produk produk;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProdukRow({
    required this.produk,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ProdukRow> createState() => _ProdukRowState();
}

class _ProdukRowState extends State<_ProdukRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.produk;
    final isLow = p.stok <= 5;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hovered ? AppColors.primaryLighter.withOpacity(0.5) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: p.warna.withOpacity(0.13),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(p.icon, color: p.warna, size: 22),
            ),
            const SizedBox(width: 8),

            // Nama
            Expanded(
              flex: 3,
              child: Text(p.nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  )),
            ),

            // Kategori
            Expanded(
              flex: 2,
              child: Container(
                width: 70,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kategoriColor(p.kategori).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(p.kategori,
                    style: TextStyle(
                      color: _kategoriColor(p.kategori),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ),

            // Harga
            Expanded(
              flex: 2,
              child: Text(p.hargaFormatted,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.primary,
                  )),
            ),

            // Stok
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Text('${p.stok}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isLow ? Colors.red : AppColors.textPrimary,
                      )),
                  if (isLow) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 14),
                  ],
                ],
              ),
            ),

            // Actions
            SizedBox(
              width: 100,
              child: Row(
                children: [
                  _ActionBtn(icon: Icons.edit_rounded, color: AppColors.accentBlue, onTap: widget.onEdit),
                  const SizedBox(width: 6),
                  _ActionBtn(icon: Icons.delete_rounded, color: AppColors.accentRed, onTap: widget.onDelete),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _kategoriColor(String k) {
    switch (k) {
      case 'Makanan': return const Color(0xFFE65100);
      case 'Minuman': return const Color(0xFF1565C0);
      case 'Snack': return const Color(0xFF6A1B9A);
      case 'Kebutuhan': return const Color(0xFF00695C);
      default: return AppColors.primary;
    }
  }
}

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _hovered ? widget.color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(widget.icon, color: widget.color, size: 17),
        ),
      ),
    );
  }
}

// ─── Produk Dialog ─────────────────────────────────────────────────────────────
class _ProdukDialog extends StatefulWidget {
  final Produk? existing;
  final Function(Produk) onSave;

  const _ProdukDialog({required this.existing, required this.onSave});

  @override
  State<_ProdukDialog> createState() => _ProdukDialogState();
}

class _ProdukDialogState extends State<_ProdukDialog> {
  final _namaCtrl = TextEditingController();
  final _hargaCtrl = TextEditingController();
  final _stokCtrl = TextEditingController();
  String _kategori = 'Makanan';
  IconData _selectedIcon = Icons.inventory_2;
  Color _selectedColor = AppColors.primary;

  final List<IconData> _iconOptions = [
    Icons.inventory_2,
    Icons.fastfood,
    Icons.local_drink,
    Icons.cookie,
    Icons.ramen_dining,
    Icons.soup_kitchen,
    Icons.icecream,
  ];

  final List<Color> _colorOptions = [
    AppColors.primary,
    AppColors.accentBlue,
    AppColors.accentOrange,
    AppColors.accentRed,
    AppColors.primaryDark,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _namaCtrl.text = widget.existing!.nama;
      _hargaCtrl.text = widget.existing!.harga.toString();
      _stokCtrl.text = widget.existing!.stok.toString();
      _kategori = widget.existing!.kategori;
      _selectedIcon = widget.existing!.icon;
      _selectedColor = widget.existing!.warna;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? 'Edit Produk' : 'Tambah Produk',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            _Field(label: 'Nama Produk', controller: _namaCtrl, hint: 'Nama produk'),
            const SizedBox(height: 14),
            _Field(label: 'Harga (Rp)', controller: _hargaCtrl, hint: '0', isNumber: true),
            const SizedBox(height: 14),
            _Field(label: 'Stok', controller: _stokCtrl, hint: '0', isNumber: true),
            const SizedBox(height: 14),
            const Text('Logo Produk',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _selectedColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_selectedIcon, color: _selectedColor, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _iconOptions.map((icon) {
                      final isSelected = icon == _selectedIcon;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = icon),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              size: 24),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Warna Logo',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _colorOptions.map((color) {
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const Text('Kategori',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _kategori,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: ['Makanan', 'Minuman', 'Snack', 'Kebutuhan']
                  .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: (v) => setState(() => _kategori = v!),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(isEdit ? 'Simpan' : 'Tambah',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onSave() {
    if (_namaCtrl.text.isEmpty) return;
    final p = widget.existing;
    if (p != null) {
      p.nama = _namaCtrl.text;
      p.harga = int.tryParse(_hargaCtrl.text) ?? p.harga;
      p.stok = int.tryParse(_stokCtrl.text) ?? p.stok;
      p.kategori = _kategori;
      p.icon = _selectedIcon;
      p.warna = _selectedColor;
    } else {
      widget.onSave(Produk(
        id: 'p${DateTime.now().millisecondsSinceEpoch}',
        nama: _namaCtrl.text,
        kategori: _kategori,
        harga: int.tryParse(_hargaCtrl.text) ?? 0,
        stok: int.tryParse(_stokCtrl.text) ?? 0,
        icon: _selectedIcon,
        warna: _selectedColor,
      ));
    }
    Navigator.pop(context);
  }
}

// ─── Reusable Field ────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool isNumber;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.isNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}

// ─── Filter Dropdown ──────────────────────────────────────────────────────────
class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Green Button ─────────────────────────────────────────────────────────────
class _GreenButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GreenButton({required this.icon, required this.label, required this.onTap});

  @override
  State<_GreenButton> createState() => _GreenButtonState();
}

class _GreenButtonState extends State<_GreenButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _hovered
                  ? [AppColors.primaryDark, AppColors.primary]
                  : [AppColors.primaryLight, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(_hovered ? 0.45 : 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(widget.label,
                  style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
