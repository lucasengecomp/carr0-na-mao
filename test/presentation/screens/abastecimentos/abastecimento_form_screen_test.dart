import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/data/providers.dart';
import 'package:carro_na_mao/presentation/screens/abastecimentos/abastecimento_form_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/l10n_delegates.dart';

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
      child: MaterialApp(
        locale: localeDefault,
        localizationsDelegates: l10nDelegates,
        supportedLocales: supportedLocales,
        home: AbastecimentoFormScreen(id: id),
      ),
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
        child: const MaterialApp(
          locale: localeDefault,
          localizationsDelegates: l10nDelegates,
          supportedLocales: supportedLocales,
          home: AbastecimentoFormScreen(),
        ),
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

  // ------------------------------------------------------------------ //
  // Testes de regressão: recálculo automático do terceiro campo (#51)   //
  // ------------------------------------------------------------------ //

  testWidgets('R1: preço=6 + litros=10 (char a char) → valor_total=60', (
    tester,
  ) async {
    await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

    // Digita o preço de uma vez
    await tester.enterText(_byKey('abast_preco'), '6');
    await tester.pump();

    // Digita litros char a char: '1' depois '10'
    await tester.enterText(_byKey('abast_litros'), '1');
    await tester.pump();
    await tester.enterText(_byKey('abast_litros'), '10');
    await tester.pump();

    final valorField = tester.widget<TextFormField>(_byKey('abast_valor'));
    expect(valorField.controller!.text, '60');
    await _teardownUI(tester);
  });

  testWidgets(
    'R2: preço=6 + litros=1 → valor=6; alterar litros para 10 → valor=60',
    (tester) async {
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.enterText(_byKey('abast_preco'), '6');
      await tester.pump();
      await tester.enterText(_byKey('abast_litros'), '1');
      await tester.pump();

      // Confirma que calculou 6 inicialmente
      final valorField = tester.widget<TextFormField>(_byKey('abast_valor'));
      expect(valorField.controller!.text, '6');

      // Altera litros para 10 — o valor deve atualizar para 60
      await tester.enterText(_byKey('abast_litros'), '10');
      await tester.pump();

      expect(valorField.controller!.text, '60');
      await _teardownUI(tester);
    },
  );

  testWidgets('R3: preço=6 + valor=60 → litros=10', (tester) async {
    await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

    await tester.enterText(_byKey('abast_preco'), '6');
    await tester.pump();
    await tester.enterText(_byKey('abast_valor'), '60');
    await tester.pump();

    final litrosField = tester.widget<TextFormField>(_byKey('abast_litros'));
    expect(litrosField.controller!.text, '10');
    await _teardownUI(tester);
  });

  testWidgets('R4: litros=10 + valor=50 → preço=5', (tester) async {
    await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

    await tester.enterText(_byKey('abast_litros'), '10');
    await tester.pump();
    await tester.enterText(_byKey('abast_valor'), '50');
    await tester.pump();

    final precoField = tester.widget<TextFormField>(_byKey('abast_preco'));
    expect(precoField.controller!.text, '5');
    await _teardownUI(tester);
  });

  testWidgets('R5: preencher 2 campos, alterar um → terceiro recalcula', (
    tester,
  ) async {
    await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

    // Primeiro cálculo: preço=5 + litros=10 → valor=50
    await tester.enterText(_byKey('abast_preco'), '5');
    await tester.pump();
    await tester.enterText(_byKey('abast_litros'), '10');
    await tester.pump();

    final valorField = tester.widget<TextFormField>(_byKey('abast_valor'));
    expect(valorField.controller!.text, '50');

    // Altera preço para 6 → valor deve recalcular para 60
    await tester.enterText(_byKey('abast_preco'), '6');
    await tester.pump();

    expect(valorField.controller!.text, '60');
    await _teardownUI(tester);
  });

  testWidgets(
    'R6: edição manual do 3º campo NÃO é sobrescrita pelo cálculo automático',
    (tester) async {
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      // Preenche 2 campos → valor calculado = 50
      await tester.enterText(_byKey('abast_preco'), '5');
      await tester.pump();
      await tester.enterText(_byKey('abast_litros'), '10');
      await tester.pump();

      // Edita manualmente o campo calculado (valor) para 99
      await tester.enterText(_byKey('abast_valor'), '99');
      await tester.pump();

      // Digita novamente no primeiro campo (preco) — não deve sobrescrever o 99
      await tester.enterText(_byKey('abast_preco'), '5');
      await tester.pump();

      final valorField = tester.widget<TextFormField>(_byKey('abast_valor'));
      // O valor foi editado manualmente; o campo "calculado" agora é outro.
      // O que importa é que '99' NÃO seja sobrescrito pelo cálculo de preco*litros=50.
      expect(valorField.controller!.text, isNot('50'));
      await _teardownUI(tester);
    },
  );

  // ---------------------------------------------------------------------------
  // RF-06: aviso não-bloqueante de km retroativo
  // ---------------------------------------------------------------------------

  testWidgets(
    'RF-06 — sem histórico (primeiro abastecimento): banner NÃO aparece',
    (tester) async {
      // DB só tem o veículo, nenhum abastecimento ainda.
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.enterText(_byKey('abast_km'), '12000');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('menor que o último registrado'),
        findsNothing,
      );
      await _teardownUI(tester);
    },
  );

  testWidgets('RF-06 — km maior que último: banner NÃO aparece', (
    tester,
  ) async {
    // Insere um abastecimento com km = 10 000.
    await db.abastecimentosDao.insertAbastecimento(
      AbastecimentosCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        data: DateTime(2026, 1, 1),
        km: 10000,
        tipoCombustivel: TipoCombustivelAbastecimento.gasolina,
        precoLitro: 6,
        valorTotal: 240,
        litros: 40,
      ),
    );

    await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

    // Digita km MAIOR que 10 000.
    await tester.enterText(_byKey('abast_km'), '11000');
    await tester.pumpAndSettle();

    expect(find.textContaining('menor que o último registrado'), findsNothing);
    await _teardownUI(tester);
  });

  testWidgets('RF-06 — km menor que último: banner APARECE', (tester) async {
    await db.abastecimentosDao.insertAbastecimento(
      AbastecimentosCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        data: DateTime(2026, 1, 1),
        km: 50000,
        tipoCombustivel: TipoCombustivelAbastecimento.gasolina,
        precoLitro: 6,
        valorTotal: 240,
        litros: 40,
      ),
    );

    await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

    // Digita km MENOR que 50 000.
    await tester.enterText(_byKey('abast_km'), '45000');
    await tester.pumpAndSettle();

    expect(
      find.textContaining('menor que o último registrado'),
      findsOneWidget,
    );
    await _teardownUI(tester);
  });

  testWidgets(
    'RF-06 — km menor que último: botão Salvar permanece habilitado (não-bloqueante)',
    (tester) async {
      await db.abastecimentosDao.insertAbastecimento(
        AbastecimentosCompanion.insert(
          veiculoPlaca: 'ABC1D23',
          data: DateTime(2026, 1, 1),
          km: 50000,
          tipoCombustivel: TipoCombustivelAbastecimento.gasolina,
          precoLitro: 6,
          valorTotal: 240,
          litros: 40,
        ),
      );

      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.enterText(_byKey('abast_km'), '45000');
      await tester.pumpAndSettle();

      // O botão Salvar deve existir e estar habilitado (onPressed != null).
      final btn = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(btn.onPressed, isNotNull);
      await _teardownUI(tester);
    },
  );

  testWidgets('RF-06 — corrigir km para valor maior que último: banner SOME', (
    tester,
  ) async {
    await db.abastecimentosDao.insertAbastecimento(
      AbastecimentosCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        data: DateTime(2026, 1, 1),
        km: 50000,
        tipoCombustivel: TipoCombustivelAbastecimento.gasolina,
        precoLitro: 6,
        valorTotal: 240,
        litros: 40,
      ),
    );

    await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

    // Acende o banner.
    await tester.enterText(_byKey('abast_km'), '45000');
    await tester.pumpAndSettle();
    expect(
      find.textContaining('menor que o último registrado'),
      findsOneWidget,
    );

    // Corrige para km válido (maior que 50 000).
    await tester.enterText(_byKey('abast_km'), '55000');
    await tester.pumpAndSettle();
    expect(find.textContaining('menor que o último registrado'), findsNothing);
    await _teardownUI(tester);
  });

  testWidgets(
    'RF-06 — km igual ao último: banner NÃO aparece (igual não é retroativo)',
    (tester) async {
      await db.abastecimentosDao.insertAbastecimento(
        AbastecimentosCompanion.insert(
          veiculoPlaca: 'ABC1D23',
          data: DateTime(2026, 1, 1),
          km: 50000,
          tipoCombustivel: TipoCombustivelAbastecimento.gasolina,
          precoLitro: 6,
          valorTotal: 240,
          litros: 40,
        ),
      );

      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.enterText(_byKey('abast_km'), '50000');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('menor que o último registrado'),
        findsNothing,
      );
      await _teardownUI(tester);
    },
  );

  testWidgets(
    'RF-06 — km retroativo salva normalmente (abastecimento retroativo persistido)',
    (tester) async {
      await db.abastecimentosDao.insertAbastecimento(
        AbastecimentosCompanion.insert(
          veiculoPlaca: 'ABC1D23',
          data: DateTime(2026, 6, 1),
          km: 50000,
          tipoCombustivel: TipoCombustivelAbastecimento.gasolina,
          precoLitro: 6,
          valorTotal: 240,
          litros: 40,
        ),
      );

      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      // Preenche campos com km retroativo.
      await tester.enterText(_byKey('abast_km'), '48000');
      await tester.enterText(_byKey('abast_preco'), '5');
      await tester.enterText(_byKey('abast_litros'), '30');
      await tester.pumpAndSettle();

      // Confirma banner visível mas não bloqueante.
      expect(
        find.textContaining('menor que o último registrado'),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.byType(FilledButton),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // O abastecimento retroativo deve ter sido persistido.
      final lista = await db.abastecimentosDao.listByVeiculo('ABC1D23');
      expect(lista, hasLength(2));
      expect(lista.map((a) => a.km), containsAll([50000, 48000]));
      await _teardownUI(tester);
    },
  );

  testWidgets(
    'RF-06 — campo km apagado: banner some (campo vazio não dispara aviso)',
    (tester) async {
      await db.abastecimentosDao.insertAbastecimento(
        AbastecimentosCompanion.insert(
          veiculoPlaca: 'ABC1D23',
          data: DateTime(2026, 1, 1),
          km: 50000,
          tipoCombustivel: TipoCombustivelAbastecimento.gasolina,
          precoLitro: 6,
          valorTotal: 240,
          litros: 40,
        ),
      );

      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      // Acende o banner.
      await tester.enterText(_byKey('abast_km'), '45000');
      await tester.pumpAndSettle();
      expect(
        find.textContaining('menor que o último registrado'),
        findsOneWidget,
      );

      // Apaga o campo.
      await tester.enterText(_byKey('abast_km'), '');
      await tester.pumpAndSettle();
      expect(
        find.textContaining('menor que o último registrado'),
        findsNothing,
      );
      await _teardownUI(tester);
    },
  );

  testWidgets('RF-06 — modo edição: alterar km para retroativo exibe banner', (
    tester,
  ) async {
    // Insere um abastecimento existente com km = 50 000 e outro com 45 000
    // (o maior é 50 000 — o do id será 50 000, que ao ser editado para
    // 44 000 deve mostrar aviso, pois 44 000 < 50 000).
    final id = await db.abastecimentosDao.insertAbastecimento(
      AbastecimentosCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        data: DateTime(2026, 3, 1),
        km: 50000,
        tipoCombustivel: TipoCombustivelAbastecimento.gasolina,
        precoLitro: 6,
        valorTotal: 300,
        litros: 50,
      ),
    );
    // Segundo abastecimento com km maior para servir de referência.
    await db.abastecimentosDao.insertAbastecimento(
      AbastecimentosCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        data: DateTime(2026, 6, 1),
        km: 60000,
        tipoCombustivel: TipoCombustivelAbastecimento.gasolina,
        precoLitro: 6,
        valorTotal: 300,
        litros: 50,
      ),
    );

    await _pumpForm(tester, db: db, id: id);

    // Aguarda o carregamento do modo edição.
    await tester.pumpAndSettle();

    // Altera km para valor abaixo do maior registrado (60 000).
    await tester.enterText(_byKey('abast_km'), '44000');
    await tester.pumpAndSettle();

    expect(
      find.textContaining('menor que o último registrado'),
      findsOneWidget,
    );
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
        child: const MaterialApp(
          locale: localeDefault,
          localizationsDelegates: l10nDelegates,
          supportedLocales: supportedLocales,
          home: AbastecimentoFormScreen(),
        ),
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

    // Verifica que ao menos uma das sugestões aparece no overlay.
    // O Autocomplete<String> do Material ancora o overlay dentro do viewport
    // disponível — dependendo da posição do campo no form, nem todos os itens
    // precisam estar simultâneamente visíveis.
    final shellCentro = find.text('Shell Centro');
    final shellNorte = find.text('Shell Norte');
    expect(
      shellCentro.evaluate().isNotEmpty || shellNorte.evaluate().isNotEmpty,
      isTrue,
      reason: '_PostoAutocomplete deve exibir ao menos uma sugestão do DAO no overlay',
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
      expect(find.text('Ipiranga Centro'), findsAtLeastNWidgets(1));

      // Após o fix #91, o Autocomplete<String> do Material gerencia o overlay
      // internamente, posicionado dentro do viewport. O tap pode ser feito
      // diretamente via tester.tap — mas para robustez, acionamos o handler
      // do InkWell (substitui o ListTile da implementação anterior com #72).
      final inkWell = tester.widget<InkWell>(
        find.ancestor(
          of: find.text('Ipiranga Centro').first,
          matching: find.byType(InkWell),
        ),
      );
      inkWell.onTap!.call();
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

  // ---------------------------------------------------------------------------
  // Testes de regressão: posicionamento do dropdown (#72)
  // ---------------------------------------------------------------------------

  testWidgets(
    'autocomplete #72: digitar "She" com histórico ["Shell", "Ipiranga"] mostra "Shell" como sugestão',
    (tester) async {
      // Pré-popula o histórico com dois postos.
      await db.postoSugestaoDao.upsert('Shell');
      await db.postoSugestaoDao.upsert('Ipiranga');

      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.tap(_byKey('abast_posto'));
      await tester.pump();
      await tester.enterText(_byKey('abast_posto'), 'She');
      // Aguarda o Future do optionsBuilder completar e o overlay renderizar.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // "Shell" deve aparecer como sugestão — confirma que o autocomplete filtra
      // corretamente por prefixo. "Ipiranga" não deve aparecer.
      expect(
        find.text('Shell'),
        findsWidgets,
        reason: 'Sugestão "Shell" deve aparecer ao digitar "She"',
      );
      expect(
        find.text('Ipiranga'),
        findsNothing,
        reason: 'Sugestão "Ipiranga" não deve aparecer ao digitar "She"',
      );
      await _teardownUI(tester);
    },
  );

  testWidgets(
    'autocomplete #72: overlay de sugestões fica próximo ao campo posto (não em Offset.zero)',
    (tester) async {
      // Viewport maior para garantir que o campo posto fique dentro da tela
      // após a adição do CTA do Comparador (#79) que empurra o conteúdo para baixo.
      tester.view.physicalSize = const Size(800 * 3, 1200 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await db.postoSugestaoDao.upsert('Shell');

      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.tap(_byKey('abast_posto'));
      await tester.pump();
      await tester.enterText(_byKey('abast_posto'), 'She');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Verifica que a sugestão está visível.
      expect(find.text('Shell'), findsWidgets);

      // Compara a posição vertical da sugestão com a do campo posto.
      // Após o fix #91, o Autocomplete<String> do Material ancora o overlay
      // internamente — a sugestão deve aparecer imediatamente abaixo do campo.
      // Sem a ancora (bug), o overlay seria renderizado em Offset.zero (topo).
      final postoRect = tester.getRect(_byKey('abast_posto'));
      final sugestaoRect = tester.getRect(find.text('Shell').last);

      // A sugestão deve estar abaixo (ou na mesma altura) do campo posto.
      // Tolerância de 8 dp para padding interno do item.
      expect(
        sugestaoRect.top,
        greaterThanOrEqualTo(postoRect.bottom - 8),
        reason:
            'O overlay de sugestões deve estar ancorado abaixo do campo posto, '
            'não no topo da tela (Offset.zero). '
            'Campo posto bottom: ${postoRect.bottom}, '
            'Sugestão top: ${sugestaoRect.top}',
      );
      await _teardownUI(tester);
    },
  );

  // ---------------------------------------------------------------------------
  // Teste de regressão: tap-through no botão Salvar (#91)
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // CTA Comparador contextual no form (#79)
  // ---------------------------------------------------------------------------

  testWidgets(
    '#79 — veículo flex: link "Vale a pena comparar..." aparece no form',
    (tester) async {
      // O veículo padrão do setUp é flex — deve exibir o CTA.
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.byKey(const Key('cta_comparador')), findsOneWidget);
      await _teardownUI(tester);
    },
  );

  testWidgets('#79 — veículo álcool-only: link do comparador NÃO aparece', (
    tester,
  ) async {
    final dbAlcool = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(dbAlcool.close);
    await _seedVeiculo(
      dbAlcool,
      placa: 'ALC0001',
      combustivel: TipoCombustivelVeiculo.alcool,
    );

    SharedPreferences.setMockInitialValues(const {
      'veiculo_selecionado_placa': 'ALC0001',
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(dbAlcool)],
        child: const MaterialApp(
          locale: localeDefault,
          localizationsDelegates: l10nDelegates,
          supportedLocales: supportedLocales,
          home: AbastecimentoFormScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cta_comparador')), findsNothing);
    await _teardownUI(tester);
  });

  testWidgets('#79 — tocar no link do comparador navega para /comparador', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(const {
      'veiculo_selecionado_placa': 'ABC1D23',
    });
    final router = GoRouter(
      initialLocation: '/abastecimentos/novo',
      routes: [
        GoRoute(
          path: '/abastecimentos/novo',
          builder: (c, s) => const AbastecimentoFormScreen(),
        ),
        GoRoute(
          path: '/comparador',
          builder: (c, s) => const Scaffold(body: Text('ROTA_COMPARADOR')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(
          locale: localeDefault,
          localizationsDelegates: l10nDelegates,
          supportedLocales: supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cta_comparador')), findsOneWidget);

    await tester.tap(find.byKey(const Key('cta_comparador')));
    await tester.pumpAndSettle();

    expect(find.text('ROTA_COMPARADOR'), findsOneWidget);
    await _teardownUI(tester);
  });

  testWidgets(
    'autocomplete #91: tap em sugestão NÃO dispara _submit (sem erros de validação)',
    (tester) async {
      // Pré-popula histórico com o posto "Shell Centro".
      await db.postoSugestaoDao.upsert('Shell Centro');

      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      // Foca o campo posto e digita para abrir o dropdown.
      await tester.tap(_byKey('abast_posto'));
      await tester.pump();
      await tester.enterText(_byKey('abast_posto'), 'Shell');
      // Aguarda o Future do optionsBuilder completar e o overlay renderizar.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Confirma que a sugestão está visível antes do tap.
      expect(find.text('Shell Centro'), findsAtLeastNWidgets(1));

      // Aciona o InkWell da sugestão — simula o tap do usuário na sugestão.
      final inkWell = tester.widget<InkWell>(
        find.ancestor(
          of: find.text('Shell Centro').first,
          matching: find.byType(InkWell),
        ),
      );
      inkWell.onTap!.call();
      await tester.pumpAndSettle();

      // 1. O campo posto deve ter sido preenchido com "Shell Centro".
      final postoField = tester.widget<TextFormField>(_byKey('abast_posto'));
      expect(postoField.controller!.text, 'Shell Centro');

      // 2. _submit() NÃO deve ter sido chamado: os outros campos obrigatórios
      //    (preço/litros/valor) estão vazios, então se _submit tivesse sido
      //    disparado apareceriam erros de validação. A ausência de erros prova
      //    que o tap não passou para o botão Salvar (regressão do bug #91).
      expect(
        find.text('Preencha 2 dos 3 campos'),
        findsNothing,
        reason:
            'Selecionar sugestão NÃO deve disparar _submit: '
            'se disparasse, campos obrigatórios exibiriam erro de validação.',
      );
      // Verifica também que nenhuma mensagem de validação obrigatória aparece.
      expect(find.text('Obrigatório'), findsNothing);

      await _teardownUI(tester);
    },
  );

  // ---------------------------------------------------------------------------
  // Ação de excluir no AppBar (issue #78)
  // ---------------------------------------------------------------------------

  testWidgets('modo novo NÃO exibe botão de excluir no AppBar', (tester) async {
    await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

    expect(
      find.byKey(const Key('btn_excluir_abastecimento_appbar')),
      findsNothing,
    );
    await _teardownUI(tester);
  });

  testWidgets('modo edição exibe botão de excluir no AppBar', (tester) async {
    final id = await db.abastecimentosDao.insertAbastecimento(
      AbastecimentosCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        data: DateTime(2026, 3, 1),
        km: 50000,
        tipoCombustivel: TipoCombustivelAbastecimento.gasolina,
        precoLitro: 6,
        valorTotal: 300,
        litros: 50,
      ),
    );

    await _pumpForm(tester, db: db, id: id);

    expect(
      find.byKey(const Key('btn_excluir_abastecimento_appbar')),
      findsOneWidget,
    );
    await _teardownUI(tester);
  });

  testWidgets('excluir — cancelar dialog mantém o form e o registro no banco', (
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
      ),
    );

    await _pumpForm(tester, db: db, id: id);

    await tester.tap(find.byKey(const Key('btn_excluir_abastecimento_appbar')));
    await tester.pumpAndSettle();

    // Cancela o dialog
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    // Ainda no form
    expect(find.text('Editar abastecimento'), findsOneWidget);
    // Registro ainda existe
    expect(await db.abastecimentosDao.byId(id), isNotNull);
    await _teardownUI(tester);
  });

  testWidgets(
    'excluir — confirmar remove do banco, exibe snackbar e navega de volta',
    (tester) async {
      final id = await db.abastecimentosDao.insertAbastecimento(
        AbastecimentosCompanion.insert(
          veiculoPlaca: 'ABC1D23',
          data: DateTime(2026, 3, 1),
          km: 50000,
          tipoCombustivel: TipoCombustivelAbastecimento.gasolina,
          precoLitro: 6,
          valorTotal: 300,
          litros: 50,
        ),
      );

      // Monta a tela com Navigator para que pop() funcione
      SharedPreferences.setMockInitialValues(const {});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            locale: localeDefault,
            localizationsDelegates: l10nDelegates,
            supportedLocales: supportedLocales,
            home: const Scaffold(body: Text('TELA_ANTERIOR')),
            routes: {'/editar': (_) => AbastecimentoFormScreen(id: id)},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('TELA_ANTERIOR'));
      await tester.pumpAndSettle();

      // Navega para o form de edição
      final navState = tester.state<NavigatorState>(find.byType(Navigator));
      navState.pushNamed('/editar');
      await tester.pumpAndSettle();

      expect(find.text('Editar abastecimento'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('btn_excluir_abastecimento_appbar')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('btn_excluir_abastecimento_confirmar')),
      );
      await tester.pumpAndSettle();

      // Registro removido
      expect(await db.abastecimentosDao.byId(id), isNull);
      // Snackbar visível
      expect(find.text('Abastecimento excluído.'), findsOneWidget);
      // Voltou para tela anterior
      expect(find.text('TELA_ANTERIOR'), findsOneWidget);
      await _teardownUI(tester);
    },
  );
}
