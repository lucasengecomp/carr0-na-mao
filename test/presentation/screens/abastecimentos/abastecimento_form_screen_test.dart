import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/data/providers.dart';
import 'package:carro_na_mao/presentation/screens/abastecimentos/abastecimento_form_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpForm(
  WidgetTester tester, {
  required AppDatabase db,
  String? placaAtiva,
  int? id,
}) async {
  SharedPreferences.setMockInitialValues(
    placaAtiva == null ? {} : {'veiculo_selecionado_placa': placaAtiva},
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(home: AbastecimentoFormScreen(id: id)),
    ),
  );
  await tester.pumpAndSettle();
}

/// Desmonta o widget tree e processa os timers pendentes do Drift
/// (streams fechando no dispose do ProviderScope). Deve ser chamado ao
/// final de cada teste — `addTearDown` não serve, pois roda após o
/// `_verifyInvariants` do flutter_test.
Future<void> _teardownUI(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 10));
}

Finder _byKey(String key) => find.byKey(Key(key));

Future<void> _seedVeiculo(
  AppDatabase db, {
  String placa = 'ABC1D23',
  TipoCombustivelVeiculo combustivel = TipoCombustivelVeiculo.flex,
}) {
  return db.veiculosDao.insertVeiculo(
    VeiculosCompanion.insert(
      placa: placa,
      marca: 'Fiat',
      modelo: 'Uno',
      ano: 2020,
      tipo: TipoVeiculo.carro,
      combustivel: combustivel,
      kmInicial: 10000,
    ),
  );
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await _seedVeiculo(db);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('submete abastecimento válido e persiste', (tester) async {
    await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

    await tester.enterText(_byKey('abast_km'), '12345');
    await tester.enterText(_byKey('abast_preco'), '6,20');
    await tester.enterText(_byKey('abast_litros'), '40');

    await tester.scrollUntilVisible(
      find.byType(FilledButton),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    final lista = await db.abastecimentosDao.listByVeiculo('ABC1D23');
    expect(lista, hasLength(1));
    expect(lista.single.km, 12345);
    expect(lista.single.precoLitro, closeTo(6.20, 1e-6));
    expect(lista.single.litros, closeTo(40, 1e-6));
    expect(lista.single.valorTotal, closeTo(248.0, 1e-6));
    expect(lista.single.tanqueCheio, isTrue);
    await _teardownUI(tester);
  });

  testWidgets('calcula valor total a partir de preço × litros', (tester) async {
    await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

    await tester.enterText(_byKey('abast_preco'), '6');
    await tester.enterText(_byKey('abast_litros'), '10');
    await tester.pump();

    final valorField = tester.widget<TextFormField>(_byKey('abast_valor'));
    expect(valorField.controller!.text, '60');
    await _teardownUI(tester);
  });

  testWidgets('calcula litros a partir de valor / preço', (tester) async {
    await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

    await tester.enterText(_byKey('abast_preco'), '5');
    await tester.enterText(_byKey('abast_valor'), '100');
    await tester.pump();

    final litrosField = tester.widget<TextFormField>(_byKey('abast_litros'));
    expect(litrosField.controller!.text, '20');
    await _teardownUI(tester);
  });

  testWidgets('calcula preço a partir de valor / litros', (tester) async {
    await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

    await tester.enterText(_byKey('abast_litros'), '25');
    await tester.enterText(_byKey('abast_valor'), '150');
    await tester.pump();

    final precoField = tester.widget<TextFormField>(_byKey('abast_preco'));
    expect(precoField.controller!.text, '6');
    await _teardownUI(tester);
  });

  testWidgets('km obrigatório bloqueia submit', (tester) async {
    await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

    await tester.enterText(_byKey('abast_preco'), '6');
    await tester.enterText(_byKey('abast_litros'), '10');

    await tester.scrollUntilVisible(
      find.byType(FilledButton),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Obrigatório'), findsWidgets);
    expect(await db.abastecimentosDao.listByVeiculo('ABC1D23'), isEmpty);
    await _teardownUI(tester);
  });

  testWidgets('sem veículo cadastrado mostra aviso', (tester) async {
    final dbVazio = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(dbVazio.close);
    SharedPreferences.setMockInitialValues(const {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(dbVazio)],
        child: const MaterialApp(home: AbastecimentoFormScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Cadastre um veículo'), findsOneWidget);
    await _teardownUI(tester);
  });

  testWidgets('modo edição carrega abastecimento e persiste alterações', (
    tester,
  ) async {
    final id = await db.abastecimentosDao.insertAbastecimento(
      AbastecimentosCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        data: DateTime(2026, 3, 1),
        km: 50000,
        tipoCombustivel: TipoCombustivelAbastecimento.gasolina,
        precoLitro: 6,
        valorTotal: 300,
        litros: 50,
        posto: const Value('Shell Centro'),
      ),
    );

    await _pumpForm(tester, db: db, id: id);

    expect(find.text('Editar abastecimento'), findsOneWidget);
    expect(find.text('50000'), findsOneWidget);
    expect(find.text('Shell Centro'), findsOneWidget);

    await tester.enterText(_byKey('abast_km'), '55000');

    await tester.scrollUntilVisible(
      find.byType(FilledButton),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    final atualizado = (await db.abastecimentosDao.byId(id))!;
    expect(atualizado.km, 55000);
    await _teardownUI(tester);
  });

  testWidgets('veículo álcool-only filtra combustíveis do dropdown', (
    tester,
  ) async {
    final dbAlcool = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(dbAlcool.close);
    await _seedVeiculo(
      dbAlcool,
      placa: 'XYZ9A99',
      combustivel: TipoCombustivelVeiculo.alcool,
    );

    SharedPreferences.setMockInitialValues(const {
      'veiculo_selecionado_placa': 'XYZ9A99',
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(dbAlcool)],
        child: const MaterialApp(home: AbastecimentoFormScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final dropdown = tester
        .widget<DropdownButtonFormField<TipoCombustivelAbastecimento>>(
          find.byType(DropdownButtonFormField<TipoCombustivelAbastecimento>),
        );
    expect(dropdown.initialValue, TipoCombustivelAbastecimento.alcool);

    // Abre o dropdown e confere que só Álcool aparece.
    await tester.tap(
      find.byType(DropdownButtonFormField<TipoCombustivelAbastecimento>),
    );
    await tester.pumpAndSettle();

    expect(find.text('Álcool'), findsWidgets);
    expect(find.text('Gasolina'), findsNothing);
    await _teardownUI(tester);
  });

  // ---------------------------------------------------------------------------
  // Autocomplete de posto (issue #15)
  // ---------------------------------------------------------------------------

  testWidgets('autocomplete: campo posto aparece no form', (tester) async {
    await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');
    expect(_byKey('abast_posto'), findsOneWidget);
    await _teardownUI(tester);
  });

  testWidgets('autocomplete: digitar no posto mostra sugestões do DAO', (
    tester,
  ) async {
    // Pre-seed do histórico
    await db.postoSugestaoDao.upsert('Shell Centro');
    await db.postoSugestaoDao.upsert('Shell Norte');

    await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

    await tester.tap(_byKey('abast_posto'));
    await tester.pump();
    await tester.enterText(_byKey('abast_posto'), 'Shell');
    // O optionsBuilder retorna Future<Iterable<String>>.
    // Bombeia frames para o Future completar e o overlay renderizar.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    // Verifica se sugestões aparecem no overlay.
    // NOTA: Se este teste falhar, o bug está no _PostoAutocomplete dentro do
    // AbastecimentoFormScreen — o widget em isolamento funciona corretamente
    // (confirmado em teste mínimo), mas no contexto do form completo as opções
    // não são exibidas. Ver issue de bug correspondente.
    expect(
      find.text('Shell Centro'),
      findsWidgets,
      reason: '_PostoAutocomplete deve exibir sugestões do DAO no overlay',
    );
    expect(
      find.text('Shell Norte'),
      findsWidgets,
      reason: '_PostoAutocomplete deve exibir sugestões do DAO no overlay',
    );
    await _teardownUI(tester);
  });

  testWidgets(
    'autocomplete: tocar em sugestão preenche o campo com o valor selecionado',
    (tester) async {
      await db.postoSugestaoDao.upsert('Ipiranga Centro');

      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.tap(_byKey('abast_posto'));
      await tester.pump();
      await tester.enterText(_byKey('abast_posto'), 'Ipiranga');
      // Aguarda o Future do optionsBuilder completar e o overlay renderizar.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Verifica que a sugestão está visível no overlay antes do tap.
      expect(find.text('Ipiranga Centro'), findsWidgets);

      // Toca na sugestão no overlay — o onSelected do RawAutocomplete é chamado.
      await tester.tap(find.text('Ipiranga Centro').last);
      await tester.pumpAndSettle();

      // O campo posto deve conter o texto selecionado.
      final postoField = tester.widget<TextFormField>(_byKey('abast_posto'));
      expect(postoField.controller!.text, 'Ipiranga Centro');
      await _teardownUI(tester);
    },
  );

  testWidgets('autocomplete: query sem match não mostra sugestões estranhas', (
    tester,
  ) async {
    await db.postoSugestaoDao.upsert('Ipiranga');
    await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

    await tester.enterText(_byKey('abast_posto'), 'XYZ_NADA');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Ipiranga'), findsNothing);
    await _teardownUI(tester);
  });

  testWidgets(
    'autocomplete: salvar com posto preenchido grava sugestão no DAO',
    (tester) async {
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.enterText(_byKey('abast_km'), '20000');
      await tester.enterText(_byKey('abast_preco'), '6');
      await tester.enterText(_byKey('abast_litros'), '50');
      await tester.enterText(_byKey('abast_posto'), 'Petrobras Centro');

      await tester.scrollUntilVisible(
        find.byType(FilledButton),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      final sugestoes = await db.postoSugestaoDao.search('Petrobras');
      expect(sugestoes, contains('Petrobras Centro'));
      await _teardownUI(tester);
    },
  );

  testWidgets('autocomplete: salvar com posto vazio NÃO cria sugestão', (
    tester,
  ) async {
    await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

    await tester.enterText(_byKey('abast_km'), '20000');
    await tester.enterText(_byKey('abast_preco'), '6');
    await tester.enterText(_byKey('abast_litros'), '50');
    // Campo posto deixado em branco (não digitamos nada)

    await tester.scrollUntilVisible(
      find.byType(FilledButton),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    final sugestoes = await db.select(db.postosSugestao).get();
    expect(sugestoes, isEmpty);
    await _teardownUI(tester);
  });
}
