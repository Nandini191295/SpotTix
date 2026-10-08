import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class WalletDBHelper {
  static Database? _db;
  static const String DB_NAME = 'wallet.db';
  static const String WALLET_TABLE = 'wallet';
  static const String TX_TABLE = 'transactions';

  static Future<Database> initDB() async {
    if (_db != null) return _db!;
    String path = join(await getDatabasesPath(), DB_NAME);

    _db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE $WALLET_TABLE(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userEmail TEXT UNIQUE,
          balance REAL,
          totalEarned REAL,
          totalSpent REAL
        )
      ''');

      await db.execute('''
        CREATE TABLE $TX_TABLE(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userEmail TEXT,
          title TEXT,
          amount REAL,
          type TEXT,
          date TEXT,
          time TEXT,
          status TEXT
        )
      ''');
    });

    return _db!;
  }

  // Insert/update wallet per user
  static Future<void> insertWallet(String userEmail, Map<String, dynamic> wallet) async {
    final db = await initDB();
    await db.insert(
      WALLET_TABLE,
      {'userEmail': userEmail, ...wallet},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get wallet for a specific user
  static Future<Map<String, dynamic>?> getWallet(String userEmail) async {
    final db = await initDB();
    final res = await db.query(
      WALLET_TABLE,
      where: 'userEmail = ?',
      whereArgs: [userEmail],
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  // Insert transaction per user
  static Future<void> insertTransaction(String userEmail, Map<String, dynamic> tx) async {
    final db = await initDB();
    await db.insert(TX_TABLE, {'userEmail': userEmail, ...tx});
  }

  // Get transactions for a user
  static Future<List<Map<String, dynamic>>> getTransactions(String userEmail) async {
    final db = await initDB();
    return await db.query(
      TX_TABLE,
      where: 'userEmail = ?',
      whereArgs: [userEmail],
      orderBy: 'id DESC',
    );
  }
}
