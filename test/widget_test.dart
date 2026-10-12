import 'package:carro_na_mao/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App exibe o slogan na home', (WidgetTester tester) async {
    await tester.pumpWidget(const CarroNaMaoApp());

    expect(find.text('Carro na Mão'), findsOneWidget);
    expect(
      find.text('Gastos, consumo e lembretes em um só lugar.'),
      findsOneWidget,
    );
  });
}
