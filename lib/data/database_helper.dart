import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/business_card.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cards_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE business_cards (
        id TEXT PRIMARY KEY,
        name TEXT,
        title TEXT,
        company TEXT,
        phone TEXT,
        email TEXT,
        website TEXT,
        address TEXT,
        imagePath TEXT,
        category TEXT,
        scanDate TEXT,
        isFavorite INTEGER,
        latitude REAL,
        longitude REAL,
        colorIndex INTEGER
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Simple migration: Add new columns if they don't exist
      // Since SQLite doesn't support IF NOT EXISTS in ALTER TABLE easily for all versions,
      // we'll just try/catch or assume clean install for prototype mostly.
      // But for robustness:
      try {
        await db.execute(
          'ALTER TABLE business_cards ADD COLUMN isFavorite INTEGER DEFAULT 0',
        );
        await db.execute('ALTER TABLE business_cards ADD COLUMN latitude REAL');
        await db.execute(
          'ALTER TABLE business_cards ADD COLUMN longitude REAL',
        );
        await db.execute(
          'ALTER TABLE business_cards ADD COLUMN colorIndex INTEGER DEFAULT 0',
        );
      } catch (e) {
        // Columns might already exist
      }
    }
  }

  Future<void> createCard(BusinessCard card) async {
    final db = await instance.database;
    await db.insert(
      'business_cards',
      card.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BusinessCard>> readAllCards() async {
    final db = await instance.database;
    final orderBy = 'scanDate DESC';
    final result = await db.query('business_cards', orderBy: orderBy);
    return result.map((json) => BusinessCard.fromMap(json)).toList();
  }

  Future<int> updateCard(BusinessCard card) async {
    final db = await instance.database;
    return db.update(
      'business_cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<int> deleteCard(String id) async {
    final db = await instance.database;
    return await db.delete('business_cards', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCards(List<String> ids) async {
    final db = await instance.database;
    return await db.delete(
      'business_cards',
      where: 'id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
  }
}
