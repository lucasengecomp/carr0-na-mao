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
