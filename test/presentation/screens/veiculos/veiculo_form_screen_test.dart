import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/data/providers.dart';
import 'package:carro_na_mao/presentation/screens/veiculos/veiculo_form_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/l10n_delegates.dart';

Future<void> _pumpForm(
  WidgetTester tester, {
  required AppDatabase db,
  String? placa,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        locale: localeDefault,
        localizationsDelegates: l10nDelegates,
        supportedLocales: supportedLocales,
        home: VeiculoFormScreen(placa: placa),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _byLabel(String label) =>
    find.widgetWithText(TextFormField, label).first;

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('submete veículo válido e persiste no banco', (tester) async {
    await _pumpForm(tester, db: db);

    await tester.enterText(_byLabel('Placa'), 'abc1d23');
    await tester.enterText(_byLabel('Marca'), 'Fiat');
    await tester.enterText(_byLabel('Modelo'), 'Uno');
    await tester.enterText(_byLabel('Ano'), '2020');
    await tester.enterText(_byLabel('Hodômetro atual (km)'), '10000');

    await tester.scrollUntilVisible(
      find.byType(FilledButton),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    final lista = await db.veiculosDao.listAtivos();
    expect(lista, hasLength(1));
    expect(lista.single.placa, 'ABC1D23');
    expect(lista.single.marca, 'Fiat');
    expect(lista.single.kmInicial, 10000);
  });

  testWidgets('não submete com placa inválida', (tester) async {
    await _pumpForm(tester, db: db);

    await tester.enterText(_byLabel('Placa'), 'XXX');
    await tester.enterText(_byLabel('Marca'), 'Fiat');
    await tester.enterText(_byLabel('Modelo'), 'Uno');
    await tester.enterText(_byLabel('Ano'), '2020');
    await tester.enterText(_byLabel('Hodômetro atual (km)'), '10000');

    await tester.scrollUntilVisible(
      find.byType(FilledButton),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('7 caracteres'), findsOneWidget);
    expect(await db.veiculosDao.listAtivos(), isEmpty);
  });

  testWidgets('mostra snackbar quando placa já existe', (tester) async {
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

    await _pumpForm(tester, db: db);

    await tester.enterText(_byLabel('Placa'), 'ABC1D23');
    await tester.enterText(_byLabel('Marca'), 'Fiat');
    await tester.enterText(_byLabel('Modelo'), 'Mobi');
    await tester.enterText(_byLabel('Ano'), '2024');
    await tester.enterText(_byLabel('Hodômetro atual (km)'), '5000');

    await tester.scrollUntilVisible(
      find.byType(FilledButton),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Já existe'), findsOneWidget);
  });

  testWidgets('ano fora da faixa é rejeitado', (tester) async {
    await _pumpForm(tester, db: db);

    await tester.enterText(_byLabel('Placa'), 'ABC1D23');
    await tester.enterText(_byLabel('Marca'), 'Fiat');
    await tester.enterText(_byLabel('Modelo'), 'Uno');
    await tester.enterText(_byLabel('Ano'), '1800');
    await tester.enterText(_byLabel('Hodômetro atual (km)'), '10000');

    await tester.scrollUntilVisible(
      find.byType(FilledButton),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Ano fora da faixa'), findsOneWidget);
  });

  testWidgets('modo edição carrega dados e bloqueia placa', (tester) async {
    await db.veiculosDao.insertVeiculo(
      VeiculosCompanion.insert(
        placa: 'ABC1D23',
        apelido: const Value('Uninho'),
        marca: 'Fiat',
        modelo: 'Uno',
        ano: 2020,
        tipo: TipoVeiculo.carro,
        combustivel: TipoCombustivelVeiculo.flex,
        kmInicial: 10000,
      ),
    );

    await _pumpForm(tester, db: db, placa: 'ABC1D23');

    expect(find.text('Editar veículo'), findsOneWidget);
    expect(find.text('ABC1D23'), findsOneWidget);
    expect(find.text('Uninho'), findsOneWidget);

    final placaField = tester.widget<TextFormField>(_byLabel('Placa'));
    expect(placaField.enabled, isFalse);
  });

  testWidgets('mostra sugestões da base ao digitar na marca', (tester) async {
    await db.marcasModelosDao.seedFromJson(
      '{"assetsVersion": 1, "marcas": ['
      '{"marca": "Fiat", "modelos": ["Uno", "Mobi", "Argo"]},'
      '{"marca": "Volkswagen", "modelos": ["Gol"]}'
      ']}',
    );

    await _pumpForm(tester, db: db);

    await tester.enterText(_byLabel('Marca'), 'Fia');
    await tester.pumpAndSettle();

    // Overlay de sugestões lista a marca filtrada.
    expect(find.text('Fiat'), findsOneWidget);
    expect(find.text('Volkswagen'), findsNothing);

    // Clicando numa sugestão, a marca fica preenchida e os modelos daquela
    // marca passam a aparecer como sugestões.
    await tester.tap(find.text('Fiat'));
    await tester.pumpAndSettle();

    await tester.enterText(_byLabel('Modelo'), 'U');
    await tester.pumpAndSettle();

    expect(find.text('Uno'), findsOneWidget);
    // Mobi e Argo não deveriam aparecer no filtro por 'U'.
    expect(find.text('Mobi'), findsNothing);
    expect(find.text('Argo'), findsNothing);
  });

  testWidgets('aceita marca/modelo livres fora da base', (tester) async {
    // Base vazia: nenhuma sugestão. Usuário ainda consegue cadastrar.
    await _pumpForm(tester, db: db);

    await tester.enterText(_byLabel('Placa'), 'abc1d23');
    await tester.enterText(_byLabel('Marca'), 'MarcaRara');
    await tester.enterText(_byLabel('Modelo'), 'ModeloCustom');
    await tester.enterText(_byLabel('Ano'), '2020');
    await tester.enterText(_byLabel('Hodômetro atual (km)'), '10000');

    await tester.scrollUntilVisible(
      find.byType(FilledButton),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    final lista = await db.veiculosDao.listAtivos();
    expect(lista.single.marca, 'MarcaRara');
    expect(lista.single.modelo, 'ModeloCustom');
  });

  testWidgets('salvar edição persiste alterações', (tester) async {
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

    await _pumpForm(tester, db: db, placa: 'ABC1D23');

    await tester.enterText(_byLabel('Apelido (opcional)'), 'Uninho');
    await tester.enterText(_byLabel('Hodômetro atual (km)'), '12345');

    await tester.scrollUntilVisible(
      find.byType(FilledButton),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    final v = (await db.veiculosDao.byPlaca('ABC1D23'))!;
    expect(v.apelido, 'Uninho');
    expect(v.kmInicial, 12345);
  });
}
