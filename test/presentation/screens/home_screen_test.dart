import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/data/providers.dart';
import 'package:carro_na_mao/presentation/screens/home_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

Future<void> _advance(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _teardownUi(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _pumpHome(WidgetTester tester, AppDatabase db) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
      GoRoute(
        path: '/comparador',
        builder: (c, s) => const Scaffold(body: Text('ROTA_COMPARADOR')),
      ),
      GoRoute(
        path: '/config',
        builder: (c, s) => const Scaffold(body: Text('ROTA_CONFIG')),
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

void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('título padrão quando não há veículos', (tester) async {
    await _pumpHome(tester, db);
    expect(find.text('Carro na Mão'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
    await _teardownUi(tester);
  });

  testWidgets('título padrão com apenas 1 veículo (seletor oculto)', (
    tester,
  ) async {
    await db.veiculosDao.insertVeiculo(
      _novo(placa: 'ABC1D23', apelido: 'Único'),
    );

    await _pumpHome(tester, db);
    expect(find.text('Carro na Mão'), findsOneWidget);
    expect(find.text('Único'), findsNothing);
    expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
    await _teardownUi(tester);
  });

  testWidgets('exibe seletor com 2+ veículos e persiste seleção', (
    tester,
  ) async {
    await db.veiculosDao.insertVeiculo(
      _novo(placa: 'ABC1D23', apelido: 'Uninho'),
    );
    await db.veiculosDao.insertVeiculo(
      _novo(placa: 'XYZ9A99', apelido: 'Mobinho'),
    );

    await _pumpHome(tester, db);

    expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    expect(find.text('Mobinho'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await _advance(tester);
    await tester.tap(find.text('Uninho').last);
    await _advance(tester);

    expect(find.text('Uninho'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('veiculo_selecionado_placa'), 'ABC1D23');

    await _teardownUi(tester);
  });

  testWidgets('respeita placa persistida no SharedPreferences', (tester) async {
    SharedPreferences.setMockInitialValues({
      'veiculo_selecionado_placa': 'XYZ9A99',
    });

    await db.veiculosDao.insertVeiculo(
      _novo(placa: 'ABC1D23', apelido: 'Uninho'),
    );
    await db.veiculosDao.insertVeiculo(
      _novo(placa: 'XYZ9A99', apelido: 'Mobinho'),
    );

    await _pumpHome(tester, db);

    expect(find.text('Mobinho'), findsOneWidget);
    await _teardownUi(tester);
  });

  testWidgets('placa persistida inexistente cai no primeiro ativo', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'veiculo_selecionado_placa': 'ZZZ0Z00',
    });

    await db.veiculosDao.insertVeiculo(
      _novo(placa: 'ABC1D23', apelido: 'Uninho'),
    );
    await db.veiculosDao.insertVeiculo(
      _novo(placa: 'XYZ9A99', apelido: 'Mobinho'),
    );

    await _pumpHome(tester, db);
    expect(find.text('Mobinho'), findsOneWidget);
    await _teardownUi(tester);
  });
}
