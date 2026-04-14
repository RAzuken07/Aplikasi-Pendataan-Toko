import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('aplikasi_pendataan.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'AplikasiPendataan', filePath);

    // Pastikan direktori AplikasiPendataan ada
    final dir = Directory(join(directory.path, 'AplikasiPendataan'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Tabel Produk
    await db.execute('''
      CREATE TABLE produk (
        id TEXT PRIMARY KEY,
        nama TEXT NOT NULL,
        kategori TEXT NOT NULL,
        harga INTEGER NOT NULL,
        stok INTEGER NOT NULL,
        iconCode INTEGER NOT NULL,
        colorValue INTEGER NOT NULL
      )
    ''');

    // Tabel Transaksi
    await db.execute('''
      CREATE TABLE transaksi (
        id TEXT PRIMARY KEY,
        tanggal TEXT NOT NULL,
        totalBayar INTEGER NOT NULL,
        kasir TEXT NOT NULL
      )
    ''');

    // Tabel Item Transaksi
    await db.execute('''
      CREATE TABLE transaksi_item (
        id_transaksi TEXT NOT NULL,
        id_produk TEXT NOT NULL,
        jumlah INTEGER NOT NULL,
        FOREIGN KEY (id_transaksi) REFERENCES transaksi (id) ON DELETE CASCADE,
        FOREIGN KEY (id_produk) REFERENCES produk (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
