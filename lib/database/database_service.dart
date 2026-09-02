class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();

  DatabaseService._internal();

  factory DatabaseService() {
    return instance;
  }

  Future<void> initialize() async {
    // Database initialization will be added here.
    //
    // We are keeping this service separate from the screens
    // so the application can later support SQLite locally
    // and a cloud database/backend in production.
  }
}
