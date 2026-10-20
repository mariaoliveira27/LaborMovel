import 'package:mysql1/mysql1.dart';
import '../models/tarefa.dart';

class MySqlService {
  static final MySqlService _instance = MySqlService._internal();
  factory MySqlService() => _instance;
  MySqlService._internal();

  // Configurações de conexão padrão
  // NOTA: No emulador Android, '10.0.2.2' aponta para o localhost do computador.
  // Em dispositivo físico via USB/Wi-Fi, use o endereço IP da sua máquina na rede local (ex: 192.168.x.x).
  String host = '10.0.2.2';
  int port = 3306;
  String user = 'root';
  String password = '';
  String db = 'tarefas_db';

  void updateConfig({
    required String newHost,
    required int newPort,
    required String newUser,
    required String newPassword,
    required String newDb,
  }) {
    host = newHost;
    port = newPort;
    user = newUser;
    password = newPassword;
    db = newDb;
  }

  ConnectionSettings _getSettings({bool includeDb = true}) {
    return ConnectionSettings(
      host: host,
      port: port,
      user: user,
      password: password.isEmpty ? null : password,
      db: includeDb ? db : null,
      timeout: const Duration(seconds: 7),
    );
  }

  /// Inicializa o banco de dados e a tabela caso ainda não existam.
  Future<void> inicializarBanco() async {
    // 1. Conecta sem especificar banco para poder criá-lo
    MySqlConnection? conn;
    try {
      conn = await MySqlConnection.connect(_getSettings(includeDb: false));
      await conn.query('CREATE DATABASE IF NOT EXISTS `$db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;');
    } finally {
      await conn?.close();
    }

    // 2. Conecta no banco especificado e cria a tabela
    MySqlConnection? connDb;
    try {
      connDb = await MySqlConnection.connect(_getSettings(includeDb: true));
      await connDb.query('''
        CREATE TABLE IF NOT EXISTS `tarefas` (
          `id` INT AUTO_INCREMENT PRIMARY KEY,
          `titulo` VARCHAR(255) NOT NULL,
          `concluida` TINYINT(1) NOT NULL DEFAULT 0
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
      ''');
    } finally {
      await connDb?.close();
    }
  }

  /// Busca todas as tarefas ordenadas por id
  Future<List<Tarefa>> listarTarefas() async {
    MySqlConnection? conn;
    try {
      conn = await MySqlConnection.connect(_getSettings(includeDb: true));
      final results = await conn.query(
        'SELECT id, titulo, concluida FROM tarefas ORDER BY id DESC;',
      );

      final List<Tarefa> lista = [];
      for (final row in results) {
        lista.add(Tarefa(
          id: row['id'] as int?,
          titulo: row['titulo'].toString(),
          concluida: row['concluida'] == 1 || row['concluida'] == true,
        ));
      }
      return lista;
    } finally {
      await conn?.close();
    }
  }

  /// Insere uma nova tarefa no banco de dados
  Future<int?> inserirTarefa(String titulo) async {
    MySqlConnection? conn;
    try {
      conn = await MySqlConnection.connect(_getSettings(includeDb: true));
      final result = await conn.query(
        'INSERT INTO tarefas (titulo, concluida) VALUES (?, 0);',
        [titulo],
      );
      return result.insertId;
    } finally {
      await conn?.close();
    }
  }

  /// Atualiza o status de conclusão da tarefa
  Future<void> atualizarStatus(int id, bool concluida) async {
    MySqlConnection? conn;
    try {
      conn = await MySqlConnection.connect(_getSettings(includeDb: true));
      await conn.query(
        'UPDATE tarefas SET concluida = ? WHERE id = ?;',
        [concluida ? 1 : 0, id],
      );
    } finally {
      await conn?.close();
    }
  }

  /// Remove uma tarefa pelo id
  Future<void> removerTarefa(int id) async {
    MySqlConnection? conn;
    try {
      conn = await MySqlConnection.connect(_getSettings(includeDb: true));
      await conn.query(
        'DELETE FROM tarefas WHERE id = ?;',
        [id],
      );
    } finally {
      await conn?.close();
    }
  }
}
