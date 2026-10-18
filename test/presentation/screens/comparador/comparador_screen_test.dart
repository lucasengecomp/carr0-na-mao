import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/data/providers.dart';
import 'package:carro_na_mao/presentation/screens/comparador/comparador_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/l10n_delegates.dart';

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
      child: const MaterialApp(
        locale: localeDefault,
        localizationsDelegates: l10nDelegates,
        supportedLocales: supportedLocales,
        home: ComparadorScreen(),
      ),
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
    // Sem histórico, exibe custo/km estimado com valores padrão (7 e 10 km/L).
    expect(find.textContaining('/km'), findsNWidgets(2));
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
    // 'Álcool compensa' aparece apenas no título do card.
    expect(find.text('Álcool compensa'), findsOneWidget);
    // Labels das linhas de custo/km são os nomes dos combustíveis.
    expect(find.text('Álcool'), findsOneWidget);
    expect(find.text('Gasolina'), findsOneWidget);
    // Confere a linha de custo/km de cada combustível.
    expect(find.textContaining('/km'), findsNWidgets(2));
    await _teardownUi(tester);
  });

  // ─── Validação de formulário ───────────────────────────────────────────────

  testWidgets('campo álcool vazio exibe mensagem Obrigatório', (tester) async {
    await db.veiculosDao.insertVeiculo(_novoVeiculo());
    await _pumpScreen(tester, db);

    // Deixa campo álcool vazio; preenche gasolina.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Preço da gasolina (R\$/L)'),
      '6,00',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Comparar'));
    await _advance(tester);

    expect(find.text('Obrigatório'), findsOneWidget);
    // Resultado não deve aparecer.
    expect(find.textContaining('/km'), findsNothing);
    await _teardownUi(tester);
  });

  testWidgets('campo gasolina vazio exibe mensagem Obrigatório', (
    tester,
  ) async {
    await db.veiculosDao.insertVeiculo(_novoVeiculo());
    await _pumpScreen(tester, db);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Preço do álcool (R\$/L)'),
      '3,90',
    );
    // Deixa campo gasolina vazio.
    await tester.tap(find.widgetWithText(FilledButton, 'Comparar'));
    await _advance(tester);

    expect(find.text('Obrigatório'), findsOneWidget);
    expect(find.textContaining('/km'), findsNothing);
    await _teardownUi(tester);
  });

  testWidgets(
    'preço não-numérico (apenas pontuação) exibe mensagem Valor inválido',
    (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await _pumpScreen(tester, db);

      // "," passa pelo inputFormatter mas double.tryParse(',') == null → inválido.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Preço do álcool (R\$/L)'),
        ',',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Preço da gasolina (R\$/L)'),
        '6,00',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Comparar'));
      await _advance(tester);

      expect(find.text('Valor inválido'), findsOneWidget);
      expect(find.textContaining('/km'), findsNothing);
      await _teardownUi(tester);
    },
  );

  testWidgets('preço zero exibe mensagem Valor inválido', (tester) async {
    await db.veiculosDao.insertVeiculo(_novoVeiculo());
    await _pumpScreen(tester, db);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Preço do álcool (R\$/L)'),
      '0',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Preço da gasolina (R\$/L)'),
      '6,00',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Comparar'));
    await _advance(tester);

    expect(find.text('Valor inválido'), findsOneWidget);
    expect(find.textContaining('/km'), findsNothing);
    await _teardownUi(tester);
  });

  // ─── Resultados adicionais ─────────────────────────────────────────────────

  testWidgets('exibe "Gasolina compensa" quando gasolina é mais barata', (
    tester,
  ) async {
    await db.veiculosDao.insertVeiculo(_novoVeiculo());
    await _pumpScreen(tester, db);

    // 4,50 / 6,00 = 0,75 > 0,70 → gasolina vence.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Preço do álcool (R\$/L)'),
      '4,50',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Preço da gasolina (R\$/L)'),
      '6,00',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Comparar'));
    await _advance(tester);

    expect(find.text('Gasolina compensa'), findsOneWidget);
    expect(find.text('Regra dos 70%'), findsOneWidget);
    expect(find.textContaining('/km'), findsNWidgets(2));
    await _teardownUi(tester);
  });

  testWidgets('exibe "Empate técnico" quando razão é exatamente 0,70', (
    tester,
  ) async {
    await db.veiculosDao.insertVeiculo(_novoVeiculo());
    await _pumpScreen(tester, db);

    // 7,00 / 10,00 = 0,70 exato → empate.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Preço do álcool (R\$/L)'),
      '7,00',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Preço da gasolina (R\$/L)'),
      '10,00',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Comparar'));
    await _advance(tester);

    expect(find.text('Empate técnico'), findsOneWidget);
    expect(find.text('Regra dos 70%'), findsOneWidget);
    expect(find.textContaining('/km'), findsNWidgets(2));
    await _teardownUi(tester);
  });

  testWidgets('dropdown mostra múltiplos veículos ativos', (tester) async {
    await db.veiculosDao.insertVeiculo(_novoVeiculo(placa: 'AAA0000'));
    await db.veiculosDao.insertVeiculo(_novoVeiculo(placa: 'BBB1111'));

    await _pumpScreen(tester, db);

    // O DropdownButtonFormField deve exibir os dois veículos ao abrir.
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    await _teardownUi(tester);
  });

  testWidgets(
    'nota de sem histórico aparece na rota regra 70% e some na rota histórico',
    (tester) async {
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

      // Nota "Sem histórico suficiente..." deve aparecer.
      expect(find.textContaining('Sem histórico suficiente'), findsOneWidget);
      await _teardownUi(tester);
    },
  );
}
