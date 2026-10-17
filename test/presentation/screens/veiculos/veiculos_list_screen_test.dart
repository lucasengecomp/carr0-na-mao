import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/data/providers.dart';
import 'package:carro_na_mao/presentation/screens/veiculos/veiculos_list_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/l10n_delegates.dart';

VeiculosCompanion _novo({
  required String placa,
  String? apelido,
  String marca = 'Fiat',
  String modelo = 'Uno',
  int ano = 2020,
}) => VeiculosCompanion.insert(
  placa: placa,
  apelido: Value(apelido),
  marca: marca,
  modelo: modelo,
  ano: ano,
  tipo: TipoVeiculo.carro,
  combustivel: TipoCombustivelVeiculo.flex,
  kmInicial: 10000,
);

/// Avança o tempo em pequenos passos sem usar pumpAndSettle. O stream do
/// drift precisa de alguns ticks para emitir, e pumpAndSettle fica preso
/// na animação do CircularProgressIndicator do estado de loading.
Future<void> _advance(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Desmonta a árvore e drena o timer que o drift agenda ao cancelar o
/// stream subscription. Sem isso, Flutter reclama de "Timer still pending".
Future<void> _teardownUi(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _pumpList(WidgetTester tester, AppDatabase db) async {
  final router = GoRouter(
    initialLocation: '/veiculos',
    routes: [
      GoRoute(
        path: '/veiculos',
        builder: (c, s) => const VeiculosListScreen(),
        routes: [
          GoRoute(
            path: 'novo',
            builder: (c, s) =>
                const Scaffold(body: Center(child: Text('ROTA_NOVO'))),
          ),
          GoRoute(
            path: ':placa/editar',
            builder: (c, s) => Scaffold(
              body: Center(child: Text('EDITAR_${s.pathParameters['placa']}')),
            ),
          ),
        ],
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

  testWidgets('empty state quando sem veículos', (tester) async {
    await _pumpList(tester, db);
    expect(find.textContaining('Nenhum veículo'), findsOneWidget);
    await _teardownUi(tester);
  });

  testWidgets('lista veículos ativos com apelido ou modelo', (tester) async {
    await db.veiculosDao.insertVeiculo(
      _novo(placa: 'ABC1D23', apelido: 'Uninho'),
    );
    await db.veiculosDao.insertVeiculo(
      _novo(placa: 'XYZ9A99', marca: 'Fiat', modelo: 'Mobi'),
    );

    await _pumpList(tester, db);

    expect(find.text('Uninho'), findsOneWidget);
    expect(find.text('Fiat Mobi'), findsOneWidget);
    expect(find.text('ABC1D23 · 2020'), findsOneWidget);
    await _teardownUi(tester);
  });

  testWidgets('toggle para arquivados muda a lista', (tester) async {
    await db.veiculosDao.insertVeiculo(_novo(placa: 'ABC1D23'));
    await db.veiculosDao.insertVeiculo(_novo(placa: 'XYZ9A99'));
    await db.veiculosDao.arquivar('XYZ9A99');

    await _pumpList(tester, db);
    expect(find.text('ABC1D23 · 2020'), findsOneWidget);
    expect(find.text('XYZ9A99 · 2020'), findsNothing);

    await tester.tap(find.text('Arquivados'));
    await _advance(tester);

    expect(find.text('ABC1D23 · 2020'), findsNothing);
    expect(find.text('XYZ9A99 · 2020'), findsOneWidget);
    await _teardownUi(tester);
  });

  testWidgets('arquivar via menu move pra arquivados', (tester) async {
    await db.veiculosDao.insertVeiculo(_novo(placa: 'ABC1D23'));

    await _pumpList(tester, db);

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await _advance(tester);
    await tester.tap(find.text('Arquivar'));
    await _advance(tester);

    expect(find.text('ABC1D23 · 2020'), findsNothing);
    expect(await db.veiculosDao.listArquivados(), hasLength(1));

    await tester.tap(find.text('Arquivados'));
    await _advance(tester);
    expect(find.text('ABC1D23 · 2020'), findsOneWidget);
    await _teardownUi(tester);
  });

  testWidgets('restaurar via menu volta pra ativos', (tester) async {
    await db.veiculosDao.insertVeiculo(_novo(placa: 'ABC1D23'));
    await db.veiculosDao.arquivar('ABC1D23');

    await _pumpList(tester, db);
    await tester.tap(find.text('Arquivados'));
    await _advance(tester);

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await _advance(tester);
    await tester.tap(find.text('Restaurar'));
    await _advance(tester);

    expect(find.text('ABC1D23 · 2020'), findsNothing);
    expect(await db.veiculosDao.listAtivos(), hasLength(1));
    await _teardownUi(tester);
  });

  testWidgets('FAB some na visão de arquivados', (tester) async {
    await db.veiculosDao.insertVeiculo(_novo(placa: 'ABC1D23'));

    await _pumpList(tester, db);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    await tester.tap(find.text('Arquivados'));
    await _advance(tester);
    expect(find.byType(FloatingActionButton), findsNothing);
    await _teardownUi(tester);
  });
}
