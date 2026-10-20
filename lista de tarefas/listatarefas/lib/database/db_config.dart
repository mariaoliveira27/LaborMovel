import 'package:shared_preferences/shared_preferences.dart';

class DbConfig {
  static const String _keyHost = 'db_host';
  static const String _keyPort = 'db_port';
  static const String _keyUser = 'db_user';
  static const String _keyPassword = 'db_password';
  static const String _keyDatabase = 'db_name';

  // Valores padrão:
  // 10.0.2.2 é o alias do emulador Android para o localhost da máquina host
  static const String defaultHost = '10.0.2.2';
  static const int defaultPort = 3306;
  static const String defaultUser = 'root';
  static const String defaultPassword = '';
  static const String defaultDatabase = 'lista_tarefas';

  static Future<Map<String, dynamic>> getConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'host': prefs.getString(_keyHost) ?? defaultHost,
        'port': prefs.getInt(_keyPort) ?? defaultPort,
        'user': prefs.getString(_keyUser) ?? defaultUser,
        'password': prefs.getString(_keyPassword) ?? defaultPassword,
        'database': prefs.getString(_keyDatabase) ?? defaultDatabase,
      };
    } catch (_) {
      return {
        'host': defaultHost,
        'port': defaultPort,
        'user': defaultUser,
        'password': defaultPassword,
        'database': defaultDatabase,
      };
    }
  }

  static Future<void> saveConfig({
    required String host,
    required int port,
    required String user,
    required String password,
    required String database,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHost, host.trim());
    await prefs.setInt(_keyPort, port);
    await prefs.setString(_keyUser, user.trim());
    await prefs.setString(_keyPassword, password);
    await prefs.setString(_keyDatabase, database.trim());
  }
}

