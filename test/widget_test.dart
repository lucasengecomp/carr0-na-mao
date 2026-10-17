import 'package:carro_na_mao/presentation/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home exibe o título e CTA de cadastro quando sem veículo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: CarroNaMaoApp()));
    await tester.pumpAndSettle();

    // Título da AppBar
    expect(find.text('Carro na Mão'), findsOneWidget);
    // Dashboard sem veículo exibe CTA para cadastrar
    expect(find.text('Nenhum veículo cadastrado.'), findsOneWidget);
  });
}
