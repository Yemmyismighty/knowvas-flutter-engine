import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Main database class for Knowvas Flutter client
/// Handles database creation, migrations, and provides access to the database instance
class KnowvasDatabase {
  factory KnowvasDatabase() {
    return _instance;
  }

  KnowvasDatabase._internal();

  static final KnowvasDatabase _instance = KnowvasDatabase._internal();
  static Database? _database;
  final Logger _logger = Logger();

  /// Database version - increment this when schema changes
  static const int _databaseVersion = 1;
  static const String _databaseName = 'knowvas.db';

  /// Get database instance, creating it if necessary
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    _logger.i('Initializing database at: $path');

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: onDatabaseDowngradeDelete,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    _logger.i('Creating database tables (version $version)');

    // Users table (cached user data)
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        username TEXT NOT NULL,
        first_name TEXT,
        last_name TEXT,
        profile_picture TEXT,
        preferred_currency TEXT,
        last_synced INTEGER
      )
    ''');

    // Library items table
    await db.execute('''
      CREATE TABLE library_items (
        content_id INTEGER PRIMARY KEY,
        user_id TEXT NOT NULL,
        content_data TEXT NOT NULL,
        purchase_date INTEGER,
        reading_progress REAL DEFAULT 0.0,
        current_page INTEGER,
        last_opened INTEGER,
        is_downloaded INTEGER DEFAULT 0,
        is_favorite INTEGER DEFAULT 0,
        last_synced INTEGER,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Downloaded files table
    await db.execute('''
      CREATE TABLE downloaded_files (
        content_id INTEGER PRIMARY KEY,
        user_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        encrypted_path TEXT NOT NULL,
        file_size INTEGER,
        download_date INTEGER,
        quality TEXT,
        hash TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Bookmarks table
    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content_id INTEGER NOT NULL,
        user_id TEXT NOT NULL,
        page_number INTEGER NOT NULL,
        location TEXT,
        created_at INTEGER NOT NULL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Highlights table
    await db.execute('''
      CREATE TABLE highlights (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content_id INTEGER NOT NULL,
        user_id TEXT NOT NULL,
        page_number INTEGER NOT NULL,
        start_position INTEGER NOT NULL,
        end_position INTEGER NOT NULL,
        highlighted_text TEXT NOT NULL,
        color TEXT DEFAULT '#FFFF00',
        created_at INTEGER NOT NULL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Notes table
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content_id INTEGER NOT NULL,
        user_id TEXT NOT NULL,
        page_number INTEGER NOT NULL,
        position INTEGER,
        note_text TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Engagement events queue table
    await db.execute('''
      CREATE TABLE engagement_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content_id INTEGER NOT NULL,
        user_id TEXT NOT NULL,
        session_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        payload TEXT,
        timestamp INTEGER NOT NULL,
        uploaded INTEGER DEFAULT 0
      )
    ''');

    // Reading sessions table
    await db.execute('''
      CREATE TABLE reading_sessions (
        session_id TEXT PRIMARY KEY,
        content_id INTEGER NOT NULL,
        user_id TEXT NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        start_page INTEGER,
        end_page INTEGER,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Reader preferences table (per content)
    await db.execute('''
      CREATE TABLE reader_preferences (
        content_id INTEGER PRIMARY KEY,
        user_id TEXT NOT NULL,
        font_size INTEGER DEFAULT 16,
        font_family TEXT DEFAULT 'serif',
        theme TEXT DEFAULT 'light',
        line_height REAL DEFAULT 1.5,
        margin REAL DEFAULT 1.0,
        layout TEXT DEFAULT 'single',
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Create indexes for better query performance
    await _createIndexes(db);

    _logger.i('Database tables created successfully');
  }

  /// Create indexes for frequently queried columns
  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_library_items_user_id ON library_items(user_id)');
    await db.execute('CREATE INDEX idx_downloaded_files_user_id ON downloaded_files(user_id)');
    await db.execute('CREATE INDEX idx_bookmarks_content_id ON bookmarks(content_id)');
    await db.execute('CREATE INDEX idx_bookmarks_user_id ON bookmarks(user_id)');
    await db.execute('CREATE INDEX idx_highlights_content_id ON highlights(content_id)');
    await db.execute('CREATE INDEX idx_highlights_user_id ON highlights(user_id)');
    await db.execute('CREATE INDEX idx_notes_content_id ON notes(content_id)');
    await db.execute('CREATE INDEX idx_notes_user_id ON notes(user_id)');
    await db.execute('CREATE INDEX idx_engagement_queue_uploaded ON engagement_queue(uploaded)');
    await db.execute('CREATE INDEX idx_reading_sessions_user_id ON reading_sessions(user_id)');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.i('Upgrading database from version $oldVersion to $newVersion');

    // Add migration logic here when schema changes
    // Example:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE users ADD COLUMN new_column TEXT');
    // }
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    _logger.i('Database closed');
  }

  /// Delete the database (useful for testing or logout)
  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
    _logger.i('Database deleted');
  }
}
