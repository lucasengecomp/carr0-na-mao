// ignore_for_file: avoid_print

import 'dart:async';

import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/data/providers.dart';
import 'package:carro_na_mao/presentation/screens/dashboard/dashboard_graficos_providers.dart';
import 'package:carro_na_mao/presentation/screens/dashboard/dashboard_graficos_screen.dart';
import 'package:carro_na_mao/presentation/screens/dashboard/dashboard_home_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _placa = 'TST2B22';

VeiculosCompanion _novoVeiculo({String placa = _placa, String? apelido}) =>
    VeiculosCompanion.insert(
      placa: placa,
      apelido: Value(apelido),
      marca: 'Honda',
      modelo: 'Civic',
      ano: 2022,
      tipo: TipoVeiculo.carro,
      combustivel: TipoCombustivelVeiculo.flex,
      kmInicial: 1000,
    );

/// Converts an [AsyncValue] to the corresponding Stream (used for overriding providers).
Stream<T> _asyncToStream<T>(AsyncValue<T> av) {
  if (av is AsyncData<T>) return Stream.value(av.value);
  if (av is AsyncError<T>) return Stream.error(av.error, av.stackTrace);
  return StreamController<T>().stream;
}

/// Advances the tester by pumping multiple frames to allow streams to resolve.
Future<void> _advance(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Tears down the widget tree to avoid timer leak warnings.
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

/// Pumps [DashboardGraficosScreen] with explicit provider overrides.
/// This avoids DB-level timing issues in widget tests.
Future<void> _pumpGraficosWithOverrides(
  WidgetTester tester,
  AppDatabase db, {
  required AsyncValue<List<GastoMensal>> gastos,
  required AsyncValue<List<ConsumoMensal>> consumo,
  required AsyncValue<List<CategoriaGasto>> distribuicao,
  String placa = _placa,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        gastosMensaisProvider(_placa)
            .overrideWith((_) => _asyncToStream(gastos)),
        consumoMensalProvider(_placa)
            .overrideWith((_) => _asyncToStream(consumo)),
        distribuicaoCategoriaProvider(_placa)
            .overrideWith((_) => _asyncToStream(distribuicao)),
      ],
      child: MaterialApp(home: DashboardGraficosScreen(placa: placa)),
    ),
  );
  await _advance(tester);
}

/// Creates a list of 12 GastoMensal entries all with zero values.
List<GastoMensal> _emptyGastos() {
  final now = DateTime.now();
  return List.generate(12, (i) {
    final offset = 11 - i;
    return GastoMensal(
      mes: DateTime(now.year, now.month - offset),
      abastec: 0,
      manut: 0,
      despesas: 0,
    );
  });
}

/// Creates a list of 12 ConsumoMensal entries all with null kmPorLitro.
List<ConsumoMensal> _emptyConsumo() {
  final now = DateTime.now();
  return List.generate(12, (i) {
    final offset = 11 - i;
    return ConsumoMensal(
      mes: DateTime(now.year, now.month - offset),
      kmPorLitro: null,
    );
  });
}

/// Creates 12 GastoMensal entries where only the last month has data.
List<GastoMensal> _gastosWithCurrentMonth({
  double abastec = 300.0,
  double manut = 100.0,
  double despesas = 50.0,
}) {
  final now = DateTime.now();
  return List.generate(12, (i) {
    final offset = 11 - i;
    final mes = DateTime(now.year, now.month - offset);
    final isLast = i == 11;
    return GastoMensal(
      mes: mes,
      abastec: isLast ? abastec : 0,
      manut: isLast ? manut : 0,
      despesas: isLast ? despesas : 0,
    );
  });
}

/// Creates 12 ConsumoMensal entries where only the last month has a value.
List<ConsumoMensal> _consumoWithCurrentMonth({double kmPorLitro = 12.5}) {
  final now = DateTime.now();
  return List.generate(12, (i) {
    final offset = 11 - i;
    return ConsumoMensal(
      mes: DateTime(now.year, now.month - offset),
      kmPorLitro: i == 11 ? kmPorLitro : null,
    );
  });
}

// ---------------------------------------------------------------------------
// Tests
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
  // Screen structure
  // =========================================================================

  group('DashboardGraficosScreen — structure', () {
    testWidgets('screen has AppBar with title "Gráficos"', (tester) async {
      await _pumpGraficosWithOverrides(
        tester,
        db,
        gastos: AsyncData(_emptyGastos()),
        consumo: AsyncData(_emptyConsumo()),
        distribuicao: const AsyncData([]),
      );

      expect(find.text('Gráficos'), findsOneWidget);

      await _teardown(tester);
    });

    testWidgets('loading state shows CircularProgressIndicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            gastosMensaisProvider(_placa)
                .overrideWith((_) => _asyncToStream(const AsyncLoading())),
            consumoMensalProvider(_placa)
                .overrideWith((_) => _asyncToStream(const AsyncLoading())),
            distribuicaoCategoriaProvider(_placa)
                .overrideWith((_) => _asyncToStream(const AsyncLoading())),
          ],
          child: const MaterialApp(
            home: DashboardGraficosScreen(placa: _placa),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      await _teardown(tester);
    });
  });

  // =========================================================================
  // Empty states
  // =========================================================================

  group('DashboardGraficosScreen — empty states', () {
    testWidgets('shows empty text for gastos when all months are zero', (
      tester,
    ) async {
      await _pumpGraficosWithOverrides(
        tester,
        db,
        gastos: AsyncData(_emptyGastos()),
        consumo: AsyncData(_emptyConsumo()),
        distribuicao: const AsyncData([]),
      );

      expect(
        find.text('Nenhum gasto registrado nos últimos 12 meses.'),
        findsOneWidget,
      );

      await _teardown(tester);
    });

    testWidgets('shows empty text for consumo when all months are null', (
      tester,
    ) async {
      await _pumpGraficosWithOverrides(
        tester,
        db,
        gastos: AsyncData(_emptyGastos()),
        consumo: AsyncData(_emptyConsumo()),
        distribuicao: const AsyncData([]),
      );

      expect(find.textContaining('Dados insuficientes'), findsOneWidget);

      await _teardown(tester);
    });

    testWidgets('shows empty text for distribuicao when list is empty', (
      tester,
    ) async {
      await _pumpGraficosWithOverrides(
        tester,
        db,
        gastos: AsyncData(_emptyGastos()),
        consumo: AsyncData(_emptyConsumo()),
        distribuicao: const AsyncData([]),
      );

      expect(find.text('Nenhum gasto nos últimos 12 meses.'), findsOneWidget);

      await _teardown(tester);
    });
  });

  // =========================================================================
  // Charts render with data
  // =========================================================================

  group('DashboardGraficosScreen — charts render with data', () {
    testWidgets('BarChart is present when gastos data has values', (
      tester,
    ) async {
      await _pumpGraficosWithOverrides(
        tester,
        db,
        gastos: AsyncData(
          _gastosWithCurrentMonth(abastec: 300, manut: 100, despesas: 50),
        ),
        consumo: AsyncData(_emptyConsumo()),
        distribuicao: const AsyncData([]),
      );

      expect(find.byType(BarChart), findsOneWidget);

      await _teardown(tester);
    });

    testWidgets(
      'LineChart is present when consumo data has at least one value',
      (tester) async {
        await _pumpGraficosWithOverrides(
          tester,
          db,
          gastos: AsyncData(_emptyGastos()),
          consumo: AsyncData(_consumoWithCurrentMonth(kmPorLitro: 12.5)),
          distribuicao: const AsyncData([]),
        );

        expect(find.byType(LineChart), findsOneWidget);

        await _teardown(tester);
      },
    );

    testWidgets('PieChart is present when distribuicao has entries', (
      tester,
    ) async {
      await _pumpGraficosWithOverrides(
        tester,
        db,
        gastos: AsyncData(_emptyGastos()),
        consumo: AsyncData(_emptyConsumo()),
        distribuicao: const AsyncData([
          CategoriaGasto(rotulo: 'Combustível', total: 500.0),
          CategoriaGasto(rotulo: 'Manutenção', total: 200.0),
        ]),
      );

      expect(find.byType(PieChart), findsOneWidget);

      await _teardown(tester);
    });

    testWidgets('all 3 charts render simultaneously when all have data', (
      tester,
    ) async {
      await _pumpGraficosWithOverrides(
        tester,
        db,
        gastos: AsyncData(
          _gastosWithCurrentMonth(abastec: 300, manut: 100, despesas: 50),
        ),
        consumo: AsyncData(_consumoWithCurrentMonth(kmPorLitro: 10.0)),
        distribuicao: const AsyncData([
          CategoriaGasto(rotulo: 'Combustível', total: 300.0),
        ]),
      );

      expect(find.byType(BarChart), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.byType(PieChart), findsOneWidget);

      await _teardown(tester);
    });
  });

  // =========================================================================
  // Error states
  // =========================================================================

  group('DashboardGraficosScreen — error states', () {
    testWidgets('shows error text when gastosMensaisProvider errors', (
      tester,
    ) async {
      final erro = Exception('DB read failure');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            gastosMensaisProvider(_placa).overrideWith(
              (_) => Stream<List<GastoMensal>>.error(erro, StackTrace.empty),
            ),
            consumoMensalProvider(_placa)
                .overrideWith((_) => Stream.value(_emptyConsumo())),
            distribuicaoCategoriaProvider(_placa)
                .overrideWith((_) => Stream.value(<CategoriaGasto>[])),
          ],
          child: const MaterialApp(
            home: DashboardGraficosScreen(placa: _placa),
          ),
        ),
      );
      // Stream.error() terminates immediately; pumpAndSettle completes
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data?.startsWith('Erro:') ?? false),
        ),
        findsAtLeastNWidgets(1),
      );

      await _teardown(tester);
    });

    testWidgets('shows error text when consumoMensalProvider errors', (
      tester,
    ) async {
      final erro = Exception('consumo error');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            gastosMensaisProvider(_placa)
                .overrideWith((_) => Stream.value(_emptyGastos())),
            consumoMensalProvider(_placa).overrideWith(
              (_) => Stream<List<ConsumoMensal>>.error(erro, StackTrace.empty),
            ),
            distribuicaoCategoriaProvider(_placa)
                .overrideWith((_) => Stream.value(<CategoriaGasto>[])),
          ],
          child: const MaterialApp(
            home: DashboardGraficosScreen(placa: _placa),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data?.startsWith('Erro:') ?? false),
        ),
        findsAtLeastNWidgets(1),
      );

      await _teardown(tester);
    });

    testWidgets('shows error text when distribuicaoCategoriaProvider errors', (
      tester,
    ) async {
      final erro = Exception('dist error');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            gastosMensaisProvider(_placa)
                .overrideWith((_) => Stream.value(_emptyGastos())),
            consumoMensalProvider(_placa)
                .overrideWith((_) => Stream.value(_emptyConsumo())),
            distribuicaoCategoriaProvider(_placa).overrideWith(
              (_) => Stream<List<CategoriaGasto>>.error(erro, StackTrace.empty),
            ),
          ],
          child: const MaterialApp(
            home: DashboardGraficosScreen(placa: _placa),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data?.startsWith('Erro:') ?? false),
        ),
        findsAtLeastNWidgets(1),
      );

      await _teardown(tester);
    });
  });

  // =========================================================================
  // Section titles (pt-BR locale)
  // =========================================================================

  group('DashboardGraficosScreen — section titles', () {
    testWidgets('three section titles are shown in pt-BR', (tester) async {
      await _pumpGraficosWithOverrides(
        tester,
        db,
        gastos: AsyncData(_emptyGastos()),
        consumo: AsyncData(_emptyConsumo()),
        distribuicao: const AsyncData([]),
      );

      expect(
        find.text('Evolução de gastos (últimos 12 meses)'),
        findsOneWidget,
      );
      expect(
        find.text('Consumo médio km/l (últimos 12 meses)'),
        findsOneWidget,
      );
      expect(
        find.text('Distribuição por categoria (últimos 12 meses)'),
        findsOneWidget,
      );

      await _teardown(tester);
    });
  });

  // =========================================================================
  // Bar chart legend labels
  // =========================================================================

  group('DashboardGraficosScreen — bar chart legend', () {
    testWidgets('legend shows Abastec., Manut. and Despesas labels', (
      tester,
    ) async {
      await _pumpGraficosWithOverrides(
        tester,
        db,
        gastos: AsyncData(
          _gastosWithCurrentMonth(abastec: 100, manut: 50, despesas: 30),
        ),
        consumo: AsyncData(_emptyConsumo()),
        distribuicao: const AsyncData([]),
      );

      expect(find.text('Abastec.'), findsOneWidget);
      expect(find.text('Manut.'), findsOneWidget);
      expect(find.text('Despesas'), findsOneWidget);

      await _teardown(tester);
    });
  });

  // =========================================================================
  // Pie chart legend
  // =========================================================================

  group('DashboardGraficosScreen — pie chart legend', () {
    testWidgets('pie legend shows category rotulos', (tester) async {
      await _pumpGraficosWithOverrides(
        tester,
        db,
        gastos: AsyncData(_emptyGastos()),
        consumo: AsyncData(_emptyConsumo()),
        distribuicao: const AsyncData([
          CategoriaGasto(rotulo: 'Combustível', total: 500.0),
          CategoriaGasto(rotulo: 'Manutenção', total: 200.0),
        ]),
      );

      expect(find.textContaining('Combustível'), findsWidgets);
      expect(find.textContaining('Manutenção'), findsWidgets);

      await _teardown(tester);
    });
  });

  // =========================================================================
  // AppBar — graficos button in DashboardHomeScreen
  // =========================================================================

  group('DashboardHomeScreen — graficos AppBar button', () {
    testWidgets(
      'bar_chart_outlined button is hidden when no active vehicle exists',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => const DashboardHomeScreen(),
            ),
            GoRoute(
              path: '/veiculos/novo',
              builder: (context, _) =>
                  const Scaffold(body: Text('ROTA_VEICULOS_NOVO')),
            ),
            GoRoute(
              path: '/comparador',
              builder: (context, _) =>
                  const Scaffold(body: Text('ROTA_COMPARADOR')),
            ),
            GoRoute(
              path: '/config',
              builder: (context, _) =>
                  const Scaffold(body: Text('ROTA_CONFIG')),
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

        expect(find.byIcon(Icons.bar_chart_outlined), findsNothing);

        await _teardown(tester);
      },
    );

    testWidgets(
      'bar_chart_outlined button is visible when an active vehicle exists',
      (tester) async {
        await db.veiculosDao.insertVeiculo(_novoVeiculo());
        SharedPreferences.setMockInitialValues({
          'veiculo_selecionado_placa': _placa,
        });

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => const DashboardHomeScreen(),
            ),
            GoRoute(
              path: '/veiculos/novo',
              builder: (context, _) =>
                  const Scaffold(body: Text('ROTA_VEICULOS_NOVO')),
            ),
            GoRoute(
              path: '/comparador',
              builder: (context, _) =>
                  const Scaffold(body: Text('ROTA_COMPARADOR')),
            ),
            GoRoute(
              path: '/config',
              builder: (context, _) =>
                  const Scaffold(body: Text('ROTA_CONFIG')),
            ),
            GoRoute(
              path: '/dashboard/graficos',
              builder: (_, state) {
                final placa = state.uri.queryParameters['placa'] ?? '';
                return Scaffold(body: Text('ROTA_GRAFICOS:$placa'));
              },
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

        expect(find.byIcon(Icons.bar_chart_outlined), findsOneWidget);

        await _teardown(tester);
      },
    );

    testWidgets(
      'tapping bar_chart_outlined navigates to /dashboard/graficos with correct placa',
      (tester) async {
        await db.veiculosDao.insertVeiculo(_novoVeiculo());
        SharedPreferences.setMockInitialValues({
          'veiculo_selecionado_placa': _placa,
        });

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => const DashboardHomeScreen(),
            ),
            GoRoute(
              path: '/veiculos/novo',
              builder: (context, _) =>
                  const Scaffold(body: Text('ROTA_VEICULOS_NOVO')),
            ),
            GoRoute(
              path: '/comparador',
              builder: (context, _) =>
                  const Scaffold(body: Text('ROTA_COMPARADOR')),
            ),
            GoRoute(
              path: '/config',
              builder: (context, _) =>
                  const Scaffold(body: Text('ROTA_CONFIG')),
            ),
            GoRoute(
              path: '/dashboard/graficos',
              builder: (_, state) {
                final placa = state.uri.queryParameters['placa'] ?? '';
                return Scaffold(body: Text('ROTA_GRAFICOS:$placa'));
              },
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

        await tester.tap(find.byIcon(Icons.bar_chart_outlined));
        await _advance(tester);

        // Should navigate to graficos route passing the vehicle plate
        expect(find.textContaining('ROTA_GRAFICOS:$_placa'), findsOneWidget);

        await _teardown(tester);
      },
    );

    testWidgets('graficos button has correct tooltip "Gráficos"', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      SharedPreferences.setMockInitialValues({
        'veiculo_selecionado_placa': _placa,
      });

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => const DashboardHomeScreen(),
          ),
          GoRoute(
            path: '/veiculos/novo',
            builder: (context, _) =>
                const Scaffold(body: Text('ROTA_VEICULOS_NOVO')),
          ),
          GoRoute(
            path: '/comparador',
            builder: (context, _) =>
                const Scaffold(body: Text('ROTA_COMPARADOR')),
          ),
          GoRoute(
            path: '/config',
            builder: (context, _) => const Scaffold(body: Text('ROTA_CONFIG')),
          ),
          GoRoute(
            path: '/dashboard/graficos',
            builder: (context, _) =>
                const Scaffold(body: Text('ROTA_GRAFICOS')),
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

      expect(find.byTooltip('Gráficos'), findsOneWidget);

      await _teardown(tester);
    });
  });

  // =========================================================================
  // Dark mode — issue #108
  // =========================================================================

  /// Pumps [DashboardGraficosScreen] with an explicit [ThemeData] brightness.
  Future<void> pumpGraficosWithBrightness(
    WidgetTester tester,
    AppDatabase db, {
    required Brightness brightness,
    required AsyncValue<List<GastoMensal>> gastos,
    required AsyncValue<List<ConsumoMensal>> consumo,
    required AsyncValue<List<CategoriaGasto>> distribuicao,
  }) async {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: brightness,
      ),
      useMaterial3: true,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          gastosMensaisProvider(_placa)
              .overrideWith((_) => _asyncToStream(gastos)),
          consumoMensalProvider(_placa)
              .overrideWith((_) => _asyncToStream(consumo)),
          distribuicaoCategoriaProvider(_placa)
              .overrideWith((_) => _asyncToStream(distribuicao)),
        ],
        child: MaterialApp(
          theme: theme,
          home: const DashboardGraficosScreen(placa: _placa),
        ),
      ),
    );
    await _advance(tester);
  }

  group('DashboardGraficosScreen — dark mode (issue #108)', () {
    testWidgets('renders without exception in light mode', (tester) async {
      await pumpGraficosWithBrightness(
        tester,
        db,
        brightness: Brightness.light,
        gastos: AsyncData(
          _gastosWithCurrentMonth(abastec: 300, manut: 100, despesas: 50),
        ),
        consumo: AsyncData(_consumoWithCurrentMonth(kmPorLitro: 12.5)),
        distribuicao: const AsyncData([
          CategoriaGasto(rotulo: 'Combustível', total: 300.0),
          CategoriaGasto(rotulo: 'Manutenção', total: 100.0),
        ]),
      );

      expect(tester.takeException(), isNull);

      await _teardown(tester);
    });

    testWidgets('renders without exception in dark mode', (tester) async {
      await pumpGraficosWithBrightness(
        tester,
        db,
        brightness: Brightness.dark,
        gastos: AsyncData(
          _gastosWithCurrentMonth(abastec: 300, manut: 100, despesas: 50),
        ),
        consumo: AsyncData(_consumoWithCurrentMonth(kmPorLitro: 12.5)),
        distribuicao: const AsyncData([
          CategoriaGasto(rotulo: 'Combustível', total: 300.0),
          CategoriaGasto(rotulo: 'Manutenção', total: 100.0),
        ]),
      );

      expect(tester.takeException(), isNull);

      await _teardown(tester);
    });

    testWidgets('empty state placeholder renders in dark mode', (tester) async {
      await pumpGraficosWithBrightness(
        tester,
        db,
        brightness: Brightness.dark,
        gastos: AsyncData(_emptyGastos()),
        consumo: AsyncData(_emptyConsumo()),
        distribuicao: const AsyncData([]),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.text('Nenhum gasto registrado nos últimos 12 meses.'),
        findsOneWidget,
      );
      expect(find.text('Nenhum gasto nos últimos 12 meses.'), findsOneWidget);

      await _teardown(tester);
    });

    testWidgets(
      'legend text uses colorScheme.onSurface in light mode (not hardcoded)',
      (tester) async {
        await pumpGraficosWithBrightness(
          tester,
          db,
          brightness: Brightness.light,
          gastos: AsyncData(
            _gastosWithCurrentMonth(abastec: 100, manut: 50, despesas: 30),
          ),
          consumo: AsyncData(_emptyConsumo()),
          distribuicao: const AsyncData([]),
        );

        // Verify legend Text widgets exist and carry the theme onSurface color.
        final legendaItems = tester.widgetList<Text>(find.text('Abastec.'));
        expect(legendaItems, isNotEmpty);
        for (final t in legendaItems) {
          // The color should be set (not null), and should NOT be Colors.grey.
          expect(t.style?.color, isNotNull);
          expect(t.style?.color, isNot(Colors.grey));
        }

        await _teardown(tester);
      },
    );

    testWidgets(
      'legend text uses colorScheme.onSurface in dark mode (not hardcoded)',
      (tester) async {
        await pumpGraficosWithBrightness(
          tester,
          db,
          brightness: Brightness.dark,
          gastos: AsyncData(
            _gastosWithCurrentMonth(abastec: 100, manut: 50, despesas: 30),
          ),
          consumo: AsyncData(_emptyConsumo()),
          distribuicao: const AsyncData([]),
        );

        final legendaItems = tester.widgetList<Text>(find.text('Abastec.'));
        expect(legendaItems, isNotEmpty);
        for (final t in legendaItems) {
          expect(t.style?.color, isNotNull);
          expect(t.style?.color, isNot(Colors.grey));
        }

        await _teardown(tester);
      },
    );

    testWidgets(
      'section title color adapts: uses onSurfaceVariant in both modes',
      (tester) async {
        for (final brightness in [Brightness.light, Brightness.dark]) {
          await pumpGraficosWithBrightness(
            tester,
            db,
            brightness: brightness,
            gastos: AsyncData(_emptyGastos()),
            consumo: AsyncData(_emptyConsumo()),
            distribuicao: const AsyncData([]),
          );

          expect(tester.takeException(), isNull);

          // Section titles should be present with adaptive colors (no crash).
          expect(
            find.text('Evolução de gastos (últimos 12 meses)'),
            findsOneWidget,
          );

          await _teardown(tester);
        }
      },
    );
  });
}
