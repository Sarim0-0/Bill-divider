import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/person.dart';
import '../models/event.dart';
import '../models/item.dart';
import '../models/variant.dart';
import '../models/add_on.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'bill_divider.db');
    return await openDatabase(
      path,
      version: 9,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add events table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          date TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      // Add event_people junction table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS event_people (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id INTEGER NOT NULL,
          person_id INTEGER NOT NULL,
          FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
          FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE CASCADE,
          UNIQUE(event_id, person_id)
        )
      ''');
    }
    if (oldVersion < 4) {
      // Add items table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          price REAL NOT NULL,
          FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 5) {
      // Add variants table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS variants (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          price REAL NOT NULL,
          FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
        )
      ''');
      // Add add_ons table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS add_ons (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          price REAL NOT NULL,
          FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 6) {
      // Add item_variant_selections table to store selected variants for items
      // Only one variant per item (item_id is unique)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS item_variant_selections (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_id INTEGER NOT NULL UNIQUE,
          variant_id INTEGER NOT NULL,
          quantity INTEGER NOT NULL DEFAULT 1,
          FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE,
          FOREIGN KEY (variant_id) REFERENCES variants(id) ON DELETE CASCADE
        )
      ''');
      // Add item_addon_selections table to store selected add-ons for items
      // Multiple add-ons per item allowed
      await db.execute('''
        CREATE TABLE IF NOT EXISTS item_addon_selections (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_id INTEGER NOT NULL,
          addon_id INTEGER NOT NULL,
          quantity INTEGER NOT NULL DEFAULT 1,
          FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE,
          FOREIGN KEY (addon_id) REFERENCES add_ons(id) ON DELETE CASCADE,
          UNIQUE(item_id, addon_id)
        )
      ''');
    }
    if (oldVersion < 7) {
      // Add event_order_items table to store items added to order
      await db.execute('''
        CREATE TABLE IF NOT EXISTS event_order_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id INTEGER NOT NULL,
          item_id INTEGER NOT NULL,
          variant_id INTEGER,
          quantity INTEGER NOT NULL DEFAULT 1,
          total_price REAL NOT NULL,
          FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
          FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE,
          FOREIGN KEY (variant_id) REFERENCES variants(id) ON DELETE SET NULL
        )
      ''');
      // Add event_order_item_addons table to store add-ons for order items
      await db.execute('''
        CREATE TABLE IF NOT EXISTS event_order_item_addons (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_item_id INTEGER NOT NULL,
          addon_id INTEGER NOT NULL,
          quantity INTEGER NOT NULL DEFAULT 1,
          FOREIGN KEY (order_item_id) REFERENCES event_order_items(id) ON DELETE CASCADE,
          FOREIGN KEY (addon_id) REFERENCES add_ons(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 8) {
      // Add event_payment_settings table and calculated columns if needed
      await db.execute('''
        CREATE TABLE IF NOT EXISTS event_payment_settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id INTEGER NOT NULL UNIQUE,
          payment_method TEXT,
          tax_type TEXT,
          calculated_tax REAL,
          calculated_total REAL,
          FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
        )
      ''');
      try {
        await db.execute('ALTER TABLE event_payment_settings ADD COLUMN calculated_tax REAL');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE event_payment_settings ADD COLUMN calculated_total REAL');
      } catch (_) {}
    }
    if (oldVersion < 9) {
      // Add discount and foodpanda columns to event_payment_settings
      try {
        await db.execute('ALTER TABLE event_payment_settings ADD COLUMN discount_percentage REAL');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE event_payment_settings ADD COLUMN is_foodpanda INTEGER DEFAULT 0');
      } catch (_) {}
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create people table
    await db.execute('''
      CREATE TABLE people (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // Create events table
    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // Create event_people junction table
    await db.execute('''
      CREATE TABLE event_people (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        person_id INTEGER NOT NULL,
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
        FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE CASCADE,
        UNIQUE(event_id, person_id)
      )
    ''');

    // Create items table
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
      )
    ''');

    // Create variants table
    await db.execute('''
      CREATE TABLE variants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
      )
    ''');

    // Create add_ons table
    await db.execute('''
      CREATE TABLE add_ons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
      )
    ''');

    // Create item_variant_selections table to store selected variants for items
    // Only one variant per item (item_id is unique)
    await db.execute('''
      CREATE TABLE item_variant_selections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL UNIQUE,
        variant_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE,
        FOREIGN KEY (variant_id) REFERENCES variants(id) ON DELETE CASCADE
      )
    ''');

    // Create item_addon_selections table to store selected add-ons for items
    await db.execute('''
      CREATE TABLE item_addon_selections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        addon_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE,
        FOREIGN KEY (addon_id) REFERENCES add_ons(id) ON DELETE CASCADE,
        UNIQUE(item_id, addon_id)
      )
    ''');

    // Create event_order_items table to store items added to order
    await db.execute('''
      CREATE TABLE event_order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        variant_id INTEGER,
        quantity INTEGER NOT NULL DEFAULT 1,
        total_price REAL NOT NULL,
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
        FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE,
        FOREIGN KEY (variant_id) REFERENCES variants(id) ON DELETE SET NULL
      )
    ''');

    // Create event_order_item_addons table to store add-ons for order items
    await db.execute('''
      CREATE TABLE event_order_item_addons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_item_id INTEGER NOT NULL,
        addon_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (order_item_id) REFERENCES event_order_items(id) ON DELETE CASCADE,
        FOREIGN KEY (addon_id) REFERENCES add_ons(id) ON DELETE CASCADE
      )
    ''');

    // Create event_payment_settings table to store payment method and tax type
    await db.execute('''
      CREATE TABLE event_payment_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL UNIQUE,
        payment_method TEXT,
        tax_type TEXT,
        calculated_tax REAL,
        calculated_total REAL,
        discount_percentage REAL,
        is_foodpanda INTEGER DEFAULT 0,
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
      )
    ''');
  }

  // ==================== People Operations ====================

  Future<int> insertPerson(Person person) async {
    final db = await database;
    return await db.insert('people', person.toMap());
  }

  Future<List<Person>> getAllPeople() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'people',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Person.fromMap(maps[i]));
  }

  Future<Person?> getPersonById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('people', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Person.fromMap(maps.first);
  }

  Future<int> updatePerson(Person person) async {
    final db = await database;
    return await db.update(
      'people',
      person.toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
  }

  Future<int> deletePerson(int id) async {
    final db = await database;
    return await db.delete('people', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Event Operations ====================

  Future<int> insertEvent(Event event) async {
    final db = await database;
    return await db.insert('events', event.toMap());
  }

  Future<List<Event>> getAllEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      orderBy: 'date DESC, name ASC',
    );
    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }

  Future<Event?> getEventById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('events', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Event.fromMap(maps.first);
  }

  Future<int> updateEvent(Event event) async {
    final db = await database;
    return await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await database;
    return await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Event-People Operations ====================

  Future<void> addPersonToEvent(int eventId, int personId) async {
    final db = await database;
    await db.insert(
      'event_people',
      {'event_id': eventId, 'person_id': personId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removePersonFromEvent(int eventId, int personId) async {
    final db = await database;
    await db.delete(
      'event_people',
      where: 'event_id = ? AND person_id = ?',
      whereArgs: [eventId, personId],
    );
  }

  Future<List<Person>> getPeopleInEvent(int eventId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.* FROM people p
      INNER JOIN event_people ep ON p.id = ep.person_id
      WHERE ep.event_id = ?
      ORDER BY p.name ASC
    ''', [eventId]);
    return List.generate(maps.length, (i) => Person.fromMap(maps[i]));
  }

  Future<List<Event>> getEventsForPerson(int personId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT e.* FROM events e
      INNER JOIN event_people ep ON e.id = ep.event_id
      WHERE ep.person_id = ?
      ORDER BY e.date DESC, e.name ASC
    ''', [personId]);
    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }

  // ==================== Item Operations ====================

  Future<int> insertItem(Item item) async {
    final db = await database;
    return await db.insert('items', item.toMap());
  }

  Future<List<Item>> getItemsByEvent(int eventId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'event_id = ?',
      whereArgs: [eventId],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Item.fromMap(maps[i]));
  }

  Future<Item?> getItemById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('items', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Item.fromMap(maps.first);
  }

  Future<int> updateItem(Item item) async {
    final db = await database;
    return await db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  /// Get all items with the same name
  Future<List<Item>> getItemsByName(String name) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'name = ?',
      whereArgs: [name],
      orderBy: 'event_id ASC',
    );
    return List.generate(maps.length, (i) => Item.fromMap(maps[i]));
  }

  /// Update price for all items with the same name in present and future events only
  /// Returns the number of items updated
  Future<int> updateItemPriceForPresentAndFuture(String itemName, double newPrice) async {
    final db = await database;
    
    // Get today's date at midnight for comparison
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    // Update items where:
    // 1. The item name matches
    // 2. The event date is today or in the future
    final result = await db.rawUpdate('''
      UPDATE items
      SET price = ?
      WHERE name = ? 
      AND event_id IN (
        SELECT id FROM events 
        WHERE date >= ?
      )
    ''', [newPrice, itemName, todayStr]);
    
    return result;
  }

  // ==================== Variant Operations ====================

  Future<int> insertVariant(Variant variant) async {
    final db = await database;
    return await db.insert('variants', variant.toMap());
  }

  Future<List<Variant>> getVariantsByItem(int itemId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'variants',
      where: 'item_id = ?',
      whereArgs: [itemId],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Variant.fromMap(maps[i]));
  }

  Future<Variant?> getVariantById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('variants', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Variant.fromMap(maps.first);
  }

  Future<int> updateVariant(Variant variant) async {
    final db = await database;
    return await db.update(
      'variants',
      variant.toMap(),
      where: 'id = ?',
      whereArgs: [variant.id],
    );
  }

  Future<int> deleteVariant(int id) async {
    final db = await database;
    return await db.delete('variants', where: 'id = ?', whereArgs: [id]);
  }

  /// Update price for all variants with the same name for the same item
  Future<int> updateVariantPriceForPresentAndFuture(int itemId, String variantName, double newPrice) async {
    final db = await database;
    
    // Get today's date at midnight for comparison
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    // Update variants where:
    // 1. The variant name matches
    // 2. The item_id matches
    // 3. The item belongs to an event that is today or in the future
    final result = await db.rawUpdate('''
      UPDATE variants
      SET price = ?
      WHERE name = ? 
      AND item_id = ?
      AND item_id IN (
        SELECT i.id FROM items i
        INNER JOIN events e ON i.event_id = e.id
        WHERE e.date >= ?
      )
    ''', [newPrice, variantName, itemId, todayStr]);
    
    return result;
  }

  // ==================== AddOn Operations ====================

  Future<int> insertAddOn(AddOn addOn) async {
    final db = await database;
    return await db.insert('add_ons', addOn.toMap());
  }

  Future<List<AddOn>> getAddOnsByItem(int itemId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'add_ons',
      where: 'item_id = ?',
      whereArgs: [itemId],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => AddOn.fromMap(maps[i]));
  }

  Future<AddOn?> getAddOnById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('add_ons', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return AddOn.fromMap(maps.first);
  }

  Future<int> updateAddOn(AddOn addOn) async {
    final db = await database;
    return await db.update(
      'add_ons',
      addOn.toMap(),
      where: 'id = ?',
      whereArgs: [addOn.id],
    );
  }

  Future<int> deleteAddOn(int id) async {
    final db = await database;
    return await db.delete('add_ons', where: 'id = ?', whereArgs: [id]);
  }

  /// Update price for all add-ons with the same name for the same item
  Future<int> updateAddOnPriceForPresentAndFuture(int itemId, String addOnName, double newPrice) async {
    final db = await database;
    
    // Get today's date at midnight for comparison
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    // Update add-ons where:
    // 1. The add-on name matches
    // 2. The item_id matches
    // 3. The item belongs to an event that is today or in the future
    final result = await db.rawUpdate('''
      UPDATE add_ons
      SET price = ?
      WHERE name = ? 
      AND item_id = ?
      AND item_id IN (
        SELECT i.id FROM items i
        INNER JOIN events e ON i.event_id = e.id
        WHERE e.date >= ?
      )
    ''', [newPrice, addOnName, itemId, todayStr]);
    
    return result;
  }

  // ==================== Item Selection Operations ====================

  /// Save or update variant selection for an item
  Future<void> saveItemVariantSelection(int itemId, int variantId, int quantity) async {
    final db = await database;
    await db.insert(
      'item_variant_selections',
      {
        'item_id': itemId,
        'variant_id': variantId,
        'quantity': quantity,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Delete variant selection for an item
  Future<void> deleteItemVariantSelection(int itemId) async {
    final db = await database;
    await db.delete(
      'item_variant_selections',
      where: 'item_id = ?',
      whereArgs: [itemId],
    );
  }

  /// Get variant selection for an item
  Future<Map<String, dynamic>?> getItemVariantSelection(int itemId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'item_variant_selections',
      where: 'item_id = ?',
      whereArgs: [itemId],
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  /// Save or update add-on selection for an item
  Future<void> saveItemAddOnSelection(int itemId, int addonId, int quantity) async {
    final db = await database;
    await db.insert(
      'item_addon_selections',
      {
        'item_id': itemId,
        'addon_id': addonId,
        'quantity': quantity,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Delete add-on selection for an item
  Future<void> deleteItemAddOnSelection(int itemId, int addonId) async {
    final db = await database;
    await db.delete(
      'item_addon_selections',
      where: 'item_id = ? AND addon_id = ?',
      whereArgs: [itemId, addonId],
    );
  }

  /// Delete all add-on selections for an item
  Future<void> deleteAllItemAddOnSelections(int itemId) async {
    final db = await database;
    await db.delete(
      'item_addon_selections',
      where: 'item_id = ?',
      whereArgs: [itemId],
    );
  }

  /// Get all add-on selections for an item
  Future<List<Map<String, dynamic>>> getItemAddOnSelections(int itemId) async {
    final db = await database;
    return await db.query(
      'item_addon_selections',
      where: 'item_id = ?',
      whereArgs: [itemId],
    );
  }

  /// Get variant with details for an item
  Future<Map<String, dynamic>?> getItemVariantWithDetails(int itemId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT ivs.*, v.name as variant_name, v.price as variant_price
      FROM item_variant_selections ivs
      INNER JOIN variants v ON ivs.variant_id = v.id
      WHERE ivs.item_id = ?
    ''', [itemId]);
    if (maps.isEmpty) return null;
    return maps.first;
  }

  /// Get all add-ons with details for an item
  Future<List<Map<String, dynamic>>> getItemAddOnsWithDetails(int itemId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT ias.*, ao.name as addon_name, ao.price as addon_price
      FROM item_addon_selections ias
      INNER JOIN add_ons ao ON ias.addon_id = ao.id
      WHERE ias.item_id = ?
    ''', [itemId]);
  }

  // ==================== Order Items Operations ====================

  /// Save an order item with variant, add-ons, quantity, and total price
  Future<int> insertOrderItem({
    required int eventId,
    required int itemId,
    int? variantId,
    required int quantity,
    required double totalPrice,
    List<Map<String, int>>? addOns,
  }) async {
    final db = await database;
    final orderItemId = await db.insert(
      'event_order_items',
      {
        'event_id': eventId,
        'item_id': itemId,
        'variant_id': variantId,
        'quantity': quantity,
        'total_price': totalPrice,
      },
    );

    if (addOns != null && addOns.isNotEmpty) {
      for (var addOn in addOns) {
        await db.insert(
          'event_order_item_addons',
          {
            'order_item_id': orderItemId,
            'addon_id': addOn['addon_id']!,
            'quantity': addOn['quantity']!,
          },
        );
      }
    }

    return orderItemId;
  }

  /// Get all order items for an event with details
  Future<List<Map<String, dynamic>>> getOrderItemsByEvent(int eventId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        eoi.*,
        i.name as item_name,
        i.price as base_price,
        v.name as variant_name,
        v.price as variant_price
      FROM event_order_items eoi
      INNER JOIN items i ON eoi.item_id = i.id
      LEFT JOIN variants v ON eoi.variant_id = v.id
      WHERE eoi.event_id = ?
      ORDER BY eoi.id DESC
    ''', [eventId]);
  }

  /// Get all add-ons for an order item with details
  Future<List<Map<String, dynamic>>> getOrderItemAddOns(int orderItemId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT eoia.*, ao.name as addon_name, ao.price as addon_price
      FROM event_order_item_addons eoia
      INNER JOIN add_ons ao ON eoia.addon_id = ao.id
      WHERE eoia.order_item_id = ?
    ''', [orderItemId]);
  }

  /// Delete an order item (add-ons are deleted via cascade)
  Future<void> deleteOrderItem(int orderItemId) async {
    final db = await database;
    await db.delete(
      'event_order_items',
      where: 'id = ?',
      whereArgs: [orderItemId],
    );
  }

  // ==================== Payment Settings Operations ====================

  /// Save or update payment settings for an event
  Future<void> saveEventPaymentSettings({
    required int eventId,
    String? paymentMethod,
    String? taxType,
    double? calculatedTax,
    double? calculatedTotal,
    double? discountPercentage,
    bool? isFoodpanda,
  }) async {
    final db = await database;
    final existing = await getEventPaymentSettings(eventId);

    final data = {
      'event_id': eventId,
      'payment_method': paymentMethod ?? existing?['payment_method'],
      'tax_type': taxType ?? existing?['tax_type'],
      'calculated_tax': calculatedTax ?? existing?['calculated_tax'],
      'calculated_total': calculatedTotal ?? existing?['calculated_total'],
      'discount_percentage': discountPercentage ?? existing?['discount_percentage'],
      'is_foodpanda': isFoodpanda != null ? (isFoodpanda ? 1 : 0) : (existing?['is_foodpanda'] ?? 0),
    };

    await db.insert(
      'event_payment_settings',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get payment settings for an event
  Future<Map<String, dynamic>?> getEventPaymentSettings(int eventId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'event_payment_settings',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}

