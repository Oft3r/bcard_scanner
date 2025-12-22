import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
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
        await db.execute('ALTER TABLE business_cards ADD COLUMN isFavorite INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE business_cards ADD COLUMN latitude REAL');
        await db.execute('ALTER TABLE business_cards ADD COLUMN longitude REAL');
        await db.execute('ALTER TABLE business_cards ADD COLUMN colorIndex INTEGER DEFAULT 0');
      } catch (e) {
        // Columns might already exist
      }
    }
  }

  Future<void> createCard(BusinessCard card) async {
    final db = await instance.database;
    await db.insert('business_cards', card.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
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
    return await db.delete(
      'business_cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCards(List<String> ids) async {
    final db = await instance.database;
    return await db.delete(
      'business_cards',
      where: 'id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
  }

  // Seed Data Function
  Future<void> seedDataIfEmpty() async {
    final cards = await readAllCards();
    if (cards.isNotEmpty) return;

    final random = Random();
    
    final seedCards = [
      BusinessCard(
        id: const Uuid().v4(),
        name: 'Sarah Connor',
        title: 'Security Consultant',
        company: 'Skynet Defense',
        phone: '+1 555 0199',
        email: 'sarah@resistance.org',
        website: 'www.no-fate.net',
        address: '123 Tech Blvd, Los Angeles, CA',
        imagePath: '',
        category: 'Tech',
        scanDate: DateTime.now(),
        isFavorite: true,
        latitude: 34.0522,
        longitude: -118.2437,
        colorIndex: 0,
      ),
      BusinessCard(
        id: const Uuid().v4(),
        name: 'Tony Stark',
        title: 'CEO',
        company: 'Stark Industries',
        phone: '+1 212 555 1000',
        email: 'tony@stark.com',
        website: 'www.stark.com',
        address: '890 Fifth Avenue, New York, NY',
        imagePath: '',
        category: 'Tech',
        scanDate: DateTime.now().subtract(const Duration(days: 1)),
        isFavorite: true,
        latitude: 40.7128,
        longitude: -74.0060,
        colorIndex: 1,
      ),
       BusinessCard(
        id: const Uuid().v4(),
        name: 'Walter White',
        title: 'Chemistry Teacher',
        company: 'J.P. Wynne High',
        phone: '+1 505 555 0000',
        email: 'heisenberg@chem.net',
        website: 'www.savewalterwhite.com',
        address: '308 Negra Arroyo Lane, Albuquerque, NM',
        imagePath: '',
        category: 'Services',
        scanDate: DateTime.now().subtract(const Duration(days: 2)),
        isFavorite: false,
        latitude: 35.0844,
        longitude: -106.6504,
        colorIndex: 2,
      ),
      BusinessCard(
        id: const Uuid().v4(),
        name: 'Leslie Knope',
        title: 'Deputy Director',
        company: 'Parks and Rec',
        phone: '+1 317 555 0123',
        email: 'knope@pawnee.gov',
        website: 'www.pawnee.gov',
        address: 'City Hall, Pawnee, IN',
        imagePath: '',
        category: 'Services',
        scanDate: DateTime.now().subtract(const Duration(days: 5)),
        isFavorite: true,
        latitude: 39.7684,
        longitude: -86.1581,
        colorIndex: 3,
      ),
    ];

    for (var card in seedCards) {
      await createCard(card);
    }
  }
}