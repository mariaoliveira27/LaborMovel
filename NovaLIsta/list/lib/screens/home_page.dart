import 'package:flutter/material.dart';
import '../models/tarefa.dart';
import '../services/mysql_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MySqlService _dbService = MySqlService();
  List<Tarefa> _tarefas = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarTarefas();
  }

  Future<void> _carregarTarefas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Tenta inicializar o banco e a tabela se ainda não existirem
      await _dbService.inicializarBanco();
      final tarefas = await _dbService.listarTarefas();
      setState(() {
        _tarefas = tarefas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _adicionarTarefa(String titulo) async {
    if (titulo.trim().isEmpty) return;

    try {
      await _dbService.inserirTarefa(titulo.trim());
      await _carregarTarefas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atividade incluída com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar no MySQL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _alternarConclusao(Tarefa tarefa, bool? novoStatus) async {
    if (tarefa.id == null || novoStatus == null) return;

    // Atualização otimista na tela
    final index = _tarefas.indexWhere((t) => t.id == tarefa.id);
    if (index != -1) {
      setState(() {
        _tarefas[index] = tarefa.copyWith(concluida: novoStatus);
      });
    }

    try {
      await _dbService.atualizarStatus(tarefa.id!, novoStatus);
    } catch (e) {
      // Reverte em caso de erro
      if (index != -1) {
        setState(() {
          _tarefas[index] = tarefa;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar status no MySQL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removerTarefa(Tarefa tarefa) async {
    if (tarefa.id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover Atividade'),
        content: Text('Deseja realmente remover "${tarefa.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _dbService.removerTarefa(tarefa.id!);
      await _carregarTarefas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atividade removida com sucesso!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover no MySQL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _exibirDialogoAdicionar() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Incluir Nova Atividade'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome da atividade',
            hintText: 'Ex: Estudar para prova de Laboratório Móvel',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (val) {
            Navigator.of(ctx).pop();
            _adicionarTarefa(val);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Incluir'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _adicionarTarefa(controller.text);
            },
          ),
        ],
      ),
    );
  }

  void _exibirConfiguracoesBanco() {
    final hostCtrl = TextEditingController(text: _dbService.host);
    final portCtrl = TextEditingController(text: _dbService.port.toString());
    final userCtrl = TextEditingController(text: _dbService.user);
    final passCtrl = TextEditingController(text: _dbService.password);
    final dbCtrl = TextEditingController(text: _dbService.db);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.storage, color: Colors.blue),
            SizedBox(width: 8),
            Text('Configuração MySQL'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Dica: No emulador Android, use 10.0.2.2 para acessar o MySQL do seu computador. Em aparelho físico, use o IP da sua máquina na rede (ex: 192.168.0.x).',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hostCtrl,
                decoration: const InputDecoration(
                  labelText: 'Host (IP ou localhost)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: portCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Porta',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: userCtrl,
                decoration: const InputDecoration(
                  labelText: 'Usuário',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dbCtrl,
                decoration: const InputDecoration(
                  labelText: 'Banco de Dados',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _dbService.updateConfig(
                newHost: hostCtrl.text.trim(),
                newPort: int.tryParse(portCtrl.text.trim()) ?? 3306,
                newUser: userCtrl.text.trim(),
                newPassword: passCtrl.text,
                newDb: dbCtrl.text.trim(),
              );
              Navigator.of(ctx).pop();
              _carregarTarefas();
            },
            child: const Text('Salvar e Conectar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Tarefas'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar Lista',
            onPressed: _carregarTarefas,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurações do MySQL',
            onPressed: _exibirConfiguracoesBanco,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exibirDialogoAdicionar,
        tooltip: 'Incluir Atividade',
        icon: const Icon(Icons.add),
        label: const Text('Incluir Atividade'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Conectando ao MySQL e carregando tarefas...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Falha ao conectar no MySQL',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _carregarTarefas,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar Novamente'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _exibirConfiguracoesBanco,
                    icon: const Icon(Icons.settings),
                    label: const Text('Configurar Conexão'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_tarefas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.checklist, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Nenhuma atividade cadastrada!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Clique no botão abaixo para incluir sua primeira tarefa.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _exibirDialogoAdicionar,
                icon: const Icon(Icons.add),
                label: const Text('Incluir Atividade'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _tarefas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final tarefa = _tarefas[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            // À esquerda da atividade: checkbox para dizer se ela foi concluída ou não
            leading: Checkbox(
              value: tarefa.concluida,
              activeColor: Colors.green,
              onChanged: (bool? valor) => _alternarConclusao(tarefa, valor),
            ),
            // Título / Nome da atividade
            title: Text(
              tarefa.titulo,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                decoration: tarefa.concluida ? TextDecoration.lineThrough : null,
                color: tarefa.concluida ? Colors.grey : Colors.black87,
              ),
            ),
            // À sua direita: botão para remover
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Remover atividade',
              onPressed: () => _removerTarefa(tarefa),
            ),
          ),
        );
      },
    );
  }
}
