import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/order.dart';
import '../models/product.dart';

/// Local sqflite cache used as the app's offline fallback: the last
/// product catalog fetched from the backend and the last known order
/// list are mirrored here, so `MenuScreen` / `OrdersScreen` can still
/// show real (if slightly stale) content when the device has no
/// connectivity, rather than an empty/broken screen.
class LocalDbService {
  static final LocalDbService instance = LocalDbService._internal();
  LocalDbService._internal();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'caffora_cache.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // The cache is disposable — safe to drop and recreate rather
        // than write a real migration for what is just cached data.
        await db.execute('DROP TABLE IF EXISTS menu_items');
        await db.execute('DROP TABLE IF EXISTS products_cache');
        await db.execute('DROP TABLE IF EXISTS orders_cache');
        await _createTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE products_cache(
        id INTEGER PRIMARY KEY,
        name TEXT, description TEXT, price REAL,
        categoryId INTEGER, categoryName TEXT, imageUrl TEXT, status TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE orders_cache(
        id INTEGER PRIMARY KEY,
        orderNumber TEXT, status TEXT,
        subtotal REAL, pickupFee REAL, tax REAL, total REAL,
        placedAt TEXT, itemsSummary TEXT, tableNumber TEXT
      )
    ''');
  }

  Future<void> cacheProducts(List<Product> items) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('products_cache');
      for (final item in items) {
        await txn.insert('products_cache', item.toDbRow(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Product>> readCachedProducts() async {
    final db = await _database;
    final rows = await db.query('products_cache', orderBy: 'categoryName, name');
    return rows.map(Product.fromDbRow).toList();
  }

  Future<void> cacheOrders(List<CafforaOrder> orders) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('orders_cache');
      for (final order in orders) {
        await txn.insert('orders_cache', order.toDbRow(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<CafforaOrder>> readCachedOrders() async {
    final db = await _database;
    final rows = await db.query('orders_cache', orderBy: 'placedAt DESC');
    return rows.map(CafforaOrder.fromDbRow).toList();
  }
}
