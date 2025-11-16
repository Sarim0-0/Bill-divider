import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
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
      version: 12,
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
    if (oldVersion < 10) {
      // Add miscellaneous_amount column to event_payment_settings
      try {
        await db.execute('ALTER TABLE event_payment_settings ADD COLUMN miscellaneous_amount REAL');
      } catch (_) {}
    }
    if (oldVersion < 11) {
      // Create item_person_assignments table to store person assignments for order items
      await db.execute('''
        CREATE TABLE IF NOT EXISTS item_person_assignments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_item_id INTEGER NOT NULL,
          person_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          FOREIGN KEY (order_item_id) REFERENCES event_order_items(id) ON DELETE CASCADE,
          FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE CASCADE,
          UNIQUE(order_item_id, person_id)
        )
      ''');
    }
    if (oldVersion < 12) {
      // Create event_person_paid_status table to store paid status for people in events
      await db.execute('''
        CREATE TABLE IF NOT EXISTS event_person_paid_status (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id INTEGER NOT NULL,
          person_id INTEGER NOT NULL,
          is_paid INTEGER DEFAULT 0,
          FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
          FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE CASCADE,
          UNIQUE(event_id, person_id)
        )
      ''');
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
        miscellaneous_amount REAL,
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
      )
    ''');

    // Create item_person_assignments table to store person assignments for order items
    await db.execute('''
      CREATE TABLE item_person_assignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_item_id INTEGER NOT NULL,
        person_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        FOREIGN KEY (order_item_id) REFERENCES event_order_items(id) ON DELETE CASCADE,
        FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE CASCADE,
        UNIQUE(order_item_id, person_id)
      )
    ''');

    // Create event_person_paid_status table to store paid status for people in events
    await db.execute('''
      CREATE TABLE event_person_paid_status (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        person_id INTEGER NOT NULL,
        is_paid INTEGER DEFAULT 0,
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
        FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE CASCADE,
        UNIQUE(event_id, person_id)
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

  /// Get the most recent event with a given name (excluding a specific event ID)
  Future<Event?> getMostRecentEventByName(String eventName, {int? excludeEventId}) async {
    final db = await database;
    String whereClause = 'name = ?';
    List<dynamic> whereArgs = [eventName];
    
    if (excludeEventId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeEventId);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC, id DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Event.fromMap(maps.first);
  }

  /// Copy all items, variants, and add-ons from one event to another
  Future<void> copyEventItems({
    required int fromEventId,
    required int toEventId,
  }) async {
    final db = await database;
    
    // Get all items from the source event
    final sourceItems = await getItemsByEvent(fromEventId);
    
    // Map to track old item ID -> new item ID
    Map<int, int> itemIdMap = {};
    
    // Copy each item
    for (var sourceItem in sourceItems) {
      // Create new item for the target event
      final newItem = Item(
        eventId: toEventId,
        name: sourceItem.name,
        price: sourceItem.price,
      );
      final newItemId = await insertItem(newItem);
      itemIdMap[sourceItem.id!] = newItemId;
      
      // Copy variants for this item
      final variants = await getVariantsByItem(sourceItem.id!);
      for (var variant in variants) {
        final newVariant = Variant(
          itemId: newItemId,
          name: variant.name,
          price: variant.price,
        );
        await insertVariant(newVariant);
      }
      
      // Copy add-ons for this item
      final addOns = await getAddOnsByItem(sourceItem.id!);
      for (var addOn in addOns) {
        final newAddOn = AddOn(
          itemId: newItemId,
          name: addOn.name,
          price: addOn.price,
        );
        await insertAddOn(newAddOn);
      }
    }
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

  /// Count unpaid events for a person
  /// An event is unpaid if the person has assignments but hasn't paid
  Future<int> getUnpaidEventsCountForPerson(int personId) async {
    final db = await database;
    
    // Get all events where the person has assignments
    final List<Map<String, dynamic>> eventsWithAssignments = await db.rawQuery('''
      SELECT DISTINCT e.id as event_id
      FROM events e
      INNER JOIN event_order_items eoi ON e.id = eoi.event_id
      INNER JOIN item_person_assignments ipa ON eoi.id = ipa.order_item_id
      WHERE ipa.person_id = ?
    ''', [personId]);
    
    if (eventsWithAssignments.isEmpty) {
      return 0;
    }
    
    int unpaidCount = 0;
    
    // Check each event to see if the person has paid
    for (var eventMap in eventsWithAssignments) {
      final eventId = eventMap['event_id'] as int;
      final isPaid = await getPersonPaidStatus(eventId, personId);
      if (!isPaid) {
        unpaidCount++;
      }
    }
    
    return unpaidCount;
  }

  /// Check if a person has paid for a specific event
  /// Returns true if the person has no assignments OR has paid
  Future<bool> hasPersonPaidForEvent(int eventId, int personId) async {
    final db = await database;
    // Check if person has any assignments in this event
    final assignments = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM item_person_assignments ipa
      INNER JOIN event_order_items eoi ON ipa.order_item_id = eoi.id
      WHERE eoi.event_id = ? AND ipa.person_id = ?
    ''', [eventId, personId]);
    
    final hasAssignments = (assignments.first['count'] as int) > 0;
    
    if (!hasAssignments) {
      // Person has no assignments, so they don't owe anything
      return true;
    }
    
    // Person has assignments, check if they've paid
    return await getPersonPaidStatus(eventId, personId);
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
  /// Updates prices for events with the same event name from the given event date onwards
  /// Returns the number of items updated
  Future<int> updateItemPriceForPresentAndFuture(String itemName, String eventName, String eventDate, double newPrice) async {
    final db = await database;
    
    // Update items where:
    // 1. The item name matches
    // 2. The event name matches
    // 3. The event date is >= the given event date
    final result = await db.rawUpdate('''
      UPDATE items
      SET price = ?
      WHERE name = ? 
      AND event_id IN (
        SELECT id FROM events 
        WHERE name = ? AND date >= ?
      )
    ''', [newPrice, itemName, eventName, eventDate]);
    
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
  /// Updates prices for events with the same event name from the given event date onwards
  Future<int> updateVariantPriceForPresentAndFuture(int itemId, String variantName, String eventName, String eventDate, double newPrice) async {
    final db = await database;
    
    // Get the item name first to find matching items
    final item = await getItemById(itemId);
    if (item == null) return 0;
    
    // Update variants where:
    // 1. The variant name matches
    // 2. The item name matches
    // 3. The item belongs to an event with the same name and date >= the given event date
    final result = await db.rawUpdate('''
      UPDATE variants
      SET price = ?
      WHERE name = ? 
      AND item_id IN (
        SELECT i.id FROM items i
        INNER JOIN events e ON i.event_id = e.id
        WHERE i.name = ? AND e.name = ? AND e.date >= ?
      )
    ''', [newPrice, variantName, item.name, eventName, eventDate]);
    
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
  /// Updates prices for events with the same event name from the given event date onwards
  Future<int> updateAddOnPriceForPresentAndFuture(int itemId, String addOnName, String eventName, String eventDate, double newPrice) async {
    final db = await database;
    
    // Get the item name first to find matching items
    final item = await getItemById(itemId);
    if (item == null) return 0;
    
    // Update add-ons where:
    // 1. The add-on name matches
    // 2. The item belongs to an event with the same name and date >= the given event date
    // 3. The item name matches
    final result = await db.rawUpdate('''
      UPDATE add_ons
      SET price = ?
      WHERE name = ? 
      AND item_id IN (
        SELECT i.id FROM items i
        INNER JOIN events e ON i.event_id = e.id
        WHERE i.name = ? AND e.name = ? AND e.date >= ?
      )
    ''', [newPrice, addOnName, item.name, eventName, eventDate]);
    
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
    double? miscellaneousAmount,
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
      'miscellaneous_amount': miscellaneousAmount ?? existing?['miscellaneous_amount'],
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

  // ==================== Item-Person Assignment Operations ====================

  /// Save or update person assignments for an order item
  Future<void> saveItemPersonAssignments({
    required int orderItemId,
    required List<Map<String, dynamic>> assignments, // [{person_id: int, amount: double}]
  }) async {
    final db = await database;
    
    // Delete existing assignments for this order item
    await db.delete(
      'item_person_assignments',
      where: 'order_item_id = ?',
      whereArgs: [orderItemId],
    );
    
    // Insert new assignments
    for (var assignment in assignments) {
      await db.insert(
        'item_person_assignments',
        {
          'order_item_id': orderItemId,
          'person_id': assignment['person_id'],
          'amount': assignment['amount'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Get all person assignments for an order item
  Future<List<Map<String, dynamic>>> getItemPersonAssignments(int orderItemId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT ipa.*, p.name as person_name
      FROM item_person_assignments ipa
      INNER JOIN people p ON ipa.person_id = p.id
      WHERE ipa.order_item_id = ?
      ORDER BY p.name ASC
    ''', [orderItemId]);
  }

  /// Get all assignments for an event (all order items)
  Future<List<Map<String, dynamic>>> getEventPersonAssignments(int eventId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT ipa.*, p.name as person_name, eoi.id as order_item_id
      FROM item_person_assignments ipa
      INNER JOIN people p ON ipa.person_id = p.id
      INNER JOIN event_order_items eoi ON ipa.order_item_id = eoi.id
      WHERE eoi.event_id = ?
      ORDER BY eoi.id, p.name ASC
    ''', [eventId]);
  }

  // ==================== Paid Status Operations ====================

  /// Save or update paid status for a person in an event
  Future<void> savePersonPaidStatus({
    required int eventId,
    required int personId,
    required bool isPaid,
  }) async {
    final db = await database;
    await db.insert(
      'event_person_paid_status',
      {
        'event_id': eventId,
        'person_id': personId,
        'is_paid': isPaid ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get paid status for all people in an event
  Future<Map<int, bool>> getEventPaidStatus(int eventId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'event_person_paid_status',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
    
    Map<int, bool> paidStatus = {};
    for (var map in maps) {
      final personId = map['person_id'] as int;
      final isPaid = (map['is_paid'] as int) == 1;
      paidStatus[personId] = isPaid;
    }
    
    return paidStatus;
  }

  /// Get paid status for a specific person in an event
  Future<bool> getPersonPaidStatus(int eventId, int personId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'event_person_paid_status',
      where: 'event_id = ? AND person_id = ?',
      whereArgs: [eventId, personId],
    );
    
    if (maps.isEmpty) return false;
    return (maps.first['is_paid'] as int) == 1;
  }

  /// Check if all people who owe money in an event have paid
  Future<bool> areAllPeoplePaid(int eventId) async {
    // Get all people who have assignments (owe money) in this event
    final assignments = await getEventPersonAssignments(eventId);
    
    if (assignments.isEmpty) {
      // No one owes money, so consider it as "all paid"
      return true;
    }
    
    // Get unique person IDs who have assignments
    final personIdsWithAssignments = assignments
        .map((a) => a['person_id'] as int)
        .toSet();
    
    if (personIdsWithAssignments.isEmpty) {
      return true;
    }
    
    // Get paid status for all people in the event
    final paidStatus = await getEventPaidStatus(eventId);
    
    // Check if all people with assignments have paid
    for (var personId in personIdsWithAssignments) {
      if (paidStatus[personId] != true) {
        return false; // At least one person hasn't paid
      }
    }
    
    return true; // All people with assignments have paid
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }

  // ==================== Database Reset Operations ====================

  /// Clear all data from all tables (keeps schema intact)
  Future<void> clearAllData() async {
    final db = await database;
    
    // Disable foreign key constraints temporarily
    await db.execute('PRAGMA foreign_keys = OFF');
    
    try {
      // Get list of all tables
      final List<Map<String, dynamic>> tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
      );
      
      // Delete all data from all tables (order matters due to foreign keys)
      final tableNames = [
        'event_person_paid_status',
        'item_person_assignments',
        'event_order_item_addons',
        'event_payment_settings',
        'event_order_items',
        'item_addon_selections',
        'item_variant_selections',
        'add_ons',
        'variants',
        'items',
        'event_people',
        'events',
        'people',
      ];
      
      for (final tableName in tableNames) {
        // Check if table exists before trying to delete
        final tableExists = tables.any((table) => table['name'] == tableName);
        if (tableExists) {
          try {
            // Use DELETE FROM instead of db.delete() to ensure all rows are removed
            await db.execute('DELETE FROM $tableName');
          } catch (e) {
            // Ignore errors if table doesn't exist or is empty
            print('Warning: Could not delete from $tableName: $e');
          }
        }
      }
      
      // Reset auto-increment counters
      try {
        await db.execute('DELETE FROM sqlite_sequence');
      } catch (e) {
        // Ignore if sqlite_sequence doesn't exist
      }
    } finally {
      // Re-enable foreign key constraints
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  /// Delete the entire database file and recreate it
  Future<void> deleteDatabaseFile() async {
    try {
      final db = await database;
      await db.close();
    } catch (e) {
      // Database might not be open
    }
    _database = null;
    
    String path = join(await getDatabasesPath(), 'bill_divider.db');
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    
    // Reinitialize database
    _database = await _initDatabase();
  }
}

