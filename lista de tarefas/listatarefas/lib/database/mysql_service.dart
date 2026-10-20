import 'package:mysql_client/mysql_client.dart';
import '../models/tarefa.dart';
import 'db_config.dart';

class MySqlService {
  static final MySqlService _instance = MySqlService._internal();
  factory MySqlService() => _instance;
  MySqlService._internal();

  /// Cria uma conexão com o MySQL usando as configurações persistidas.
  /// Caso o banco de dados não exista, tenta criá-lo automaticamente.
  Future<MySQLConnection> _connect() async {
    final config = await DbConfig.getConfig();
    final host = config['host'] as String;
    final port = config['port'] as int;
    final user = config['user'] as String;
    final password = config['password'] as String;
    final database = config['database'] as String;

    try {
      // Tenta conectar diretamente ao banco especificado
      final conn = await MySQLConnection.createConnection(
        host: host,
        port: port,
        userName: user,
        password: password,
        databaseName: database,
        secure: false,
      );
      await conn.connect();
      await _criarTabelaSeNaoExistir(conn);
      return conn;
    } catch (e) {
      // Se falhou ao conectar porque o banco não existe, conecta sem databaseName e cria o banco
      try {
        final connSemDb = await MySQLConnection.createConnection(
          host: host,
          port: port,
          userName: user,
          password: password,
          secure: false,
        );
        await connSemDb.connect();
        await connSemDb.execute("CREATE DATABASE IF NOT EXISTS `$database`;");
        await connSemDb.execute("USE `$database`;");
        await _criarTabelaSeNaoExistir(connSemDb);
        return connSemDb;
      } catch (_) {
        // Se ainda assim falhar, relança o erro original com contexto
        rethrow;
      }
    }
  }

  Future<void> _criarTabelaSeNaoExistir(MySQLConnection conn) async {
    const sql = '''
      CREATE TABLE IF NOT EXISTS tarefas (
        id INT AUTO_INCREMENT PRIMARY KEY,
        titulo VARCHAR(255) NOT NULL,
        concluida TINYINT(1) NOT NULL DEFAULT 0
      );
    ''';
    await conn.execute(sql);
  }

  /// Executa uma ação com a conexão garantindo o fechamento posterior.
  Future<T> _withConnection<T>(
      Future<T> Function(MySQLConnection conn) action) async {
    final conn = await _connect();
    try {
      return await action(conn);
    } finally {
      await conn.close();
    }
  }

  /// Testa a conexão com os parâmetros passados.
  Future<bool> testarConexao({
    required String host,
    required int port,
    required String user,
    required String password,
    required String database,
  }) async {
    MySQLConnection? conn;
    try {
      conn = await MySQLConnection.createConnection(
        host: host,
        port: port,
        userName: user,
        password: password,
        databaseName: database,
        secure: false,
      );
      await conn.connect();
      return true;
    } catch (_) {
      // Tenta sem databaseName caso o banco ainda não exista
      try {
        conn = await MySQLConnection.createConnection(
          host: host,
          port: port,
          userName: user,
          password: password,
          secure: false,
        );
        await conn.connect();
        return true;
      } catch (e) {
        return false;
      }
    } finally {
      await conn?.close();
    }
  }

  /// Retorna todas as tarefas cadastradas.
  Future<List<Tarefa>> getTarefas() async {
    return await _withConnection((conn) async {
      final result = await conn.execute(
        "SELECT id, titulo, concluida FROM tarefas ORDER BY id DESC;",
      );

      final List<Tarefa> tarefas = [];
      for (final row in result.rows) {
        final map = row.assoc();
        tarefas.add(Tarefa(
          id: int.tryParse(map['id'] ?? ''),
          titulo: map['titulo'] ?? '',
          concluida: map['concluida'] == '1' ||
              map['concluida']?.toLowerCase() == 'true',
        ));
      }
      return tarefas;
    });
  }

  /// Inclui uma nova tarefa.
  Future<void> adicionarTarefa(String titulo) async {
    if (titulo.trim().isEmpty) return;
    await _withConnection((conn) async {
      await conn.execute(
        "INSERT INTO tarefas (titulo, concluida) VALUES (:titulo, :concluida);",
        {
          "titulo": titulo.trim(),
          "concluida": 0,
        },
      );
    });
  }

  /// Atualiza o status (concluída ou não) da tarefa.
  Future<void> atualizarStatus(int id, bool concluida) async {
    await _withConnection((conn) async {
      await conn.execute(
        "UPDATE tarefas SET concluida = :concluida WHERE id = :id;",
        {
          "concluida": concluida ? 1 : 0,
          "id": id,
        },
      );
    });
  }

  /// Remove uma tarefa pelo id.
  Future<void> removerTarefa(int id) async {
    await _withConnection((conn) async {
      await conn.execute(
        "DELETE FROM tarefas WHERE id = :id;",
        {"id": id},
      );
    });
  }
}

