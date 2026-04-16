# Knowvas Database

This directory contains the SQLite database implementation for the Knowvas Flutter client.

## Files

- `database.dart` - Main database class that handles database creation, migrations, and provides access to the database instance
- `database_helper.dart` - Database helper class providing CRUD operations for all tables

## Database Schema

The database includes the following tables:

1. **users** - Cached user data
2. **library_items** - User's library content with reading progress
3. **downloaded_files** - Information about downloaded and encrypted files
4. **bookmarks** - User bookmarks for content
5. **highlights** - User highlights with text and color
6. **notes** - User notes attached to content pages
7. **engagement_queue** - Queue of engagement events to be uploaded
8. **reading_sessions** - Reading session tracking
9. **reader_preferences** - Per-content reader preferences (font, theme, etc.)

## Usage

### Initialize Database

```dart
final database = KnowvasDatabase();
final db = await database.database;
```

### Using Database Helper

```dart
final dbHelper = DatabaseHelper();

// Insert a user
await dbHelper.upsertUser({
  'id': 'user123',
  'email': 'user@example.com',
  'username': 'johndoe',
  'first_name': 'John',
  'last_name': 'Doe',
  'preferred_currency': 'USD',
  'last_synced': DateTime.now().millisecondsSinceEpoch,
});

// Get library items
final libraryItems = await dbHelper.getLibraryItems('user123');

// Update reading progress
await dbHelper.updateReadingProgress('user123', 1, 0.45, 120);

// Insert a bookmark
await dbHelper.insertBookmark({
  'content_id': 1,
  'user_id': 'user123',
  'page_number': 42,
  'created_at': DateTime.now().millisecondsSinceEpoch,
  'synced': 0,
});

// Get unsynced engagement events
final events = await dbHelper.getUnuploadedEngagementEvents('user123');

// Clear user data on logout
await dbHelper.clearUserData('user123');
```

## Database Migrations

When the database schema needs to be updated:

1. Increment `_databaseVersion` in `database.dart`
2. Add migration logic in the `_onUpgrade` method

Example:
```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('ALTER TABLE users ADD COLUMN bio TEXT');
  }
  if (oldVersion < 3) {
    await db.execute('CREATE TABLE new_table (id INTEGER PRIMARY KEY)');
  }
}
```

## Testing

The database can be deleted for testing purposes:

```dart
final database = KnowvasDatabase();
await database.deleteDatabase();
```

## Performance Considerations

- Indexes are created on frequently queried columns for better performance
- Batch operations use transactions for atomicity
- Foreign key constraints ensure data integrity
- The database uses a singleton pattern to prevent multiple instances

## Requirements Covered

This implementation satisfies the following requirements:

- **4.1, 4.2** - Library management and organization
- **8.1, 8.2** - Offline download and encrypted storage tracking
- **9.7** - Engagement tracking and analytics queue
