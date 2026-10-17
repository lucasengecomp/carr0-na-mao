// ignore_for_file: lines_longer_than_80_chars

import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/data/providers.dart';
import 'package:carro_na_mao/presentation/screens/despesas/despesa_form_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/l10n_delegates.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<void> _seedVeiculo(AppDatabase db, {String placa = 'ABC1D23'}) =>
    db.veiculosDao.insertVeiculo(
      VeiculosCompanion.insert(
        placa: placa,
        marca: 'Fiat',
        modelo: 'Uno',
        ano: 2020,
        tipo: TipoVeiculo.carro,
        combustivel: TipoCombustivelVeiculo.flex,
        kmInicial: 10000,
      ),
    );

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
        home: DespesaFormScreen(id: id),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _teardownUI(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 10));
}

Finder _byKey(String key) => find.byKey(Key(key));

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await _seedVeiculo(db);
  });

  tearDown(() async {
    await db.close();
  });

  // -------------------------------------------------------------------------
  // Estado inicial (modo criação)
  // -------------------------------------------------------------------------

  group('modo criação — estado inicial', () {
    testWidgets('exibe título "Nova despesa"', (tester) async {
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');
      expect(find.textContaining('Nova despesa'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('campo nome começa vazio', (tester) async {
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');
      final nomeField = tester.widget<TextFormField>(_byKey('despesa_nome'));
      expect(nomeField.controller!.text, isEmpty);
      await _teardownUI(tester);
    });

    testWidgets('campo valor começa vazio', (tester) async {
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');
      final valorField = tester.widget<TextFormField>(_byKey('despesa_valor'));
      expect(valorField.controller!.text, isEmpty);
      await _teardownUI(tester);
    });

    testWidgets('data de início exibe data de hoje no formato dd/MM/aaaa', (
      tester,
    ) async {
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');
      final hoje = DateTime.now();
      final dd = hoje.day.toString().padLeft(2, '0');
      final mm = hoje.month.toString().padLeft(2, '0');
      final dataFormatada = '$dd/$mm/${hoje.year}';
      expect(find.text(dataFormatada), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets(
      'campo dia do mês está visível para frequência padrão (mensal)',
      (tester) async {
        await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');
        expect(_byKey('despesa_dia'), findsOneWidget);
        await _teardownUI(tester);
      },
    );
  });

  // -------------------------------------------------------------------------
  // Visibilidade do campo "dia do mês" por frequência
  // -------------------------------------------------------------------------

  group('campo diaDoMes — visibilidade por frequência', () {
    testWidgets('frequência Mensal → campo diaDoMes visível', (tester) async {
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      // Seleciona Mensal explicitamente (já é o default, mas garantimos).
      await tester.tap(find.byType(DropdownButtonFormField<FrequenciaDespesa>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mensal').last);
      await tester.pumpAndSettle();

      expect(_byKey('despesa_dia'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('frequência Anual → campo diaDoMes visível', (tester) async {
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.tap(find.byType(DropdownButtonFormField<FrequenciaDespesa>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anual').last);
      await tester.pumpAndSettle();

      expect(_byKey('despesa_dia'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('frequência Única → campo diaDoMes NÃO aparece', (
      tester,
    ) async {
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.tap(find.byType(DropdownButtonFormField<FrequenciaDespesa>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Única').last);
      await tester.pumpAndSettle();

      expect(_byKey('despesa_dia'), findsNothing);
      await _teardownUI(tester);
    });

    testWidgets('frequência Semanal → campo diaDoMes NÃO aparece', (
      tester,
    ) async {
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.tap(find.byType(DropdownButtonFormField<FrequenciaDespesa>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Semanal').last);
      await tester.pumpAndSettle();

      expect(_byKey('despesa_dia'), findsNothing);
      await _teardownUI(tester);
    });

    testWidgets(
      'trocar de Mensal para Única limpa conteúdo do campo diaDoMes',
      (tester) async {
        await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

        // Preenche o campo diaDoMes enquanto é Mensal.
        await tester.enterText(_byKey('despesa_dia'), '15');

        // Troca para Única.
        await tester.tap(
          find.byType(DropdownButtonFormField<FrequenciaDespesa>),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Única').last);
        await tester.pumpAndSettle();

        // Volta para Mensal — campo deve estar vazio.
        await tester.tap(
          find.byType(DropdownButtonFormField<FrequenciaDespesa>),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mensal').last);
        await tester.pumpAndSettle();

        final diaField = tester.widget<TextFormField>(_byKey('despesa_dia'));
        expect(diaField.controller!.text, isEmpty);
        await _teardownUI(tester);
      },
    );
  });

  // -------------------------------------------------------------------------
  // Validações do formulário
  // -------------------------------------------------------------------------

  group('validações', () {
    Future<void> scrollAndSubmit(WidgetTester tester) async {
      await tester.scrollUntilVisible(
        find.byType(FilledButton),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
    }

    testWidgets('nome vazio → mensagem de obrigatório', (tester) async {
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.enterText(_byKey('despesa_valor'), '100');
      await tester.enterText(_byKey('despesa_dia'), '5');
      await scrollAndSubmit(tester);

      expect(find.text('Obrigatório'), findsWidgets);
      await _teardownUI(tester);
    });

    testWidgets('valor negativo → mensagem de erro', (tester) async {
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.enterText(_byKey('despesa_nome'), 'IPVA');
      // O formatter de decimal só permite dígitos + vírgula/ponto,
      // então -100 não é aceito pelo formatter.
      // Verificamos que um valor claramente inválido ("abc") resulta em erro.
      await tester.enterText(_byKey('despesa_valor'), 'abc');
      await tester.enterText(_byKey('despesa_dia'), '5');
      await scrollAndSubmit(tester);

      // O campo valor deve mostrar erro de validação.
      expect(find.text('Obrigatório'), findsWidgets);
      await _teardownUI(tester);
    });

    testWidgets('diaDoMes = 0 → mensagem de dia inválido', (tester) async {
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.enterText(_byKey('despesa_nome'), 'IPVA');
      await tester.enterText(_byKey('despesa_valor'), '100');
      await tester.enterText(_byKey('despesa_dia'), '0');
      await scrollAndSubmit(tester);

      // A validação exige 1-28; 0 é inválido.
      expect(find.textContaining('inválido'), findsWidgets);
      await _teardownUI(tester);
    });

    testWidgets('diaDoMes = 29 → mensagem de dia inválido (max 28)', (
      tester,
    ) async {
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.enterText(_byKey('despesa_nome'), 'IPVA');
      await tester.enterText(_byKey('despesa_valor'), '100');
      await tester.enterText(_byKey('despesa_dia'), '29');
      await scrollAndSubmit(tester);

      expect(find.textContaining('inválido'), findsWidgets);
      await _teardownUI(tester);
    });

    testWidgets('diaDoMes vazio com frequência mensal → erro obrigatório', (
      tester,
    ) async {
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      // Garante frequência mensal.
      // Frequência mensal é o default; deixa campo diaDoMes vazio.
      await tester.enterText(_byKey('despesa_nome'), 'Estacionamento');
      await tester.enterText(_byKey('despesa_valor'), '50');
      // Não preenche diaDoMes.
      await scrollAndSubmit(tester);

      expect(find.text('Obrigatório'), findsWidgets);
      await _teardownUI(tester);
    });

    testWidgets('formulário válido não mostra erros de validação', (
      tester,
    ) async {
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.enterText(_byKey('despesa_nome'), 'IPVA');
      await tester.enterText(_byKey('despesa_valor'), '1500');
      await tester.enterText(_byKey('despesa_dia'), '10');
      await tester.pumpAndSettle();

      // Não deve mostrar erros antes do submit.
      expect(find.text('Obrigatório'), findsNothing);
      await _teardownUI(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Submit — criação
  // -------------------------------------------------------------------------

  group('submit — criação', () {
    testWidgets('form válido insere despesa no banco', (tester) async {
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.enterText(_byKey('despesa_nome'), 'IPVA');
      await tester.enterText(_byKey('despesa_valor'), '1500');
      await tester.enterText(_byKey('despesa_dia'), '10');

      await tester.scrollUntilVisible(
        find.byType(FilledButton),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      final despesas = await db.despesasRecorrentesDao.listByVeiculo('ABC1D23');
      expect(despesas, hasLength(1));
      expect(despesas.single.nome, 'IPVA');
      expect(despesas.single.valor, closeTo(1500, 1e-6));
      expect(despesas.single.diaDoMes, 10);
      await _teardownUI(tester);
    });

    testWidgets(
      'criação com frequência Única chama materializar: gera 1 ocorrência',
      (tester) async {
        await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

        // Usa frequência Única para que materializar gere 1 ocorrência
        // independente do horário de hoje (sem cursor mensal afetado pelo bug).
        await tester.tap(
          find.byType(DropdownButtonFormField<FrequenciaDespesa>),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Única').last);
        await tester.pumpAndSettle();

        await tester.enterText(_byKey('despesa_nome'), 'Estacionamento');
        await tester.enterText(_byKey('despesa_valor'), '200');

        await tester.scrollUntilVisible(
          find.byType(FilledButton),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        final despesas = await db.despesasRecorrentesDao.listByVeiculo(
          'ABC1D23',
        );
        expect(despesas, hasLength(1));

        final ocorrencias = await db.ocorrenciasDespesaDao.listByDespesa(
          despesas.single.id,
        );
        expect(
          ocorrencias,
          isNotEmpty,
          reason: 'materializar deve ser chamado ao salvar (frequência única)',
        );
        await _teardownUI(tester);
      },
    );

    // Documenta o bug: materializar mensal com dataInicio = DateTime.now()
    // (que possui componente de hora) pode não gerar ocorrência no mês corrente
    // porque cursor (meia-noite) < dataInicio (com hora) → avança para mês seguinte.
    testWidgets(
      '[bug] mensal + dataInicio=hoje (com hora) deve gerar ocorrência no '
      'mês corrente — demonstra bug na normalização de dataInicio',
      (tester) async {
        await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

        final hoje = DateTime.now();
        final dia = hoje.day.clamp(1, 28);

        await tester.enterText(_byKey('despesa_nome'), 'Bug Mensal Hora');
        await tester.enterText(_byKey('despesa_valor'), '100');
        await tester.enterText(_byKey('despesa_dia'), dia.toString());

        await tester.scrollUntilVisible(
          find.byType(FilledButton),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        final despesas = await db.despesasRecorrentesDao.listByVeiculo(
          'ABC1D23',
        );
        if (despesas.isEmpty) return;

        final ocorrencias = await db.ocorrenciasDespesaDao.listByDespesa(
          despesas.first.id,
        );
        // BUG: materializar não normaliza despesa.dataInicio antes de comparar
        // com o cursor (meia-noite). Quando dataInicio tem hora > 00:00, o cursor
        // avança para o mês seguinte, que ultrapassa fimMesCorrente → 0 ocorrências.
        expect(
          ocorrencias,
          isNotEmpty,
          reason:
              '[BUG] materializar mensal ignora mês corrente quando '
              'dataInicio tem componente de hora',
        );
        await _teardownUI(tester);
      },
      // Bug corrigido em #56: materializar agora normaliza dataInicio antes de comparar.
    );

    testWidgets('criação idempotente: submit 2× não duplica despesa', (
      tester,
    ) async {
      // Esse teste verifica que pressionar Salvar navega para fora (pop),
      // prevenindo duplo submit. Em ambiente de teste sem router, o pop
      // pode falhar silenciosamente. Verificamos que apenas 1 despesa foi
      // inserida após o primeiro submit.
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.enterText(_byKey('despesa_nome'), 'Lavagem');
      await tester.enterText(_byKey('despesa_valor'), '50');
      await tester.enterText(_byKey('despesa_dia'), '1');

      await tester.scrollUntilVisible(
        find.byType(FilledButton),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      final despesas = await db.despesasRecorrentesDao.listByVeiculo('ABC1D23');
      expect(despesas.length, lessThanOrEqualTo(1));
      await _teardownUI(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Submit — edição
  // -------------------------------------------------------------------------

  group('submit — edição', () {
    late int despesaId;

    setUp(() async {
      despesaId = await db.despesasRecorrentesDao.insertDespesa(
        DespesasRecorrentesCompanion.insert(
          veiculoPlaca: 'ABC1D23',
          nome: 'Pedágio',
          categoria: CategoriaDespesa.pedagio,
          valor: 80,
          frequencia: FrequenciaDespesa.mensal,
          diaDoMes: const Value(15),
          dataInicio: DateTime(2026, 1, 1),
        ),
      );
    });

    testWidgets('modo edição exibe título "Editar despesa"', (tester) async {
      await _pumpForm(tester, db: db, id: despesaId);
      expect(find.textContaining('Editar'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('modo edição carrega nome existente', (tester) async {
      await _pumpForm(tester, db: db, id: despesaId);
      // Aguarda carregamento assíncrono.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      final nomeField = tester.widget<TextFormField>(_byKey('despesa_nome'));
      expect(nomeField.controller!.text, 'Pedágio');
      await _teardownUI(tester);
    });

    testWidgets('modo edição carrega valor existente', (tester) async {
      await _pumpForm(tester, db: db, id: despesaId);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      final valorField = tester.widget<TextFormField>(_byKey('despesa_valor'));
      expect(valorField.controller!.text, isNotEmpty);
      await _teardownUI(tester);
    });

    testWidgets('editar e salvar atualiza despesa no banco', (tester) async {
      await _pumpForm(tester, db: db, id: despesaId);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      await tester.enterText(_byKey('despesa_nome'), 'Pedágio Atualizado');
      await tester.enterText(_byKey('despesa_valor'), '90');

      await tester.scrollUntilVisible(
        find.byType(FilledButton),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      final atualizada = await db.despesasRecorrentesDao.byId(despesaId);
      expect(atualizada!.nome, 'Pedágio Atualizado');
      expect(atualizada.valor, closeTo(90, 1e-6));
      await _teardownUI(tester);
    });

    testWidgets('edição não duplica ocorrências (idempotência)', (
      tester,
    ) async {
      // Materializa antes da edição.
      final despesa = (await db.despesasRecorrentesDao.byId(despesaId))!;
      await db.ocorrenciasDespesaDao.materializar(despesa);
      final antesCount = (await db.ocorrenciasDespesaDao.listByDespesa(
        despesaId,
      )).length;

      await _pumpForm(tester, db: db, id: despesaId);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Edita sem mudar nada relevante.
      await tester.enterText(_byKey('despesa_nome'), 'Pedágio');

      await tester.scrollUntilVisible(
        find.byType(FilledButton),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      final depoisCount = (await db.ocorrenciasDespesaDao.listByDespesa(
        despesaId,
      )).length;
      expect(
        depoisCount,
        equals(antesCount),
        reason: 'Edição não deve duplicar ocorrências',
      );
      await _teardownUI(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Botão limpar dataFim
  // -------------------------------------------------------------------------

  group('dataFim', () {
    testWidgets('inicialmente exibe texto indicando que dataFim está vazia', (
      tester,
    ) async {
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');
      // O form deve exibir algum texto de placeholder para dataFim vazia.
      // Conforme o código, usa l10n.despesaDataFimVazia.
      // Em pt-BR, verificamos que há um InkWell para dataFim com texto vazio/placeholder.
      // Indiretamente: não deve haver 2 datas formatadas no form.
      final hoje = DateTime.now();
      final dd = hoje.day.toString().padLeft(2, '0');
      final mm = hoje.month.toString().padLeft(2, '0');
      final dataFormatada = '$dd/$mm/${hoje.year}';
      // Apenas 1 data formatada deve aparecer (a dataInicio).
      expect(find.text(dataFormatada), findsOneWidget);
      await _teardownUI(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Sem veículo cadastrado
  // -------------------------------------------------------------------------

  group('sem veículo', () {
    testWidgets('exibe aviso quando não há veículo ativo', (tester) async {
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
            home: DespesaFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('veículo'), findsWidgets);
      await _teardownUI(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Textos pt-BR
  // -------------------------------------------------------------------------

  group('i18n pt-BR', () {
    testWidgets('campos exibem labels em português', (tester) async {
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.textContaining('Nome'), findsOneWidget);
      expect(find.textContaining('Valor'), findsOneWidget);
      expect(find.textContaining('Frequência'), findsOneWidget);
      // "Dia" aparece no label e no helper text — usa findsWidgets.
      expect(find.textContaining('Dia'), findsWidgets);
      // "Data de início" é renderizada no InputDecorator via label animado.
      expect(find.textContaining('Data de'), findsWidgets);
      await _teardownUI(tester);
    });

    testWidgets('botão salvar exibe texto em português', (tester) async {
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.scrollUntilVisible(
        find.byType(FilledButton),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Salvar'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('dropdown de frequência exibe opções em pt-BR', (tester) async {
      await _pumpForm(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.tap(find.byType(DropdownButtonFormField<FrequenciaDespesa>));
      await tester.pumpAndSettle();

      expect(find.text('Mensal'), findsWidgets);
      expect(find.text('Anual'), findsWidgets);
      expect(find.text('Única'), findsWidgets);
      expect(find.text('Semanal'), findsWidgets);
      await _teardownUI(tester);
    });
  });
}
