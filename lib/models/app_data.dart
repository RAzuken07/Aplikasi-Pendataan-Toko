import 'package:flutter/material.dart';
import 'db_helper.dart';

// ─── Product Model ─────────────────────────────────────────────────────────────
class Produk {
  final String id;
  String nama;
  String kategori;
  int harga;
  int stok;
  IconData icon;
  Color warna;

  Produk({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.harga,
    required this.stok,
    required this.icon,
    required this.warna,
  });

  String get hargaFormatted {
    final s = harga.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write('.');
      result.write(s[i]);
    }
    return 'Rp ${result.toString()}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'kategori': kategori,
      'harga': harga,
      'stok': stok,
      'iconCode': icon.codePoint,
      'colorValue': warna.toARGB32(),
    };
  }

  factory Produk.fromMap(Map<String, dynamic> map) {
    return Produk(
      id: map['id'] as String,
      nama: map['nama'] as String,
      kategori: map['kategori'] as String,
      harga: map['harga'] as int,
      stok: map['stok'] as int,
      icon: IconData(map['iconCode'] as int, fontFamily: 'MaterialIcons'),
      warna: Color(map['colorValue'] as int),
    );
  }
}

// ─── Transaction Item Model ────────────────────────────────────────────────────
class ItemTransaksi {
  final Produk produk;
  int jumlah;

  ItemTransaksi({required this.produk, required this.jumlah});

  int get subtotal => produk.harga * jumlah;
}

// ─── Transaction Model ────────────────────────────────────────────────────────
class Transaksi {
  final String id;
  final DateTime tanggal;
  final List<ItemTransaksi> items;
  final int totalBayar;
  final String kasir;

  Transaksi({
    required this.id,
    required this.tanggal,
    required this.items,
    required this.totalBayar,
    required this.kasir,
  });

  int get totalItem => items.fold(0, (sum, i) => sum + i.jumlah);

  String get totalFormatted {
    final s = totalBayar.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write('.');
      result.write(s[i]);
    }
    return 'Rp ${result.toString()}';
  }

  String get tanggalFormatted {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final h = tanggal.hour.toString().padLeft(2, '0');
    final m = tanggal.minute.toString().padLeft(2, '0');
    return '${tanggal.day} ${months[tanggal.month]} ${tanggal.year}, $h:$m';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tanggal': tanggal.toIso8601String(),
      'totalBayar': totalBayar,
      'kasir': kasir,
    };
  }

  factory Transaksi.fromMap(Map<String, dynamic> map, List<ItemTransaksi> items) {
    return Transaksi(
      id: map['id'] as String,
      tanggal: DateTime.parse(map['tanggal'] as String),
      totalBayar: map['totalBayar'] as int,
      kasir: map['kasir'] as String,
      items: items,
    );
  }
}

// ─── Singleton App Store ───────────────────────────────────────────────────────
class AppStore {
  static final AppStore _instance = AppStore._internal();
  factory AppStore() => _instance;
  AppStore._internal();

  List<Produk> produkList = [];
  List<Transaksi> transaksiList = [];

  // Inisialisasi awal database dan memuat memori
  Future<void> initData() async {
    final db = await DatabaseHelper.instance.database;

    // Load produk
    final List<Map<String, dynamic>> produkMaps = await db.query('produk');
    if (produkMaps.isEmpty) {
      // Masukkan data default jika database kosong
      await _insertDefaultData();
    } else {
      produkList = produkMaps.map((e) => Produk.fromMap(e)).toList();
    }

    // Load transaksi
    final List<Map<String, dynamic>> trxMaps = await db.query('transaksi', orderBy: 'tanggal DESC');
    final List<Transaksi> loadedTrx = [];
    
    for (var trxMap in trxMaps) {
      final String trxId = trxMap['id'];
      
      // Ambil items untuk transaksi ini
      final List<Map<String, dynamic>> itemsMap = await db.query(
        'transaksi_item',
        where: 'id_transaksi = ?',
        whereArgs: [trxId],
      );

      List<ItemTransaksi> items = [];
      for (var itemMap in itemsMap) {
        final produkId = itemMap['id_produk'];
        // Pastikan produk masih ada, jika tidak abaikan
        try {
          final p = produkList.firstWhere((p) => p.id == produkId);
          items.add(ItemTransaksi(produk: p, jumlah: itemMap['jumlah'] as int));
        } catch (e) {
          // Produk terhapus (jika ada fitur hapus masa depan)
        }
      }

      loadedTrx.add(Transaksi.fromMap(trxMap, items));
    }
    transaksiList = loadedTrx;
  }

  Future<void> _insertDefaultData() async {
    final defaultProducts = [
      Produk(id: 'p1', nama: 'Indomie Goreng', kategori: 'Makanan', harga: 3500, stok: 120, icon: Icons.ramen_dining, warna: const Color(0xFFE65100)),
      Produk(id: 'p2', nama: 'Aqua 600ml', kategori: 'Minuman', harga: 4000, stok: 80, icon: Icons.water_drop, warna: const Color(0xFF1565C0)),
      Produk(id: 'p3', nama: 'Chitato 68g', kategori: 'Snack', harga: 10000, stok: 45, icon: Icons.breakfast_dining, warna: const Color(0xFFBF360C)),
      Produk(id: 'p4', nama: 'Beng-beng', kategori: 'Snack', harga: 2500, stok: 60, icon: Icons.cookie, warna: const Color(0xFF6A1B9A)),
      Produk(id: 'p5', nama: 'Mie Sedaap', kategori: 'Makanan', harga: 3000, stok: 5, icon: Icons.soup_kitchen, warna: const Color(0xFF2E7D32)),
      Produk(id: 'p6', nama: 'Teh Botol 500ml', kategori: 'Minuman', harga: 4500, stok: 3, icon: Icons.local_drink, warna: const Color(0xFF1B5E20)),
      Produk(id: 'p7', nama: 'Oreo 150g', kategori: 'Snack', harga: 8000, stok: 5, icon: Icons.cookie_outlined, warna: const Color(0xFF212121)),
      Produk(id: 'p8', nama: 'Sabun Lifebuoy', kategori: 'Kebutuhan', harga: 7500, stok: 4, icon: Icons.soap, warna: const Color(0xFF0288D1)),
      Produk(id: 'p9', nama: 'Pocari Sweat', kategori: 'Minuman', harga: 8500, stok: 30, icon: Icons.sports_bar, warna: const Color(0xFF0277BD)),
      Produk(id: 'p10', nama: 'Permen Relaxa', kategori: 'Snack', harga: 500, stok: 200, icon: Icons.star, warna: const Color(0xFFF9A825)),
    ];

    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();

    for (var p in defaultProducts) {
      batch.insert('produk', p.toMap());
    }

    await batch.commit(noResult: true);
    produkList = defaultProducts;
    transaksiList = [];
  }

  // Helpers
  List<Produk> get lowStockProduk =>
      produkList.where((p) => p.stok <= 5).toList();

  int get totalPendapatanHariIni {
    final now = DateTime.now();
    return transaksiList.fold(0, (sum, t) {
      if (t.tanggal.day == now.day && t.tanggal.month == now.month && t.tanggal.year == now.year) {
        return sum + t.totalBayar;
      }
      return sum;
    });
  }

  String get totalPendapatanFormatted {
    final s = totalPendapatanHariIni.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write('.');
      result.write(s[i]);
    }
    return 'Rp ${result.toString()}';
  }

  static String formatRupiah(int amount) {
    final s = amount.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write('.');
      result.write(s[i]);
    }
    return 'Rp ${result.toString()}';
  }

  Future<void> tambahTransaksi(Transaksi t) async {
    // Kurangi stok di list lokal
    for (final item in t.items) {
      item.produk.stok -= item.jumlah;
    }
    // Update local list
    transaksiList.insert(0, t);

    // Update di Local SQLite Data
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();

    // 1. Simpan Transaksi Utama
    batch.insert('transaksi', t.toMap());

    // 2. Simpan Item Transaksi
    for (final item in t.items) {
      batch.insert('transaksi_item', {
        'id_transaksi': t.id,
        'id_produk': item.produk.id,
        'jumlah': item.jumlah,
      });

      // 3. Update Stok Produk di tabel Produk
      batch.update(
        'produk',
        {'stok': item.produk.stok},
        where: 'id = ?',
        whereArgs: [item.produk.id],
      );
    }
    
    await batch.commit(noResult: true);
  }
}
