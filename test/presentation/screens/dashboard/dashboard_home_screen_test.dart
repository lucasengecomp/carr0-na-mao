// ignore_for_file: avoid_print

import 'dart:async';

import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/data/providers.dart';
import 'package:carro_na_mao/presentation/screens/dashboard/dashboard_home_screen.dart';
import 'package:carro_na_mao/presentation/screens/dashboard/dashboard_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _placa = 'ABC1D23';
const _placa2 = 'XYZ9A99';

VeiculosCompanion _novoVeiculo({String placa = _placa, String? apelido}) =>
    VeiculosCompanion.insert(
      placa: placa,
      apelido: Value(apelido),
      marca: 'Fiat',
      modelo: 'Uno',
      ano: 2020,
      tipo: TipoVeiculo.carro,
      combustivel: TipoCombustivelVeiculo.flex,
      kmInicial: 10000,
    );

Lembrete _makeLembrete({
  int id = 1,
  String placa = _placa,
  required String descricao,
  DateTime? dataAlvo,
  int? kmAlvo,
  StatusLembrete status = StatusLembrete.pendente,
}) => Lembrete(
  id: id,
  veiculoPlaca: placa,
  tipo: 'avulso',
  descricao: descricao,
  dataAlvo: dataAlvo,
  kmAlvo: kmAlvo,
  status: status,
);

/// Avança o pump por vários frames para permitir streams resolverem.
Future<void> _advance(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Desmonta o widget tree e drena timers pendentes do Drift.
Future<void> _teardownUi(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

/// Monta o DashboardHomeScreen com rotas stub para /veiculos/novo, /comparador
/// e /config, para que os botões de navegação não falhem.
Future<void> _pumpDashboard(
  WidgetTester tester,
  AppDatabase db, {
  String? placaAtiva,
}) async {
  SharedPreferences.setMockInitialValues(
    placaAtiva != null ? {'veiculo_selecionado_placa': placaAtiva} : {},
  );
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardHomeScreen(),
      ),
      GoRoute(
        path: '/veiculos/novo',
        builder: (context, state) =>
            const Scaffold(body: Text('ROTA_VEICULOS_NOVO')),
      ),
      GoRoute(
        path: '/comparador',
        builder: (context, state) =>
            const Scaffold(body: Text('ROTA_COMPARADOR')),
      ),
      GoRoute(
        path: '/config',
        builder: (context, state) => const Scaffold(body: Text('ROTA_CONFIG')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await _advance(tester);
}

/// Converte um AsyncValue em Stream correspondente:
///   AsyncData(v)       → Stream.value(v)
///   AsyncError(e, st)  → Stream.error(e, st)
///   AsyncLoading()     → StreamController não fechado (loading)
Stream<T> _asyncToStream<T>(AsyncValue<T> av) {
  if (av is AsyncData<T>) return Stream.value(av.value);
  if (av is AsyncError<T>) return Stream.error(av.error, av.stackTrace);
  // AsyncLoading: stream que nunca emite
  return StreamController<T>().stream;
}

/// Finder que encontra um RichText cujo texto plano contém [substring].
Finder _richTextContaining(String substring) {
  return find.byWidgetPredicate(
    (w) => w is RichText && w.text.toPlainText().contains(substring),
  );
}

/// Monta o DashboardHomeScreen com overrides explícitos dos 4 providers de
/// dashboard. Útil para testar a renderização do widget sem dependência do
/// estado dos providers de dados.
Future<void> _pumpDashboardWithOverrides(
  WidgetTester tester,
  AppDatabase db, {
  required AsyncValue<CustoMensalResult?> custoMensal,
  required AsyncValue<CustoPorKmResult?> custoPorKm,
  required AsyncValue<ConsumoMedioResult?> consumoMedio,
  required AsyncValue<List<Lembrete>?> proximasManutencoes,
  String? placaAtiva,
}) async {
  SharedPreferences.setMockInitialValues(
    placaAtiva != null ? {'veiculo_selecionado_placa': placaAtiva} : {},
  );
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardHomeScreen(),
      ),
      GoRoute(
        path: '/veiculos/novo',
        builder: (context, state) =>
            const Scaffold(body: Text('ROTA_VEICULOS_NOVO')),
      ),
      GoRoute(
        path: '/comparador',
        builder: (context, state) =>
            const Scaffold(body: Text('ROTA_COMPARADOR')),
      ),
      GoRoute(
        path: '/config',
        builder: (context, state) => const Scaffold(body: Text('ROTA_CONFIG')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        custoMensalProvider.overrideWith((_) => _asyncToStream(custoMensal)),
        custoPorKmProvider.overrideWith((_) => _asyncToStream(custoPorKm)),
        consumoMedioProvider.overrideWith((_) => _asyncToStream(consumoMedio)),
        proximasManutencoeProvider.overrideWith(
          (_) => _asyncToStream(proximasManutencoes),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await _advance(tester);
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

  // =========================================================================
  // Estado: sem veículo cadastrado
  // =========================================================================

  group('DashboardHomeScreen — sem veículo', () {
    testWidgets('exibe título padrão e CTA de cadastro', (tester) async {
      await _pumpDashboard(tester, db);

      expect(find.text('Carro na Mão'), findsOneWidget);
      expect(find.text('Nenhum veículo cadastrado.'), findsOneWidget);
      expect(find.text('Cadastrar veículo'), findsOneWidget);

      await _teardownUi(tester);
    });

    testWidgets('não exibe os 4 cards quando não há veículo', (tester) async {
      await _pumpDashboard(tester, db);

      expect(find.text('Custo total no mês'), findsNothing);
      expect(find.text('Custo por km'), findsNothing);
      expect(find.text('Consumo médio'), findsNothing);
      expect(find.text('Próximas manutenções'), findsNothing);

      await _teardownUi(tester);
    });

    testWidgets('botão Cadastrar veículo navega para /veiculos/novo', (
      tester,
    ) async {
      await _pumpDashboard(tester, db);

      await tester.tap(find.text('Cadastrar veículo'));
      await _advance(tester);

      expect(find.text('ROTA_VEICULOS_NOVO'), findsOneWidget);

      await _teardownUi(tester);
    });
  });

  // =========================================================================
  // 4 cards renderizam com dados válidos (via overrides)
  // =========================================================================

  group('DashboardHomeScreen — 4 cards presentes com dados', () {
    testWidgets('renderiza os 4 títulos de card', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await _pumpDashboardWithOverrides(
        tester,
        db,
        placaAtiva: _placa,
        custoMensal: const AsyncData(CustoMensalResult(total: 1234.56)),
        custoPorKm: const AsyncData(CustoPorKmResult(custoPorKm: 0.45)),
        consumoMedio: const AsyncData(ConsumoMedioResult(kmPorLitro: 12.5)),
        proximasManutencoes: const AsyncData([]),
      );

      expect(find.text('Custo total no mês'), findsOneWidget);
      expect(find.text('Custo por km'), findsOneWidget);
      expect(find.text('Consumo médio'), findsOneWidget);
      expect(find.text('Próximas manutenções'), findsOneWidget);

      await _teardownUi(tester);
    });

    testWidgets('card custo mensal exibe valor formatado em R\$', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await _pumpDashboardWithOverrides(
        tester,
        db,
        placaAtiva: _placa,
        custoMensal: const AsyncData(CustoMensalResult(total: 1234.56)),
        custoPorKm: const AsyncData(null),
        consumoMedio: const AsyncData(null),
        proximasManutencoes: const AsyncData([]),
      );

      // Espera formatação pt-BR: R$ 1.234,56
      expect(find.textContaining('1.234,56'), findsOneWidget);

      await _teardownUi(tester);
    });

    testWidgets('card custo/km exibe valor com sufixo /km', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await _pumpDashboardWithOverrides(
        tester,
        db,
        placaAtiva: _placa,
        custoMensal: const AsyncData(CustoMensalResult(total: 0)),
        custoPorKm: const AsyncData(CustoPorKmResult(custoPorKm: 0.45)),
        consumoMedio: const AsyncData(null),
        proximasManutencoes: const AsyncData([]),
      );

      // _CustoPorKmCard usa RichText com TextSpan — buscar em texto plano
      expect(_richTextContaining('0,45'), findsAtLeastNWidgets(1));
      expect(_richTextContaining('/km'), findsAtLeastNWidgets(1));

      await _teardownUi(tester);
    });

    testWidgets('card consumo médio exibe valor com sufixo km/l', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await _pumpDashboardWithOverrides(
        tester,
        db,
        placaAtiva: _placa,
        custoMensal: const AsyncData(CustoMensalResult(total: 0)),
        custoPorKm: const AsyncData(null),
        consumoMedio: const AsyncData(ConsumoMedioResult(kmPorLitro: 12.5)),
        proximasManutencoes: const AsyncData([]),
      );

      // _ConsumoMedioCard usa RichText com TextSpan — buscar em texto plano
      expect(_richTextContaining('12,5'), findsAtLeastNWidgets(1));
      expect(_richTextContaining(' km/l'), findsAtLeastNWidgets(1));

      await _teardownUi(tester);
    });
  });

  // =========================================================================
  // Placeholder quando dados insuficientes
  // =========================================================================

  group('DashboardHomeScreen — placeholders', () {
    testWidgets('card custo/km mostra placeholder quando null', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await _pumpDashboardWithOverrides(
        tester,
        db,
        placaAtiva: _placa,
        custoMensal: const AsyncData(CustoMensalResult(total: 0)),
        custoPorKm: const AsyncData(null),
        consumoMedio: const AsyncData(null),
        proximasManutencoes: const AsyncData([]),
      );

      // O texto "Dados insuficientes" deve aparecer 2x (custo/km + consumo médio)
      expect(find.text('Dados insuficientes'), findsNWidgets(2));

      await _teardownUi(tester);
    });

    testWidgets('card consumo médio mostra placeholder quando null', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await _pumpDashboardWithOverrides(
        tester,
        db,
        placaAtiva: _placa,
        custoMensal: const AsyncData(CustoMensalResult(total: 0)),
        custoPorKm: const AsyncData(CustoPorKmResult(custoPorKm: 0.5)),
        consumoMedio: const AsyncData(null),
        proximasManutencoes: const AsyncData([]),
      );

      expect(find.text('Dados insuficientes'), findsOneWidget);

      await _teardownUi(tester);
    });

    testWidgets(
      'card próximas manutenções mostra placeholder quando lista vazia',
      (tester) async {
        await db.veiculosDao.insertVeiculo(_novoVeiculo());
        await _pumpDashboardWithOverrides(
          tester,
          db,
          placaAtiva: _placa,
          custoMensal: const AsyncData(CustoMensalResult(total: 0)),
          custoPorKm: const AsyncData(null),
          consumoMedio: const AsyncData(null),
          proximasManutencoes: const AsyncData([]),
        );

        expect(find.text('Sem lembretes pendentes'), findsOneWidget);

        await _teardownUi(tester);
      },
    );

    testWidgets('card próximas manutenções mostra placeholder quando null', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await _pumpDashboardWithOverrides(
        tester,
        db,
        placaAtiva: _placa,
        custoMensal: const AsyncData(CustoMensalResult(total: 0)),
        custoPorKm: const AsyncData(null),
        consumoMedio: const AsyncData(null),
        proximasManutencoes: const AsyncData(null),
      );

      expect(find.text('Sem lembretes pendentes'), findsOneWidget);

      await _teardownUi(tester);
    });
  });

  // =========================================================================
  // Estado de erro
  // =========================================================================

  group('DashboardHomeScreen — estado de erro', () {
    testWidgets(
      'card custo mensal exibe mensagem de erro quando provider falha',
      (tester) async {
        await db.veiculosDao.insertVeiculo(_novoVeiculo());
        final erro = Exception('falha de leitura');
        SharedPreferences.setMockInitialValues({
          'veiculo_selecionado_placa': _placa,
        });

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardHomeScreen(),
            ),
            GoRoute(
              path: '/veiculos/novo',
              builder: (context, state) => const Scaffold(),
            ),
            GoRoute(
              path: '/comparador',
              builder: (context, state) => const Scaffold(),
            ),
            GoRoute(
              path: '/config',
              builder: (context, state) => const Scaffold(),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              custoMensalProvider.overrideWith(
                (_) => Stream<CustoMensalResult?>.error(erro, StackTrace.empty),
              ),
              custoPorKmProvider.overrideWith((_) => Stream.value(null)),
              consumoMedioProvider.overrideWith((_) => Stream.value(null)),
              proximasManutencoeProvider.overrideWith(
                (_) => Stream<List<Lembrete>?>.value([]),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        // pumpAndSettle aguarda todos os microtasks e frames (incluindo stream events)
        await tester.pumpAndSettle(const Duration(milliseconds: 100));

        // O card deve exibir texto de erro — Riverpod recebe o erro da stream
        expect(
          find.byWidgetPredicate(
            (w) => w is Text && (w.data?.startsWith('Erro:') ?? false),
          ),
          findsOneWidget,
        );

        await _teardownUi(tester);
      },
    );
  });

  // =========================================================================
  // Card 4 — lembretes pendentes listados
  // =========================================================================

  group('DashboardHomeScreen — card próximas manutenções com dados', () {
    testWidgets('exibe até 3 lembretes no card', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      // Cria 3 lembretes para passar ao provider override
      final l1 = _makeLembrete(
        id: 1,
        descricao: 'Troca de óleo',
        dataAlvo: DateTime(2027, 1, 1),
      );
      final l2 = _makeLembrete(
        id: 2,
        descricao: 'Revisão freios',
        dataAlvo: DateTime(2027, 2, 1),
      );
      final l3 = _makeLembrete(
        id: 3,
        descricao: 'Alinhamento',
        dataAlvo: DateTime(2027, 3, 1),
      );

      await _pumpDashboardWithOverrides(
        tester,
        db,
        placaAtiva: _placa,
        custoMensal: const AsyncData(CustoMensalResult(total: 0)),
        custoPorKm: const AsyncData(null),
        consumoMedio: const AsyncData(null),
        proximasManutencoes: AsyncData([l1, l2, l3]),
      );

      expect(find.text('Troca de óleo'), findsOneWidget);
      expect(find.text('Revisão freios'), findsOneWidget);
      expect(find.text('Alinhamento'), findsOneWidget);

      await _teardownUi(tester);
    });

    testWidgets('lembrete exibe data formatada dd/MM/aaaa', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      final lembrete = _makeLembrete(
        id: 1,
        descricao: 'Troca de óleo',
        dataAlvo: DateTime(2027, 3, 15),
      );

      await _pumpDashboardWithOverrides(
        tester,
        db,
        placaAtiva: _placa,
        custoMensal: const AsyncData(CustoMensalResult(total: 0)),
        custoPorKm: const AsyncData(null),
        consumoMedio: const AsyncData(null),
        proximasManutencoes: AsyncData([lembrete]),
      );

      // Data 15/03/2027
      expect(find.textContaining('15/03/2027'), findsOneWidget);

      await _teardownUi(tester);
    });
  });

  // =========================================================================
  // Ações da AppBar
  // =========================================================================

  group('DashboardHomeScreen — AppBar', () {
    testWidgets('botão comparador navega para /comparador', (tester) async {
      await _pumpDashboard(tester, db);

      await tester.tap(find.byTooltip('Comparador'));
      await _advance(tester);

      expect(find.text('ROTA_COMPARADOR'), findsOneWidget);

      await _teardownUi(tester);
    });

    testWidgets('botão configurações navega para /config', (tester) async {
      await _pumpDashboard(tester, db);

      await tester.tap(find.byTooltip('Configurações'));
      await _advance(tester);

      expect(find.text('ROTA_CONFIG'), findsOneWidget);

      await _teardownUi(tester);
    });

    testWidgets('sem veículos: título é "Carro na Mão" sem seletor', (
      tester,
    ) async {
      await _pumpDashboard(tester, db);

      expect(find.text('Carro na Mão'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);

      await _teardownUi(tester);
    });

    testWidgets('com 1 veículo: título é "Carro na Mão" sem seletor dropdown', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo(apelido: 'Uninho'));
      await _pumpDashboard(tester, db, placaAtiva: _placa);

      expect(find.text('Carro na Mão'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);

      await _teardownUi(tester);
    });

    testWidgets('com 2 veículos: exibe seletor dropdown', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo(apelido: 'Uninho'));
      await db.veiculosDao.insertVeiculo(
        _novoVeiculo(placa: _placa2, apelido: 'Mobinho'),
      );
      await _pumpDashboard(tester, db, placaAtiva: _placa);

      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);

      await _teardownUi(tester);
    });
  });

  // =========================================================================
  // Layout responsivo
  // =========================================================================

  group('DashboardHomeScreen — layout responsivo', () {
    testWidgets('tela larga (800x600 dp): exibe os 4 cards sem overflow', (
      tester,
    ) async {
      // 800x600 logical pixels → grid 2x2
      tester.view.physicalSize = const Size(800 * 3, 600 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await _pumpDashboardWithOverrides(
        tester,
        db,
        placaAtiva: _placa,
        custoMensal: const AsyncData(CustoMensalResult(total: 500)),
        custoPorKm: const AsyncData(CustoPorKmResult(custoPorKm: 0.5)),
        consumoMedio: const AsyncData(ConsumoMedioResult(kmPorLitro: 10.0)),
        proximasManutencoes: const AsyncData([]),
      );

      // Todos os 4 títulos presentes em tela larga
      expect(find.text('Custo total no mês'), findsOneWidget);
      expect(find.text('Custo por km'), findsOneWidget);
      expect(find.text('Consumo médio'), findsOneWidget);
      expect(find.text('Próximas manutenções'), findsOneWidget);

      // Nenhum overflow
      expect(tester.takeException(), isNull);

      await _teardownUi(tester);
    });

    testWidgets(
      'tela estreita (320x600 dp): exibe os 4 cards em coluna única',
      (tester) async {
        // 320x600 logical pixels → coluna única (< 500 dp)
        tester.view.physicalSize = const Size(320 * 3, 600 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await db.veiculosDao.insertVeiculo(_novoVeiculo());
        await _pumpDashboardWithOverrides(
          tester,
          db,
          placaAtiva: _placa,
          custoMensal: const AsyncData(CustoMensalResult(total: 500)),
          custoPorKm: const AsyncData(null),
          consumoMedio: const AsyncData(null),
          proximasManutencoes: const AsyncData([]),
        );

        expect(find.text('Custo total no mês'), findsOneWidget);
        expect(find.text('Custo por km'), findsOneWidget);
        expect(find.text('Consumo médio'), findsOneWidget);
        expect(find.text('Próximas manutenções'), findsOneWidget);

        expect(tester.takeException(), isNull);

        await _teardownUi(tester);
      },
    );
  });

  // =========================================================================
  // Formatação de moeda (R$) e data (dd/MM/aaaa) — pt-BR
  // =========================================================================

  group('DashboardHomeScreen — formatação pt-BR', () {
    testWidgets('custo zero formata como R\$ 0,00', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await _pumpDashboardWithOverrides(
        tester,
        db,
        placaAtiva: _placa,
        custoMensal: const AsyncData(CustoMensalResult(total: 0.0)),
        custoPorKm: const AsyncData(null),
        consumoMedio: const AsyncData(null),
        proximasManutencoes: const AsyncData([]),
      );

      expect(find.textContaining('0,00'), findsOneWidget);

      await _teardownUi(tester);
    });

    testWidgets('custo maior que 1000 usa separador de milhar com ponto', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await _pumpDashboardWithOverrides(
        tester,
        db,
        placaAtiva: _placa,
        custoMensal: const AsyncData(CustoMensalResult(total: 2500.00)),
        custoPorKm: const AsyncData(null),
        consumoMedio: const AsyncData(null),
        proximasManutencoes: const AsyncData([]),
      );

      // pt-BR: 2500.00 → "2.500,00"
      expect(find.textContaining('2.500,00'), findsOneWidget);

      await _teardownUi(tester);
    });

    testWidgets('consumo médio usa vírgula como separador decimal', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await _pumpDashboardWithOverrides(
        tester,
        db,
        placaAtiva: _placa,
        custoMensal: const AsyncData(CustoMensalResult(total: 0)),
        custoPorKm: const AsyncData(null),
        consumoMedio: const AsyncData(ConsumoMedioResult(kmPorLitro: 12.3)),
        proximasManutencoes: const AsyncData([]),
      );

      // _ConsumoMedioCard usa RichText — buscar em texto plano
      expect(_richTextContaining('12,3'), findsAtLeastNWidgets(1));

      await _teardownUi(tester);
    });
  });

  // =========================================================================
  // Troca de veículo re-dispara streams (integração básica com DB real)
  // =========================================================================

  group('DashboardHomeScreen — troca de veículo', () {
    testWidgets('com 2 veículos: seletor dropdown aparece e permite trocar', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo(apelido: 'Uninho'));
      await db.veiculosDao.insertVeiculo(
        _novoVeiculo(placa: _placa2, apelido: 'Mobinho'),
      );

      // Inicia com _placa selecionado
      await _pumpDashboard(tester, db, placaAtiva: _placa);

      // Seletor presente
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);

      // Abre dropdown e seleciona Mobinho
      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await _advance(tester);
      await tester.tap(find.text('Mobinho').last);
      await _advance(tester);

      // Após a troca, o título exibe o apelido do novo veículo
      expect(find.text('Mobinho'), findsOneWidget);

      // Preferência persistida
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('veiculo_selecionado_placa'), _placa2);

      await _teardownUi(tester);
    });
  });
}
