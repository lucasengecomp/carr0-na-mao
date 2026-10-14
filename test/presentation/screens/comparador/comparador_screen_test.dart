import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/data/providers.dart';
import 'package:carro_na_mao/presentation/screens/comparador/comparador_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _advance(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _teardownUi(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

VeiculosCompanion _novoVeiculo({String placa = 'ABC1D23'}) =>
    VeiculosCompanion.insert(
      placa: placa,
      marca: 'Fiat',
      modelo: 'Uno',
      ano: 2020,
      tipo: TipoVeiculo.carro,
      combustivel: TipoCombustivelVeiculo.flex,
      kmInicial: 10000,
    );

AbastecimentosCompanion _abast({
  required DateTime data,
  required int km,
  double litros = 40,
  TipoCombustivelAbastecimento combustivel =
      TipoCombustivelAbastecimento.gasolina,
  bool tanqueCheio = true,
  String placa = 'ABC1D23',
}) => AbastecimentosCompanion.insert(
  veiculoPlaca: placa,
  data: data,
  km: km,
  tipoCombustivel: combustivel,
  precoLitro: 6,
  valorTotal: litros * 6,
  litros: litros,
  tanqueCheio: Value(tanqueCheio),
);

Future<void> _pumpScreen(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: ComparadorScreen()),
    ),
  );
  await _advance(tester);
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('mostra estado vazio quando não há veículos', (tester) async {
    await _pumpScreen(tester, db);
    expect(find.textContaining('Cadastre um veículo'), findsOneWidget);
    await _teardownUi(tester);
  });

  testWidgets('usa regra 70% quando o veículo não tem histórico', (
    tester,
  ) async {
    await db.veiculosDao.insertVeiculo(_novoVeiculo());

    await _pumpScreen(tester, db);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Preço do álcool (R\$/L)'),
      '3,90',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Preço da gasolina (R\$/L)'),
      '6,00',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Comparar'));
    await _advance(tester);

    expect(find.text('Álcool compensa'), findsOneWidget);
    expect(find.text('Regra dos 70%'), findsOneWidget);
    // Sem histórico, não aparecem as linhas de custo/km.
    expect(find.textContaining('/km'), findsNothing);
    await _teardownUi(tester);
  });

  testWidgets('usa histórico quando o veículo tem dados suficientes', (
    tester,
  ) async {
    await db.veiculosDao.insertVeiculo(_novoVeiculo());
    // Gasolina 12 km/l, álcool 8 km/l.
    for (final c in [
      _abast(data: DateTime(2026, 6, 1), km: 10000, litros: 40),
      _abast(data: DateTime(2026, 7, 1), km: 10600, litros: 50),
      _abast(
        data: DateTime(2026, 6, 15),
        km: 10200,
        litros: 25,
        combustivel: TipoCombustivelAbastecimento.alcool,
      ),
      _abast(
        data: DateTime(2026, 7, 15),
        km: 10400,
        litros: 25,
        combustivel: TipoCombustivelAbastecimento.alcool,
      ),
    ]) {
      await db.abastecimentosDao.insertAbastecimento(c);
    }

    await _pumpScreen(tester, db);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Preço do álcool (R\$/L)'),
      '3,80',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Preço da gasolina (R\$/L)'),
      '6,00',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Comparar'));
    await _advance(tester);

    expect(find.text('Baseado no histórico do veículo'), findsOneWidget);
    expect(find.text('Álcool compensa'), findsOneWidget);
    // Confere a linha de custo/km de cada combustível.
    expect(find.textContaining('/km'), findsNWidgets(2));
    await _teardownUi(tester);
  });
}
