import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/person.dart';
import '../models/event.dart';
import '../models/item.dart';

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
      version: 4,
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

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}

