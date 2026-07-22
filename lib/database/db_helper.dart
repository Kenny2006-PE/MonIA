import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('asistente_financiero.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to cards table
      await db.execute('ALTER TABLE cards ADD COLUMN tea REAL');
      await db.execute('ALTER TABLE cards ADD COLUMN trea REAL');
      await db.execute('ALTER TABLE cards ADD COLUMN maintenance REAL');
      await db.execute('ALTER TABLE cards ADD COLUMN billingDate INTEGER');
      await db.execute('ALTER TABLE cards ADD COLUMN debt REAL');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE cards ADD COLUMN linkedWallets TEXT');
      await db.execute('''
        CREATE TABLE transactions (
          id TEXT PRIMARY KEY,
          amount REAL,
          date TEXT,
          type TEXT,
          cardId TEXT,
          walletUsed TEXT,
          description TEXT
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        isCredit INTEGER,
        name TEXT,
        nickname TEXT,
        balance REAL,
        creditLimit REAL,
        tea REAL,
        trea REAL,
        maintenance REAL,
        billingDate INTEGER,
        debt REAL,
        linkedWallets TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL,
        date TEXT,
        type TEXT,
        cardId TEXT,
        walletUsed TEXT,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE chats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        subtitle TEXT,
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chatId INTEGER,
        text TEXT,
        isUser INTEGER,
        time TEXT,
        FOREIGN KEY (chatId) REFERENCES chats (id) ON DELETE CASCADE
      )
    ''');
    
    // Default income setting
    await db.insert('settings', {'key': 'monthlyIncome', 'value': '3500.0'});
  }

  // --- Settings (Income) CRUD ---
  Future<double> getMonthlyIncome() async {
    final db = await instance.database;
    final maps = await db.query('settings', where: 'key = ?', whereArgs: ['monthlyIncome']);
    if (maps.isNotEmpty) {
      return double.tryParse(maps.first['value'] as String) ?? 0.0;
    }
    return 0.0;
  }

  Future<int> updateMonthlyIncome(double income) async {
    final db = await instance.database;
    return await db.update(
      'settings',
      {'value': income.toString()},
      where: 'key = ?',
      whereArgs: ['monthlyIncome'],
    );
  }

  // --- Cards CRUD ---
  Future<void> _ensureCardColumns(Database db) async {
    final columns = ['tea REAL', 'trea REAL', 'maintenance REAL', 'billingDate INTEGER', 'debt REAL', 'linkedWallets TEXT'];
    for (var col in columns) {
      try {
        await db.execute('ALTER TABLE cards ADD COLUMN $col');
      } catch (_) {}
    }
  }

  Future<int> createCard(Map<String, dynamic> card) async {
    final db = await instance.database;
    try {
      return await db.insert('cards', card);
    } catch (e) {
      if (e.toString().contains('no such column')) {
        await _ensureCardColumns(db);
        return await db.insert('cards', card);
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> readAllCards() async {
    final db = await instance.database;
    try {
      return await db.query('cards');
    } catch (e) {
      if (e.toString().contains('no such column')) {
        await _ensureCardColumns(db);
        return await db.query('cards');
      }
      rethrow;
    }
  }

  Future<int> updateCard(Map<String, dynamic> card) async {
    final db = await instance.database;
    try {
      return await db.update(
        'cards',
        card,
        where: 'id = ?',
        whereArgs: [card['id']],
      );
    } catch (e) {
      if (e.toString().contains('no such column')) {
        await _ensureCardColumns(db);
        return await db.update(
          'cards',
          card,
          where: 'id = ?',
          whereArgs: [card['id']],
        );
      }
      rethrow;
    }
  }

  Future<int> deleteCard(int id) async {
    final db = await instance.database;
    return await db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Chats CRUD ---
  Future<int> createChat(Map<String, dynamic> chat) async {
    final db = await instance.database;
    return await db.insert('chats', chat);
  }

  Future<List<Map<String, dynamic>>> readAllChats() async {
    final db = await instance.database;
    return await db.query('chats', orderBy: 'id DESC');
  }

  Future<int> updateChatSubtitle(int id, String subtitle) async {
    final db = await instance.database;
    return await db.update(
      'chats',
      {'subtitle': subtitle},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Messages CRUD ---
  Future<int> createMessage(Map<String, dynamic> message) async {
    final db = await instance.database;
    return await db.insert('messages', message);
  }

  Future<List<Map<String, dynamic>>> readMessagesForChat(int chatId) async {
    final db = await instance.database;
    return await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
    );
  }

  // --- Transactions CRUD ---
  Future<void> createTransaction(Map<String, dynamic> transaction) async {
    final db = await instance.database;
    await db.insert('transactions', transaction);
  }

  Future<List<Map<String, dynamic>>> readAllTransactions() async {
    final db = await instance.database;
    return await db.query('transactions', orderBy: 'date DESC');
  }

  Future<int> deleteTransaction(String id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
