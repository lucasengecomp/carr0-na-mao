import 'package:carro_na_mao/presentation/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home exibe o slogan e o título', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CarroNaMaoApp()));
    await tester.pumpAndSettle();

    expect(find.text('Carro na Mão'), findsOneWidget);
    expect(
      find.text('Gastos, consumo e lembretes em um só lugar.'),
      findsOneWidget,
    );
  });
}
