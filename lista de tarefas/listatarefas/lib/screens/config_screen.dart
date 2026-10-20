import 'package:flutter/material.dart';
import '../database/db_config.dart';
import '../database/mysql_service.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _databaseController = TextEditingController();

  bool _carregando = true;
  bool _testando = false;
  String? _statusMensagem;
  bool? _statusSucesso;

  @override
  void initState() {
    super.initState();
    _carregarConfiguracoes();
  }

  Future<void> _carregarConfiguracoes() async {
    final config = await DbConfig.getConfig();
    setState(() {
      _hostController.text = config['host'].toString();
      _portController.text = config['port'].toString();
      _userController.text = config['user'].toString();
      _passwordController.text = config['password'].toString();
      _databaseController.text = config['database'].toString();
      _carregando = false;
    });
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _databaseController.dispose();
    super.dispose();
  }

  Future<void> _testarConexao() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _testando = true;
      _statusMensagem = null;
      _statusSucesso = null;
    });

    final port = int.tryParse(_portController.text.trim()) ?? 3306;
    final sucesso = await MySqlService().testarConexao(
      host: _hostController.text.trim(),
      port: port,
      user: _userController.text.trim(),
      password: _passwordController.text,
      database: _databaseController.text.trim(),
    );

    setState(() {
      _testando = false;
      _statusSucesso = sucesso;
      _statusMensagem = sucesso
          ? 'Conexão realizada com sucesso!'
          : 'Falha ao conectar. Verifique IP, porta, credenciais e se o MySQL está rodando.';
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final port = int.tryParse(_portController.text.trim()) ?? 3306;
    await DbConfig.saveConfig(
      host: _hostController.text.trim(),
      port: port,
      user: _userController.text.trim(),
      password: _passwordController.text,
      database: _databaseController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configurações salvas com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações MySQL'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: Colors.blue.shade50,
                      child: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dicas de Host/IP:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '• Emulador Android: use 10.0.2.2\n'
                              '• Celular físico: use o IP local do seu PC (ex: 192.168.1.X)\n'
                              '• Windows/Desktop: use 127.0.0.1 ou localhost',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _hostController,
                      decoration: const InputDecoration(
                        labelText: 'Host / IP',
                        hintText: '10.0.2.2',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.computer),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Informe o host/IP'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: 'Porta',
                        hintText: '3306',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value == null || int.tryParse(value.trim()) == null
                              ? 'Informe uma porta válida'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _userController,
                      decoration: const InputDecoration(
                        labelText: 'Usuário',
                        hintText: 'root',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Informe o usuário'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        hintText: '(deixe em branco se não houver)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _databaseController,
                      decoration: const InputDecoration(
                        labelText: 'Banco de Dados',
                        hintText: 'lista_tarefas',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.storage),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Informe o nome do banco'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    if (_statusMensagem != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: (_statusSucesso ?? false)
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (_statusSucesso ?? false)
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              (_statusSucesso ?? false)
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: (_statusSucesso ?? false)
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _statusMensagem!,
                                style: TextStyle(
                                  color: (_statusSucesso ?? false)
                                      ? Colors.green.shade900
                                      : Colors.red.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: _testando ? null : _testarConexao,
                      icon: _testando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.network_check),
                      label: Text(_testando ? 'Testando...' : 'Testar Conexão'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _salvar,
                      icon: const Icon(Icons.save),
                      label: const Text(
                        'Salvar Configurações',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
