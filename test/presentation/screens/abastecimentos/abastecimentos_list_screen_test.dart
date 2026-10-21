import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/data/providers.dart';
import 'package:carro_na_mao/presentation/screens/abastecimentos/abastecimentos_list_providers.dart';
import 'package:carro_na_mao/presentation/screens/abastecimentos/abastecimentos_list_screen.dart';
import 'package:carro_na_mao/services/abastecimentos_service.dart';
import 'package:carro_na_mao/services/lembretes_service.dart';
import 'package:carro_na_mao/services/notifications_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../helpers/l10n_delegates.dart';

// ---------------------------------------------------------------------------
// Fake plugin — mesma estrutura do abastecimentos_service_test.dart
// ---------------------------------------------------------------------------
class _FakePlugin implements NotificationsPluginInterface {
  @override
  Future<void> initialize(InitializationSettings settings) async {}

  @override
  Future<void> createAndroidChannel(AndroidNotificationChannel channel) async {}

  @override
  Future<bool?> requestAndroidPermission() async => true;

  @override
  Future<bool?> requestIosPermission({
    bool alert = true,
    bool badge = true,
    bool sound = true,
  }) async => null;

  @override
  Future<void> zonedSchedule({
    required int id,
    required String? title,
    required String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required AndroidScheduleMode androidScheduleMode,
  }) async {}

  @override
  Future<void> show({
    required int id,
    required String? title,
    required String? body,
    required NotificationDetails details,
  }) async {}

  @override
  Future<void> cancel(int id) async {}
}

// Subclasse que simula falha no banco ao excluir — usada para confirmar que
// _AbastecimentoMenu não trata erros de deleteAbastecimento (bug #issue).
class _AbastecimentosServiceQueFalha extends AbastecimentosService {
  _AbastecimentosServiceQueFalha({
    required super.dao,
    required super.lembretesService,
    required super.notifications,
  });

  @override
  Future<int> deleteAbastecimento(int id) async {
    throw Exception('Falha simulada no banco de dados');
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

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

AbastecimentosCompanion _novoAbast({
  String placa = 'ABC1D23',
  required DateTime data,
  required int km,
  double litros = 40,
  double precoLitro = 6,
  double valorTotal = 240,
  String? posto,
  TipoCombustivelAbastecimento combustivel =
      TipoCombustivelAbastecimento.gasolina,
}) => AbastecimentosCompanion.insert(
  veiculoPlaca: placa,
  data: data,
  km: km,
  tipoCombustivel: combustivel,
  precoLitro: precoLitro,
  valorTotal: valorTotal,
  litros: litros,
  posto: Value(posto),
);

/// Monta a tela com um GoRouter mínimo para suportar navegação.
/// Registra também as rotas de edição para testar toque na linha.
Future<void> _pumpScreen(
  WidgetTester tester, {
  required AppDatabase db,
  String? placaAtiva,
}) async {
  SharedPreferences.setMockInitialValues(
    placaAtiva == null ? {} : {'veiculo_selecionado_placa': placaAtiva},
  );

  final router = GoRouter(
    initialLocation: '/abastecimentos',
    routes: [
      GoRoute(
        path: '/abastecimentos',
        builder: (c, s) => const AbastecimentosListScreen(),
      ),
      GoRoute(
        path: '/abastecimentos/novo',
        builder: (c, s) =>
            const Scaffold(body: Text('TELA_NOVO_ABASTECIMENTO')),
      ),
      GoRoute(
        path: '/abastecimentos/:id/editar',
        builder: (c, s) =>
            Scaffold(body: Text('TELA_EDITAR_${s.pathParameters["id"]}')),
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
  // Aguarda stream inicial resolver
  await tester.pumpAndSettle();
}

/// Desmonta o widget tree e drena timers do Drift.
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
  // Estado sem veículo selecionado
  // -------------------------------------------------------------------------
  group('sem veículo cadastrado', () {
    testWidgets('exibe CTA de cadastro de veículo', (tester) async {
      await _pumpScreen(tester, db: db);

      expect(find.textContaining('Cadastre um veículo'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      await _teardownUI(tester);
    });

    testWidgets('botão Cadastrar veículo navega para /veiculos/novo', (
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
  // Lista vazia (veículo cadastrado, sem abastecimentos)
  // -------------------------------------------------------------------------
  group('veículo cadastrado, sem abastecimentos', () {
    testWidgets('exibe mensagem de lista vazia e FAB', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.textContaining('Nenhum abastecimento'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('FAB navega para /abastecimentos/novo', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('TELA_NOVO_ABASTECIMENTO'), findsOneWidget);
      await _teardownUI(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Lista com itens — cabeçalhos por mês e ordem desc
  // -------------------------------------------------------------------------
  group('lista com itens de meses diferentes', () {
    testWidgets('exibe cabeçalhos de mês para meses distintos', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      // Abastecimentos em março e janeiro de 2026
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: DateTime(2026, 3, 15), km: 300),
      );
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: DateTime(2026, 1, 10), km: 100),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.text('Março 2026'), findsOneWidget);
      expect(find.text('Janeiro 2026'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('itens do mesmo mês compartilham o mesmo cabeçalho', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: DateTime(2026, 3, 15), km: 300),
      );
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: DateTime(2026, 3, 5), km: 200),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      // Apenas um cabeçalho de março
      expect(find.text('Março 2026'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets(
      'cabeçalhos aparecem em ordem descendente (mês mais recente primeiro)',
      (tester) async {
        await db.veiculosDao.insertVeiculo(_novoVeiculo());
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(data: DateTime(2026, 1, 10), km: 100),
        );
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(data: DateTime(2026, 3, 15), km: 300),
        );

        await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

        final marcoPos = tester.getTopLeft(find.text('Março 2026')).dy;
        final janeiroPos = tester.getTopLeft(find.text('Janeiro 2026')).dy;

        // Março (mais recente) deve aparecer acima de Janeiro
        expect(marcoPos, lessThan(janeiroPos));
        await _teardownUI(tester);
      },
    );

    testWidgets('linha exibe data formatada dd/mm/aaaa', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: DateTime(2026, 3, 5), km: 200),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.textContaining('05/03/2026'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('linha exibe valor em R\$', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: DateTime(2026, 3, 5), km: 200, valorTotal: 300),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.textContaining('R\$'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('linha exibe posto quando informado', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: DateTime(2026, 3, 5), km: 200, posto: 'Shell Centro'),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.textContaining('Shell Centro'), findsOneWidget);
      await _teardownUI(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Filtros de período (FilterChips)
  // -------------------------------------------------------------------------
  group('filtros de período', () {
    testWidgets('chip "Tudo" está selecionado por padrão', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      // O FilterChip "Tudo" deve estar selecionado inicialmente
      final chips = tester.widgetList<FilterChip>(find.byType(FilterChip));
      final todoChip = chips.firstWhere(
        (c) => (c.label as Text).data == 'Tudo',
      );
      expect(todoChip.selected, isTrue);
      await _teardownUI(tester);
    });

    testWidgets('todos os quatro chips de período são exibidos', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.text('Últimos 30d'), findsOneWidget);
      expect(find.text('Últimos 90d'), findsOneWidget);
      expect(find.text('Últimos 12m'), findsOneWidget);
      expect(find.text('Tudo'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('tocar chip de período atualiza seleção', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.tap(find.text('Últimos 30d'));
      await tester.pumpAndSettle();

      final chips = tester.widgetList<FilterChip>(find.byType(FilterChip));
      final chip30d = chips.firstWhere(
        (c) => (c.label as Text).data == 'Últimos 30d',
      );
      final chipTudo = chips.firstWhere(
        (c) => (c.label as Text).data == 'Tudo',
      );

      expect(chip30d.selected, isTrue);
      expect(chipTudo.selected, isFalse);
      await _teardownUI(tester);
    });

    testWidgets('filtro 30d oculta abastecimento mais antigo que 30 dias', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      final dataAntiga = DateTime.now().subtract(const Duration(days: 60));
      final dataRecente = DateTime.now().subtract(const Duration(days: 5));

      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: dataAntiga, km: 100, posto: 'PostoAntigo'),
      );
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: dataRecente, km: 200, posto: 'PostoRecente'),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      // Seleciona filtro de 30 dias
      await tester.tap(find.text('Últimos 30d'));
      await tester.pumpAndSettle();

      expect(find.textContaining('PostoRecente'), findsOneWidget);
      expect(find.textContaining('PostoAntigo'), findsNothing);
      await _teardownUI(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Filtros de combustível (multi-select chips — issue #77)
  // -------------------------------------------------------------------------
  group('filtros de combustível multi-select', () {
    testWidgets('todos os chips de combustível estão selecionados por padrão', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      // Estado inicial: tiposCombustivel=null → todos selecionados.
      final chips = tester.widgetList<FilterChip>(find.byType(FilterChip));
      final combustivelChips = chips
          .where(
            (c) =>
                (c.label as Text).data != 'Tudo' &&
                (c.label as Text).data != 'Últimos 30d' &&
                (c.label as Text).data != 'Últimos 90d' &&
                (c.label as Text).data != 'Últimos 12m',
          )
          .toList();
      expect(combustivelChips.every((c) => c.selected), isTrue);
      await _teardownUI(tester);
    });

    testWidgets(
      '1 chip selecionado (outros desmarcados) oculta outros combustíveis',
      (tester) async {
        await db.veiculosDao.insertVeiculo(_novoVeiculo());
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(2026, 3, 1),
            km: 100,
            combustivel: TipoCombustivelAbastecimento.gasolina,
            posto: 'PostoGas',
          ),
        );
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(2026, 3, 2),
            km: 200,
            combustivel: TipoCombustivelAbastecimento.alcool,
            posto: 'PostoAlc',
          ),
        );
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(2026, 3, 3),
            km: 300,
            combustivel: TipoCombustivelAbastecimento.diesel,
            posto: 'PostoDiesel',
          ),
        );

        await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

        // Desmarca Álcool, Diesel, GNV, Elétrico → só Gasolina fica.
        await tester.tap(find.text('Álcool'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Diesel'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('GNV'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Elétrico'));
        await tester.pumpAndSettle();

        expect(find.textContaining('PostoGas'), findsOneWidget);
        expect(find.textContaining('PostoAlc'), findsNothing);
        expect(find.textContaining('PostoDiesel'), findsNothing);
        await _teardownUI(tester);
      },
    );

    testWidgets(
      '2 chips selecionados exibem os dois combustíveis (flex use case)',
      (tester) async {
        await db.veiculosDao.insertVeiculo(_novoVeiculo());
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(2026, 3, 1),
            km: 100,
            combustivel: TipoCombustivelAbastecimento.gasolina,
            posto: 'PostoGas',
          ),
        );
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(2026, 3, 2),
            km: 200,
            combustivel: TipoCombustivelAbastecimento.alcool,
            posto: 'PostoAlc',
          ),
        );
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(2026, 3, 3),
            km: 300,
            combustivel: TipoCombustivelAbastecimento.diesel,
            posto: 'PostoDiesel',
          ),
        );

        await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

        // Desmarca tudo exceto Gasolina e Álcool.
        await tester.tap(find.text('Diesel'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('GNV'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Elétrico'));
        await tester.pumpAndSettle();

        // Gasolina e Álcool devem aparecer; Diesel não.
        expect(find.textContaining('PostoGas'), findsOneWidget);
        expect(find.textContaining('PostoAlc'), findsOneWidget);
        expect(find.textContaining('PostoDiesel'), findsNothing);
        await _teardownUI(tester);
      },
    );

    testWidgets(
      '0 chips selecionados exibe estado vazio com mensagem específica',
      (tester) async {
        await db.veiculosDao.insertVeiculo(_novoVeiculo());
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(2026, 3, 1),
            km: 100,
            combustivel: TipoCombustivelAbastecimento.gasolina,
            posto: 'PostoGas',
          ),
        );

        await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

        // Desmarca todos os chips.
        for (final label in [
          'Gasolina',
          'Álcool',
          'Diesel',
          'GNV',
          'Elétrico',
        ]) {
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
        }

        // A lista some e o estado vazio específico aparece.
        expect(find.textContaining('PostoGas'), findsNothing);
        expect(
          find.byKey(const Key('estado_nenhum_combustivel')),
          findsOneWidget,
        );
        expect(
          find.textContaining('Selecione pelo menos um combustível'),
          findsOneWidget,
        );
        await _teardownUI(tester);
      },
    );

    testWidgets('remarcar chip após 0 selecionados restaura lista', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(2026, 3, 1),
          km: 100,
          combustivel: TipoCombustivelAbastecimento.gasolina,
          posto: 'PostoGas',
        ),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      // Desmarca todos.
      for (final label in ['Gasolina', 'Álcool', 'Diesel', 'GNV', 'Elétrico']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      expect(
        find.byKey(const Key('estado_nenhum_combustivel')),
        findsOneWidget,
      );

      // Remarca Gasolina.
      await tester.tap(find.text('Gasolina'));
      await tester.pumpAndSettle();

      expect(find.textContaining('PostoGas'), findsOneWidget);
      expect(find.byKey(const Key('estado_nenhum_combustivel')), findsNothing);
      await _teardownUI(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Navegação por toque na linha
  // -------------------------------------------------------------------------
  group('navegação por toque na linha', () {
    testWidgets('toque numa linha navega para /abastecimentos/:id/editar', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      final id = await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: DateTime(2026, 3, 1), km: 100, posto: 'Shell'),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.tap(find.textContaining('Shell'));
      await tester.pumpAndSettle();

      expect(find.text('TELA_EDITAR_$id'), findsOneWidget);
      await _teardownUI(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Formatação de km e litros
  // -------------------------------------------------------------------------
  group('formatação', () {
    testWidgets('km grande é formatado com separador de milhar (ponto)', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: DateTime(2026, 3, 5), km: 123456),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.textContaining('123.456'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('litros são formatados com vírgula decimal', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: DateTime(2026, 3, 5), km: 100, litros: 40.50),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.textContaining('40,50'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('valor monetário grande é formatado com separador de milhar', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: DateTime(2026, 3, 5), km: 100, valorTotal: 1234.56),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.textContaining('1.234,56'), findsOneWidget);
      await _teardownUI(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Ação de excluir (menu 3-dots)
  // -------------------------------------------------------------------------
  group('excluir abastecimento via menu 3-dots', () {
    testWidgets('menu exibe opção "Excluir"', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      final id = await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: DateTime(2026, 3, 1), km: 100, posto: 'Shell'),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      // Abre o menu de 3 pontos do item
      await tester.tap(find.byKey(Key('menu_abastecimento_$id')));
      await tester.pumpAndSettle();

      expect(find.text('Excluir'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets('cancelar dialog NÃO exclui o registro', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      final id = await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: DateTime(2026, 3, 1), km: 100, posto: 'Shell'),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.tap(find.byKey(Key('menu_abastecimento_$id')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      // Dialog de confirmação abriu; toca em Cancelar
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(await db.abastecimentosDao.byId(id), isNotNull);
      await _teardownUI(tester);
    });

    testWidgets('confirmar exclusão remove o registro e exibe snackbar', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      final id = await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: DateTime(2026, 3, 1), km: 100, posto: 'Shell'),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.tap(find.byKey(Key('menu_abastecimento_$id')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      // Dialog abriu; toca no botão de confirmação
      await tester.tap(
        find.byKey(const Key('btn_excluir_abastecimento_confirmar')),
      );
      await tester.pumpAndSettle();

      // Registro removido do banco
      expect(await db.abastecimentosDao.byId(id), isNull);

      // Snackbar de confirmação aparece
      expect(find.text('Abastecimento excluído.'), findsOneWidget);
      await _teardownUI(tester);
    });

    testWidgets(
      'lista atualiza reativamente após exclusão (item some da tela)',
      (tester) async {
        await db.veiculosDao.insertVeiculo(_novoVeiculo());
        final id = await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(data: DateTime(2026, 3, 1), km: 100, posto: 'UnicoItem'),
        );

        await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

        expect(find.textContaining('UnicoItem'), findsOneWidget);

        await tester.tap(find.byKey(Key('menu_abastecimento_$id')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Excluir'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('btn_excluir_abastecimento_confirmar')),
        );
        await tester.pumpAndSettle();

        // Item deve sumir da lista
        expect(find.textContaining('UnicoItem'), findsNothing);
        await _teardownUI(tester);
      },
    );

    testWidgets(
      'regressão: excluir intermediário NÃO afeta demais registros na lista',
      (tester) async {
        await db.veiculosDao.insertVeiculo(_novoVeiculo());
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(data: DateTime(2026, 1, 1), km: 100, posto: 'Primeiro'),
        );
        final idMeio = await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(data: DateTime(2026, 2, 1), km: 200, posto: 'Meio'),
        );
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(data: DateTime(2026, 3, 1), km: 300, posto: 'Ultimo'),
        );

        await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

        // Exclui o intermediário
        await tester.tap(find.byKey(Key('menu_abastecimento_$idMeio')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Excluir'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('btn_excluir_abastecimento_confirmar')),
        );
        await tester.pumpAndSettle();

        // Primeiro e Ultimo ainda estão na lista
        expect(find.textContaining('Primeiro'), findsOneWidget);
        expect(find.textContaining('Ultimo'), findsOneWidget);
        expect(find.textContaining('Meio'), findsNothing);
        await _teardownUI(tester);
      },
    );
  });

  // -------------------------------------------------------------------------
  // Tratamento de erro ao excluir via menu da lista
  // -------------------------------------------------------------------------
  group('excluir abastecimento — caminho de erro', () {
    // Documenta o bug: _AbastecimentoMenu não trata exceções de
    // deleteAbastecimento — ao contrário do form screen que tem try/catch.
    testWidgets(
      '[bug] falha no banco ao excluir pela lista exibe snackbar de erro em vez de propagar exceção',
      (tester) async {
        await db.veiculosDao.insertVeiculo(_novoVeiculo());
        final id = await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(data: DateTime(2026, 3, 1), km: 100, posto: 'Shell'),
        );

        // Monta a tela com service que sempre lança ao deletar
        SharedPreferences.setMockInitialValues(const {
          'veiculo_selecionado_placa': 'ABC1D23',
        });

        final notifService = NotificationsService(plugin: _FakePlugin());
        await notifService.init();
        final lembretesService = LembretesService(
          dao: db.lembretesDao,
          notifications: notifService,
        );
        final serviceQueFalha = _AbastecimentosServiceQueFalha(
          dao: db.abastecimentosDao,
          lembretesService: lembretesService,
          notifications: notifService,
        );

        final router = GoRouter(
          initialLocation: '/abastecimentos',
          routes: [
            GoRoute(
              path: '/abastecimentos',
              builder: (c, s) => const AbastecimentosListScreen(),
            ),
            GoRoute(
              path: '/abastecimentos/novo',
              builder: (c, s) =>
                  const Scaffold(body: Text('TELA_NOVO_ABASTECIMENTO')),
            ),
            GoRoute(
              path: '/abastecimentos/:id/editar',
              builder: (c, s) =>
                  Scaffold(body: Text('TELA_EDITAR_${s.pathParameters["id"]}')),
            ),
            GoRoute(
              path: '/veiculos/novo',
              builder: (c, s) =>
                  const Scaffold(body: Text('TELA_NOVO_VEICULO')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              abastecimentosServiceProvider.overrideWithValue(serviceQueFalha),
            ],
            child: MaterialApp.router(
              locale: localeDefault,
              localizationsDelegates: l10nDelegates,
              supportedLocales: supportedLocales,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(Key('menu_abastecimento_$id')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Excluir'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('btn_excluir_abastecimento_confirmar')),
        );

        // O comportamento ESPERADO (correto) é exibir snackbar de erro, como
        // faz o form screen. O comportamento ATUAL é propagar a exceção.
        // Este teste documenta o bug: ao pumpAndSettle a exceção vai explodir.
        await tester.pumpAndSettle();

        // Se chegar aqui sem lançar, verifica se snackbar de erro aparece
        expect(
          find.textContaining('Não foi possível'),
          findsOneWidget,
          reason: 'Esperado snackbar de erro; _AbastecimentoMenu não trata exceções de deleteAbastecimento',
        );
        await _teardownUI(tester);
      },
    );
  });

  // -------------------------------------------------------------------------
  // Estado de erro
  // -------------------------------------------------------------------------
  group('estado de erro', () {
    testWidgets('quando o stream emite erro, exibe mensagem de erro', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());

      SharedPreferences.setMockInitialValues(const {
        'veiculo_selecionado_placa': 'ABC1D23',
      });

      final router = GoRouter(
        initialLocation: '/abastecimentos',
        routes: [
          GoRoute(
            path: '/abastecimentos',
            builder: (c, s) => const AbastecimentosListScreen(),
          ),
          GoRoute(
            path: '/veiculos/novo',
            builder: (c, s) => const Scaffold(body: Text('TELA_NOVO_VEICULO')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            abastecimentosFiltradosProvider.overrideWith(
              (ref, placa) =>
                  Stream<List<Abastecimento>>.error('Erro simulado'),
            ),
          ],
          child: MaterialApp.router(
            locale: localeDefault,
            localizationsDelegates: l10nDelegates,
            supportedLocales: supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Erro'), findsOneWidget);
      await _teardownUI(tester);
    });
  });
}
