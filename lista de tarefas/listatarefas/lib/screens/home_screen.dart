import 'package:flutter/material.dart';
import '../database/mysql_service.dart';
import '../models/tarefa.dart';
import 'config_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MySqlService _dbService = MySqlService();
  List<Tarefa> _tarefas = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarTarefas();
  }

  Future<void> _carregarTarefas() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final lista = await _dbService.getTarefas();
      setState(() {
        _tarefas = lista;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _carregando = false;
        _erro = e.toString();
      });
    }
  }

  Future<void> _mostrarDialogoAdicionarTarefa() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nova Tarefa'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descrição da tarefa',
                hintText: 'Ex: Estudar para prova de LaborMovel',
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Informe o nome da tarefa';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final titulo = controller.text.trim();
                  Navigator.of(context).pop();
                  await _adicionarTarefa(titulo);
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _adicionarTarefa(String titulo) async {
    try {
      await _dbService.adicionarTarefa(titulo);
      _mostrarMensagem('Tarefa adicionada com sucesso!');
      await _carregarTarefas();
    } catch (e) {
      _mostrarMensagem('Erro ao adicionar tarefa: $e', isErro: true);
    }
  }

  Future<void> _alternarStatus(Tarefa tarefa, bool? novoStatus) async {
    if (tarefa.id == null || novoStatus == null) return;

    // Atualização otimista na tela para responsividade imediata
    setState(() {
      final index = _tarefas.indexWhere((t) => t.id == tarefa.id);
      if (index != -1) {
        _tarefas[index] = tarefa.copyWith(concluida: novoStatus);
      }
    });

    try {
      await _dbService.atualizarStatus(tarefa.id!, novoStatus);
    } catch (e) {
      _mostrarMensagem('Erro ao atualizar status: $e', isErro: true);
      // Em caso de erro, recarrega do banco para restaurar estado real
      await _carregarTarefas();
    }
  }

  Future<void> _removerTarefa(Tarefa tarefa) async {
    if (tarefa.id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover Tarefa'),
        content: Text('Deseja remover "${tarefa.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _dbService.removerTarefa(tarefa.id!);
      _mostrarMensagem('Tarefa removida com sucesso!');
      await _carregarTarefas();
    } catch (e) {
      _mostrarMensagem('Erro ao remover tarefa: $e', isErro: true);
    }
  }

  void _mostrarMensagem(String msg, {bool isErro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isErro ? Colors.red.shade700 : Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Tarefas'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurações do MySQL',
            onPressed: () async {
              final alterou = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (context) => const ConfigScreen()),
              );
              if (alterou == true) {
                _carregarTarefas();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar',
            onPressed: _carregarTarefas,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoAdicionarTarefa,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova Tarefa'),
        tooltip: 'Incluir Tarefa',
      ),
    );
  }

  Widget _buildBody() {
    if (_carregando) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.indigo),
            SizedBox(height: 16),
            Text('Carregando tarefas do MySQL...'),
          ],
        ),
      );
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Falha ao conectar com o MySQL',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Verifique se o MySQL está rodando e se o IP do servidor está correto.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _erro!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _carregarTarefas,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar Novamente'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final alterou = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (context) => const ConfigScreen(),
                        ),
                      );
                      if (alterou == true) {
                        _carregarTarefas();
                      }
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Configurações'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_tarefas.isEmpty) {
      return RefreshIndicator(
        onRefresh: _carregarTarefas,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.check_circle_outline, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma tarefa pendente!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Toque no botão "+" abaixo para cadastrar uma atividade.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarTarefas,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        itemCount: _tarefas.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final tarefa = _tarefas[index];
          return Card(
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              // Checkbox à esquerda
              leading: Checkbox(
                value: tarefa.concluida,
                activeColor: Colors.green,
                onChanged: (bool? valor) {
                  _alternarStatus(tarefa, valor);
                },
              ),
              // Título no centro
              title: Text(
                tarefa.titulo,
                style: TextStyle(
                  fontSize: 16,
                  decoration: tarefa.concluida
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: tarefa.concluida ? Colors.grey : Colors.black87,
                ),
              ),
              // Botão para remover à direita
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Remover tarefa',
                onPressed: () {
                  _removerTarefa(tarefa);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
