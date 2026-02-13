import '../database_helper.dart';
import '../models/document_model.dart';

class DocumentDao {
  final dbProvider = DatabaseHelper.instance;

  Future<int> create(Document document) async {
    final db = await dbProvider.database;
    return await db.insert('documents', document.toMap());
  }

  Future<Document?> read(int id) async {
    final db = await dbProvider.database;
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

  Future<List<Document>> readAll() async {
    final db = await dbProvider.database;
    final result = await db.query('documents');
    return result.map((json) => Document.fromMap(json)).toList();
  }

  Future<int> update(Document document) async {
    final db = await dbProvider.database;
    return db.update(
      'documents',
      document.toMap(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await dbProvider.database;
    return await db.delete(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
