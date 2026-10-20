class Tarefa {
  final int? id;
  final String titulo;
  final bool concluida;

  Tarefa({
    this.id,
    required this.titulo,
    this.concluida = false,
  });

  Tarefa copyWith({
    int? id,
    String? titulo,
    bool? concluida,
  }) {
    return Tarefa(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      concluida: concluida ?? this.concluida,
    );
  }

  factory Tarefa.fromMap(Map<String, dynamic> map) {
    return Tarefa(
      id: map['id'] is int
          ? map['id']
          : int.tryParse(map['id']?.toString() ?? ''),
      titulo: map['titulo']?.toString() ?? '',
      concluida: map['concluida'] == 1 ||
          map['concluida'] == true ||
          map['concluida']?.toString() == '1' ||
          map['concluida']?.toString().toLowerCase() == 'true',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'concluida': concluida ? 1 : 0,
    };
  }
}

