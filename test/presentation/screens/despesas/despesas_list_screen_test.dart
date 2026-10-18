// ignore_for_file: lines_longer_than_80_chars

import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/data/providers.dart';
import 'package:carro_na_mao/presentation/screens/despesas/despesas_list_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

Future<int> _seedDespesa(
  AppDatabase db, {
  String placa = 'ABC1D23',
  String nome = 'Estacionamento',
  double valor = 150.0,
}) => db.despesasRecorrentesDao.insertDespesa(
  DespesasRecorrentesCompanion.insert(
    veiculoPlaca: placa,
    nome: nome,
    categoria: CategoriaDespesa.estacionamento,
    valor: valor,
    frequencia: FrequenciaDespesa.mensal,
    dataInicio: DateTime(2026, 1, 1),
  ),
);

Future<int> _seedOcorrencia(
  AppDatabase db, {
  required int despesaId,
  required DateTime vencimento,
  StatusOcorrencia status = StatusOcorrencia.pendente,
  double? valorPago,
  DateTime? dataPagamento,
}) async {
  final id = await db.ocorrenciasDespesaDao.insertOcorrencia(
    OcorrenciasDespesaCompanion.insert(
      despesaId: despesaId,
      dataVencimento: vencimento,
      status: status,
    ),
  );
  if (status == StatusOcorrencia.paga && valorPago != null) {
    await db.ocorrenciasDespesaDao.marcarPaga(
      id,
      valorPago: valorPago,
      dataPagamento: dataPagamento ?? vencimento,
    );
  } else if (status == StatusOcorrencia.pulada) {
    await db.ocorrenciasDespesaDao.marcarPulada(id);
  }
  return id;
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required AppDatabase db,
  String? placaAtiva,
}) async {
  SharedPreferences.setMockInitialValues(
    placaAtiva == null ? {} : {'veiculo_selecionado_placa': placaAtiva},
  );

  final router = GoRouter(
    initialLocation: '/despesas',
    routes: [
      GoRoute(path: '/despesas', builder: (c, s) => const DespesasListScreen()),
      GoRoute(
        path: '/despesas/novo',
        builder: (c, s) => const Scaffold(body: Text('TELA_NOVA_DESPESA')),
      ),
      GoRoute(
        path: '/veiculos/novo',
        builder: (c, s) => const Scaffold(body: Text('TELA_NOVO_VEICULO')),
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
}

Future<void> _teardownUI(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 10));
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // -------------------------------------------------------------------------
  // Estado sem veículo
  // -------------------------------------------------------------------------
  group('sem veículo cadastrado', () {
    testWidgets('exibe mensagem de cadastrar veículo', (tester) async {
      await _pumpScreen(tester, db: db);

      expect(
        find.textContaining('Cadastre um veículo'),
        findsOneWidget,
        reason: 'Deve exibir a mensagem semVeiculoCadastrarDespesa',
      );
      expect(find.byType(FloatingActionButton), findsNothing);
      await _teardownUI(tester);
    });

    testWidgets('botão "Cadastrar veículo" navega para /veiculos/novo', (
      tester,
    ) async {
      await _pumpScreen(tester, db: db);

      await tester.tap(find.text('Cadastrar veículo'));
      await tester.pumpAndSettle();

      expect(find.text('TELA_NOVO_VEICULO'), findsOneWidget);
      await _teardownUI(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Lista vazia (veículo existe, sem ocorrências)
  // -------------------------------------------------------------------------
  group('veículo cadastrado, sem ocorrências', () {
    testWidgets('exibe mensagem de lista vazia', (tester) async {
      await _seedVeiculo(db);
      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.textContaining('Nenhuma ocorrência'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('CTA lista vazia exibe FAB e botão "Nova despesa"', (
      tester,
    ) async {
      await _seedVeiculo(db);
      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      // FAB deve estar presente
      expect(find.byType(FloatingActionButton), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('FAB navega para /despesas/novo', (tester) async {
      await _seedVeiculo(db);
      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('TELA_NOVA_DESPESA'), findsOneWidget);
      await _teardownUI(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Agrupamento por mês
  // -------------------------------------------------------------------------
  group('agrupamento por mês', () {
    testWidgets('exibe cabeçalhos de meses distintos', (tester) async {
      await _seedVeiculo(db);
      final despesaId = await _seedDespesa(db);

      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2027, 3, 10),
      );
      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2027, 5, 20),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.textContaining('Março 2027'), findsOneWidget);
      expect(find.textContaining('Maio 2027'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('ocorrências do mesmo mês compartilham um único cabeçalho', (
      tester,
    ) async {
      await _seedVeiculo(db);
      final despesaId = await _seedDespesa(db);

      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2027, 4, 5),
      );
      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2027, 4, 20),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.textContaining('Abril 2027'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('cabeçalhos estão em ordem ASC por vencimento', (tester) async {
      await _seedVeiculo(db);
      final despesaId = await _seedDespesa(db);

      // Inserir fora de ordem
      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2027, 6, 1),
      );
      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2027, 4, 1),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      final abrilPos = tester.getTopLeft(find.textContaining('Abril 2027')).dy;
      final junhoPos = tester.getTopLeft(find.textContaining('Junho 2027')).dy;

      // Abril (mais antigo) deve aparecer antes de Junho
      expect(abrilPos, lessThan(junhoPos));
      await _teardownUI(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Cor vermelha para vencidas
  // -------------------------------------------------------------------------
  group('cor vermelha para ocorrências vencidas', () {
    testWidgets('pendente vencida exibe chip com texto "Pendente"', (
      tester,
    ) async {
      await _seedVeiculo(db);
      final despesaId = await _seedDespesa(db, nome: 'IPVA Vencido');

      // Vencida: data no passado
      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2020, 1, 1),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      // A ocorrência deve aparecer na lista com o nome e chip de pendente
      expect(find.textContaining('IPVA Vencido'), findsOneWidget);
      expect(find.text('Pendente'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets(
      'pendente futura exibe chip "Pendente" sem erro visual explícito',
      (tester) async {
        await _seedVeiculo(db);
        final despesaId = await _seedDespesa(db, nome: 'Seguro Futuro');

        // Futura: vence em 2099
        await _seedOcorrencia(
          db,
          despesaId: despesaId,
          vencimento: DateTime(2099, 12, 31),
        );

        await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

        expect(find.textContaining('Seguro Futuro'), findsOneWidget);
        expect(find.text('Pendente'), findsOneWidget);
        await _teardownUI(tester);
      },
    );
  });

  // -------------------------------------------------------------------------
  // Menu de ações (3-dots)
  // -------------------------------------------------------------------------
  group('menu de ações por status', () {
    testWidgets('ocorrência pendente: menu mostra "Marcar paga" e "Pular"', (
      tester,
    ) async {
      await _seedVeiculo(db);
      final despesaId = await _seedDespesa(db);
      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2099, 1, 1),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      // Abre o 3-dots menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Marcar paga'), findsOneWidget);
      expect(find.text('Pular'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('ocorrência paga: menu mostra "Editar valor pago"', (
      tester,
    ) async {
      await _seedVeiculo(db);
      final despesaId = await _seedDespesa(db);
      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2099, 1, 1),
        status: StatusOcorrencia.paga,
        valorPago: 150.0,
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Editar valor pago'), findsOneWidget);
      expect(find.text('Marcar paga'), findsNothing);
      expect(find.text('Pular'), findsNothing);
      await _teardownUI(tester);
    });

    testWidgets('ocorrência pulada: sem 3-dots menu', (tester) async {
      await _seedVeiculo(db);
      final despesaId = await _seedDespesa(db);
      final hoje = DateTime.now();
      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(
          hoje.year,
          hoje.month,
          hoje.day,
        ).subtract(const Duration(days: 5)),
        status: StatusOcorrencia.pulada,
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.byIcon(Icons.more_vert), findsNothing);
      await _teardownUI(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Ação "Pular"
  // -------------------------------------------------------------------------
  group('ação "Pular"', () {
    testWidgets('pular muda chip para "Pulada" e remove menu', (tester) async {
      await _seedVeiculo(db);
      final despesaId = await _seedDespesa(db, nome: 'Lavagem');
      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2099, 2, 1),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      // Abre menu e toca em Pular
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pular'));
      await tester.pumpAndSettle();

      expect(find.text('Pulada'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsNothing);
      await _teardownUI(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Ação "Marcar paga" — dialog
  // -------------------------------------------------------------------------
  group('ação "Marcar paga"', () {
    testWidgets('dialog abre com valor pré-preenchido = valor da despesa', (
      tester,
    ) async {
      await _seedVeiculo(db);
      final despesaId = await _seedDespesa(db, valor: 250.0);
      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2099, 3, 1),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcar paga'));
      await tester.pumpAndSettle();

      // Título do dialog
      expect(find.text('Marcar como paga'), findsOneWidget);
      // Valor pré-preenchido: 250,00 (formato pt-BR)
      expect(find.text('250,00'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('confirmar marcar paga muda chip para "Paga"', (tester) async {
      await _seedVeiculo(db);
      final despesaId = await _seedDespesa(db, valor: 300.0);
      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2099, 3, 15),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      // Abre menu e aciona "Marcar paga"
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcar paga'));
      await tester.pumpAndSettle();

      // Confirma sem alterar o valor
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(find.text('Paga'), findsOneWidget);
      // Após pagar, o menu 3-dots deve mostrar "Editar valor pago"
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('Editar valor pago'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('cancelar no dialog não altera o status', (tester) async {
      await _seedVeiculo(db);
      final despesaId = await _seedDespesa(db);
      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2099, 4, 1),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcar paga'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Status deve continuar "Pendente"
      expect(find.text('Pendente'), findsOneWidget);
      expect(find.text('Paga'), findsNothing);
      await _teardownUI(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Ação "Editar valor pago"
  // -------------------------------------------------------------------------
  group('ação "Editar valor pago"', () {
    testWidgets('dialog abre com valor atual pré-preenchido', (tester) async {
      await _seedVeiculo(db);
      final despesaId = await _seedDespesa(db);
      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2099, 5, 1),
        status: StatusOcorrencia.paga,
        valorPago: 175.50,
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar valor pago'));
      await tester.pumpAndSettle();

      expect(find.text('Editar valor pago'), findsWidgets);
      // Valor pré-preenchido: 175,50
      expect(find.text('175,50'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('confirmar editar valor persiste novo valor no DAO', (
      tester,
    ) async {
      await _seedVeiculo(db);
      final despesaId = await _seedDespesa(db);
      final ocorrenciaId = await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2099, 5, 15),
        status: StatusOcorrencia.paga,
        valorPago: 100.0,
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar valor pago'));
      await tester.pumpAndSettle();

      // Limpa e digita novo valor
      final textField = find.byType(TextField);
      await tester.enterText(textField, '200,00');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      // Verifica persistência diretamente no DAO
      final o = (await db.ocorrenciasDespesaDao.byId(ocorrenciaId))!;
      expect(o.valorPago, 200.0);
      await _teardownUI(tester);
    });

    testWidgets('cancelar não altera valor pago', (tester) async {
      await _seedVeiculo(db);
      final despesaId = await _seedDespesa(db);
      final ocorrenciaId = await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2099, 6, 1),
        status: StatusOcorrencia.paga,
        valorPago: 333.0,
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar valor pago'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      final o = (await db.ocorrenciasDespesaDao.byId(ocorrenciaId))!;
      expect(o.valorPago, 333.0);
      await _teardownUI(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Formatação pt-BR
  // -------------------------------------------------------------------------
  group('formatação pt-BR', () {
    testWidgets('data exibida como dd/MM/yyyy', (tester) async {
      await _seedVeiculo(db);
      final despesaId = await _seedDespesa(db);
      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2027, 8, 5),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.textContaining('05/08/2027'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('valor exibido com separador brasileiro', (tester) async {
      await _seedVeiculo(db);
      final despesaId = await _seedDespesa(db, valor: 1500.75);
      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2027, 9, 1),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      // _fmtMoney(1500.75) = "1.500,75"
      expect(find.textContaining('R\$ 1.500,75'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('cabeçalho de mês capitalizado em pt-BR', (tester) async {
      await _seedVeiculo(db);
      final despesaId = await _seedDespesa(db);
      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2027, 1, 15),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      // "Janeiro 2027" — capitalizado
      expect(find.textContaining('Janeiro 2027'), findsOneWidget);
      await _teardownUI(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Textos em pt-BR
  // -------------------------------------------------------------------------
  group('textos em pt-BR', () {
    testWidgets('AppBar exibe título "Despesas"', (tester) async {
      await _seedVeiculo(db);
      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.text('Despesas'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('FAB label exibe "Nova despesa"', (tester) async {
      await _seedVeiculo(db);
      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      // "Nova despesa" aparece no FAB e também no botão CTA da lista vazia.
      expect(find.text('Nova despesa'), findsWidgets);
      await _teardownUI(tester);
    });

    testWidgets('chip de status paga exibe "Paga"', (tester) async {
      await _seedVeiculo(db);
      final despesaId = await _seedDespesa(db);
      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2099, 10, 1),
        status: StatusOcorrencia.paga,
        valorPago: 100.0,
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.text('Paga'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('chip de status pulada exibe "Pulada"', (tester) async {
      await _seedVeiculo(db);
      final despesaId = await _seedDespesa(db);
      final hoje = DateTime.now();
      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(
          hoje.year,
          hoje.month,
          hoje.day,
        ).subtract(const Duration(days: 3)),
        status: StatusOcorrencia.pulada,
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.text('Pulada'), findsOneWidget);
      await _teardownUI(tester);
    });
  });
}
