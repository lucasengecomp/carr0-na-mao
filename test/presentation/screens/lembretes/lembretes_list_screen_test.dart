import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/data/providers.dart';
import 'package:carro_na_mao/presentation/screens/lembretes/lembretes_list_screen.dart';
import 'package:carro_na_mao/presentation/screens/lembretes/lembretes_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/l10n_delegates.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

LembretesCompanion _novoLembrete({
  String placa = 'ABC1D23',
  String descricao = 'Trocar palhetas',
  DateTime? dataAlvo,
  int? kmAlvo,
  StatusLembrete status = StatusLembrete.pendente,
}) => LembretesCompanion.insert(
  veiculoPlaca: placa,
  tipo: 'avulso',
  descricao: descricao,
  dataAlvo: Value(dataAlvo),
  kmAlvo: Value(kmAlvo),
  status: status,
);

/// Monta a LembretesListScreen com DB real injetado.
Future<void> _pumpScreen(WidgetTester tester, {required AppDatabase db}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const MaterialApp(
        locale: localeDefault,
        localizationsDelegates: l10nDelegates,
        supportedLocales: supportedLocales,
        home: LembretesListScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Monta a tela com providers substituídos por dados fixos.
Future<void> _pumpScreenWithProviders(
  WidgetTester tester, {
  required AppDatabase db,
  List<Lembrete> pendentes = const [],
  List<Lembrete> atrasados = const [],
  List<Lembrete> concluidos = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        lembretesPendentesProvider.overrideWith((_) => Stream.value(pendentes)),
        lembretesAtrasadosProvider.overrideWith((_) => Stream.value(atrasados)),
        lembretesConcluidosProvider.overrideWith(
          (_) => Stream.value(concluidos),
        ),
      ],
      child: const MaterialApp(
        locale: localeDefault,
        localizationsDelegates: l10nDelegates,
        supportedLocales: supportedLocales,
        home: LembretesListScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Monta a tela com GoRouter para testar navegação do FAB.
Future<void> _pumpScreenWithRouter(
  WidgetTester tester, {
  required AppDatabase db,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LembretesListScreen(),
      ),
      GoRoute(
        path: '/lembretes/novo',
        builder: (context, state) =>
            const Scaffold(body: Text('LembreteFormScreen')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        lembretesPendentesProvider.overrideWith((_) => Stream.value([])),
        lembretesAtrasadosProvider.overrideWith((_) => Stream.value([])),
        lembretesConcluidosProvider.overrideWith((_) => Stream.value([])),
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
}

/// Desmonta o widget tree e drena timers do Drift.
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 10));
}

/// Cria um Lembrete fictício sem banco (para uso nos overrides de provider).
Lembrete _fakeLembrete({
  int id = 1,
  String placa = 'ABC1D23',
  String descricao = 'Trocar palhetas',
  DateTime? dataAlvo,
  int? kmAlvo,
  StatusLembrete status = StatusLembrete.pendente,
}) => Lembrete(
  id: id,
  veiculoPlaca: placa,
  manutencaoId: null,
  tipo: 'avulso',
  descricao: descricao,
  dataAlvo: dataAlvo,
  kmAlvo: kmAlvo,
  status: status,
);

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.veiculosDao.insertVeiculo(
      VeiculosCompanion.insert(
        placa: 'ABC1D23',
        marca: 'Fiat',
        modelo: 'Uno',
        ano: 2020,
        tipo: TipoVeiculo.carro,
        combustivel: TipoCombustivelVeiculo.flex,
        kmInicial: 10000,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  // -------------------------------------------------------------------------
  // Estrutura básica — 3 tabs
  // -------------------------------------------------------------------------
  group('estrutura: 3 tabs', () {
    testWidgets('exibe título da tela', (tester) async {
      await _pumpScreenWithProviders(tester, db: db);
      expect(find.text('Lembretes'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('exibe tab "Pendentes"', (tester) async {
      await _pumpScreenWithProviders(tester, db: db);
      expect(find.text('Pendentes'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('exibe tab "Atrasados"', (tester) async {
      await _pumpScreenWithProviders(tester, db: db);
      expect(find.text('Atrasados'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('exibe tab "Concluídos"', (tester) async {
      await _pumpScreenWithProviders(tester, db: db);
      expect(find.text('Concluídos'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('exibe TabBar com 3 tabs', (tester) async {
      await _pumpScreenWithProviders(tester, db: db);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(3));
      await _teardown(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Estado vazio por tab
  // -------------------------------------------------------------------------
  group('estado vazio', () {
    testWidgets('tab Pendentes vazia exibe mensagem de vazio', (tester) async {
      await _pumpScreenWithProviders(tester, db: db);
      expect(find.textContaining('Nenhum lembrete pendente'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('tab Atrasados vazia exibe mensagem de vazio ao navegar', (
      tester,
    ) async {
      await _pumpScreenWithProviders(tester, db: db);

      await tester.tap(find.text('Atrasados'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nenhum lembrete atrasado'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('tab Concluídos vazia exibe mensagem de vazio ao navegar', (
      tester,
    ) async {
      await _pumpScreenWithProviders(tester, db: db);

      await tester.tap(find.text('Concluídos'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nenhum lembrete concluído'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('ícone exibido no estado vazio', (tester) async {
      await _pumpScreenWithProviders(tester, db: db);
      expect(find.byIcon(Icons.notifications_none_outlined), findsOneWidget);
      await _teardown(tester);
    });
  });

  // -------------------------------------------------------------------------
  // FAB
  // -------------------------------------------------------------------------
  group('FAB', () {
    testWidgets('FAB está visível', (tester) async {
      await _pumpScreenWithProviders(tester, db: db);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('FAB exibe label "Novo lembrete"', (tester) async {
      await _pumpScreenWithProviders(tester, db: db);
      expect(find.text('Novo lembrete'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets(
      'toque no FAB navega para /lembretes/novo (não exibe "Em breve")',
      (tester) async {
        // Usa helper com GoRouter para verificar que a navegação ocorre.
        await _pumpScreenWithRouter(tester, db: db);

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Deve ter navegado para /lembretes/novo; "Em breve" não deve aparecer
        expect(find.text('Em breve'), findsNothing);
        // A tela de formulário (stub) deve estar visível
        expect(find.text('LembreteFormScreen'), findsOneWidget);
        await _teardown(tester);
      },
    );
  });

  // -------------------------------------------------------------------------
  // Linha de lembrete — campos e badge
  // -------------------------------------------------------------------------
  group('linha de lembrete', () {
    testWidgets('exibe descrição do lembrete', (tester) async {
      await _pumpScreenWithProviders(
        tester,
        db: db,
        pendentes: [
          _fakeLembrete(descricao: 'Trocar filtro de ar', kmAlvo: 50000),
        ],
      );

      expect(find.text('Trocar filtro de ar'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('exibe placa do veículo no subtítulo', (tester) async {
      await _pumpScreenWithProviders(
        tester,
        db: db,
        pendentes: [_fakeLembrete(placa: 'XYZ1A23', kmAlvo: 50000)],
      );

      expect(find.textContaining('XYZ1A23'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('exibe data formatada dd/MM/yyyy', (tester) async {
      await _pumpScreenWithProviders(
        tester,
        db: db,
        pendentes: [
          _fakeLembrete(
            dataAlvo: DateTime(2026, 12, 5),
            kmAlvo: 50000,
            descricao: 'Revisão anual',
          ),
        ],
      );

      expect(find.textContaining('05/12/2026'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('exibe km_alvo com separador de milhar (ponto)', (
      tester,
    ) async {
      await _pumpScreenWithProviders(
        tester,
        db: db,
        pendentes: [_fakeLembrete(kmAlvo: 123456, descricao: 'Revisão km')],
      );

      expect(find.textContaining('123.456'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('exibe badge "Pendente" na tab Pendentes', (tester) async {
      await _pumpScreenWithProviders(
        tester,
        db: db,
        pendentes: [_fakeLembrete(kmAlvo: 50000)],
      );

      expect(find.text('Pendente'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('exibe badge "Concluído" na tab Concluídos', (tester) async {
      await _pumpScreenWithProviders(
        tester,
        db: db,
        concluidos: [
          _fakeLembrete(
            kmAlvo: 50000,
            status: StatusLembrete.concluido,
            descricao: 'Já feito',
          ),
        ],
      );

      await tester.tap(find.text('Concluídos'));
      await tester.pumpAndSettle();

      expect(find.text('Concluído'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('exibe badge "Adiado" para status adiado', (tester) async {
      await _pumpScreenWithProviders(
        tester,
        db: db,
        concluidos: [
          _fakeLembrete(
            kmAlvo: 50000,
            status: StatusLembrete.adiado,
            descricao: 'Revisão adiada',
          ),
        ],
      );

      await tester.tap(find.text('Concluídos'));
      await tester.pumpAndSettle();

      expect(find.text('Adiado'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('exibe ícone de notificação na linha', (tester) async {
      await _pumpScreenWithProviders(
        tester,
        db: db,
        pendentes: [_fakeLembrete(kmAlvo: 50000)],
      );

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('toque na linha navega para /lembretes/:id', (tester) async {
      // Usa GoRouter para que context.push funcione corretamente.
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => ProviderScope(
              overrides: [
                appDatabaseProvider.overrideWithValue(db),
                lembretesPendentesProvider.overrideWith(
                  (_) => Stream.value([
                    _fakeLembrete(
                      id: 42,
                      kmAlvo: 50000,
                      descricao: 'Trocar velas',
                    ),
                  ]),
                ),
                lembretesAtrasadosProvider.overrideWith(
                  (_) => Stream.value(const []),
                ),
                lembretesConcluidosProvider.overrideWith(
                  (_) => Stream.value(const []),
                ),
              ],
              child: const LembretesListScreen(),
            ),
          ),
          GoRoute(
            path: '/lembretes/:id',
            builder: (context, state) =>
                Scaffold(body: Text('detalhe-${state.pathParameters['id']}')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          locale: localeDefault,
          localizationsDelegates: l10nDelegates,
          supportedLocales: supportedLocales,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Trocar velas'));
      await tester.pumpAndSettle();

      // Após tap, o GoRouter navegou para /lembretes/42 e o snackbar "Em breve"
      // nunca foi exibido.
      expect(find.text('detalhe-42'), findsOneWidget);
      expect(find.text('Em breve'), findsNothing);
      await _teardown(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Lembrete pendente futuro aparece na tab correta
  // -------------------------------------------------------------------------
  group('roteamento por tab com DB real', () {
    testWidgets('lembrete pendente futuro aparece na tab Pendentes', (
      tester,
    ) async {
      await db.lembretesDao.insertLembrete(
        _novoLembrete(
          dataAlvo: DateTime(2027, 6, 1),
          descricao: 'Revisão 2027',
        ),
      );

      await _pumpScreen(tester, db: db);

      expect(find.text('Revisão 2027'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('lembrete pendente com dataAlvo passada aparece em Atrasados', (
      tester,
    ) async {
      // Data claramente no passado para evitar dependência de "hoje"
      await db.lembretesDao.insertLembrete(
        _novoLembrete(
          dataAlvo: DateTime(2020, 1, 1),
          descricao: 'Revisão atrasada 2020',
        ),
      );

      await _pumpScreen(tester, db: db);

      // Aba Pendentes não deve conter
      expect(find.text('Revisão atrasada 2020'), findsNothing);

      // Navega para Atrasados
      await tester.tap(find.text('Atrasados'));
      await tester.pumpAndSettle();

      expect(find.text('Revisão atrasada 2020'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('lembrete concluído aparece em Concluídos', (tester) async {
      final id = await db.lembretesDao.insertLembrete(
        _novoLembrete(
          dataAlvo: DateTime(2025, 6, 1),
          descricao: 'Troca óleo concluída',
        ),
      );
      await db.lembretesDao.marcarConcluido(id);

      await _pumpScreen(tester, db: db);

      // Não deve estar em Pendentes
      expect(find.text('Troca óleo concluída'), findsNothing);

      // Navega para Concluídos
      await tester.tap(find.text('Concluídos'));
      await tester.pumpAndSettle();

      expect(find.text('Troca óleo concluída'), findsOneWidget);
      await _teardown(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Formatação (unit — sem DB)
  // -------------------------------------------------------------------------
  group('formatação de data dd/MM/yyyy', () {
    testWidgets('data 01/01/2026 é exibida como 01/01/2026', (tester) async {
      await _pumpScreenWithProviders(
        tester,
        db: db,
        pendentes: [
          _fakeLembrete(dataAlvo: DateTime(2026, 1, 1), kmAlvo: 50000),
        ],
      );
      expect(find.textContaining('01/01/2026'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('data 31/12/2027 é exibida como 31/12/2027', (tester) async {
      await _pumpScreenWithProviders(
        tester,
        db: db,
        pendentes: [
          _fakeLembrete(dataAlvo: DateTime(2027, 12, 31), kmAlvo: 50000),
        ],
      );
      expect(find.textContaining('31/12/2027'), findsOneWidget);
      await _teardown(tester);
    });
  });

  group('formatação de km com separador de milhar', () {
    testWidgets('1000 km é exibido como 1.000 km', (tester) async {
      await _pumpScreenWithProviders(
        tester,
        db: db,
        pendentes: [_fakeLembrete(kmAlvo: 1000)],
      );
      expect(find.textContaining('1.000'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('999 km não tem separador de milhar', (tester) async {
      await _pumpScreenWithProviders(
        tester,
        db: db,
        pendentes: [_fakeLembrete(kmAlvo: 999)],
      );
      expect(find.textContaining('999 km'), findsOneWidget);
      await _teardown(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Estado de erro
  // -------------------------------------------------------------------------
  group('estado de erro', () {
    testWidgets('quando provider emite erro, exibe mensagem genérica', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            lembretesPendentesProvider.overrideWith(
              (_) => Stream<List<Lembrete>>.error('Erro de banco simulado'),
            ),
            lembretesAtrasadosProvider.overrideWith(
              (_) => Stream.value(const []),
            ),
            lembretesConcluidosProvider.overrideWith(
              (_) => Stream.value(const []),
            ),
          ],
          child: const MaterialApp(
            locale: localeDefault,
            localizationsDelegates: l10nDelegates,
            supportedLocales: supportedLocales,
            home: LembretesListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Erro'), findsOneWidget);
      await _teardown(tester);
    });
  });
}
