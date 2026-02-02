import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/document_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('motofile.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
CREATE TABLE documents (
  id $idType,
  doc_type $textType,
  file_path $textType,
  issue_date $textType,
  expiry_date $textType,
  status $textType
)
''');
  }

  Future<int> create(Document document) async {
    final db = await instance.database;
    return await db.insert('documents', document.toMap());
  }

  Future<Document?> readDocument(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'documents',
      columns: ['id', 'doc_type', 'file_path', 'issue_date', 'expiry_date', 'status'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Document.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Document>> readAllDocuments() async {
    final db = await instance.database;
    final result = await db.query('documents');
    return result.map((json) => Document.fromMap(json)).toList();
  }

  Future<int> update(Document document) async {
    final db = await instance.database;
    return db.update(
      'documents',
      document.toMap(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
