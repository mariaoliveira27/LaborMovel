import 'package:flutter_test/flutter_test.dart';
import 'package:listatarefas/main.dart';

void main() {
  testWidgets('Smoke test da inicialização do app de tarefas', (WidgetTester tester) async {
    await tester.pumpWidget(const TarefasApp());
    expect(find.text('Lista de Tarefas'), findsOneWidget);
  });
}
