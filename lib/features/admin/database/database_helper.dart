import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sobatkost.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE kamar (
  id_kamar $idType,
  nomor_kamar $textType,
  tipe_kamar $textType,
  harga_sewa $intType
)
''');

    await db.execute('''
CREATE TABLE penghuni (
  id_penghuni $idType,
  id_kamar $intType,
  nama_lengkap $textType,
  nomor_wa $textType,
  tanggal_masuk $textType,
  FOREIGN KEY (id_kamar) REFERENCES kamar (id_kamar) ON DELETE CASCADE
)
''');
  }

  // --- CRUD KAMAR ---
  Future<int> createKamar(Map<String, dynamic> kamar) async {
    final db = await instance.database;
    return await db.insert('kamar', kamar);
  }

  Future<List<Map<String, dynamic>>> readAllKamar() async {
    final db = await instance.database;
    return await db.query('kamar', orderBy: 'nomor_kamar ASC');
  }

  Future<int> updateKamar(Map<String, dynamic> kamar) async {
    final db = await instance.database;
    return db.update(
      'kamar',
      kamar,
      where: 'id_kamar = ?',
      whereArgs: [kamar['id_kamar']],
    );
  }

  Future<int> deleteKamar(int id) async {
    final db = await instance.database;
    return await db.delete(
      'kamar',
      where: 'id_kamar = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD PENGHUNI ---
  Future<int> createPenghuni(Map<String, dynamic> penghuni) async {
    final db = await instance.database;
    return await db.insert('penghuni', penghuni);
  }

  Future<List<Map<String, dynamic>>> readAllPenghuni() async {
    final db = await instance.database;
    // JOIN dengan tabel kamar untuk dapat info nomor kamar
    return await db.rawQuery('''
      SELECT penghuni.*, kamar.nomor_kamar 
      FROM penghuni 
      LEFT JOIN kamar ON penghuni.id_kamar = kamar.id_kamar
      ORDER BY penghuni.nama_lengkap ASC
    ''');
  }

  Future<int> updatePenghuni(Map<String, dynamic> penghuni) async {
    final db = await instance.database;
    return db.update(
      'penghuni',
      penghuni,
      where: 'id_penghuni = ?',
      whereArgs: [penghuni['id_penghuni']],
    );
  }

  Future<int> deletePenghuni(int id) async {
    final db = await instance.database;
    return await db.delete(
      'penghuni',
      where: 'id_penghuni = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('penghuni');
    await db.delete('kamar');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
