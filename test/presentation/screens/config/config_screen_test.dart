import 'dart:async';

import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/data/providers.dart';
import 'package:carro_na_mao/presentation/screens/config/config_screen.dart';
import 'package:carro_na_mao/services/export_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/l10n_delegates.dart';

// ── Fake ExportService ──────────────────────────────────────────────────────

class _FakeExportService implements ExportService {
  final List<String> exportedPlacas = [];
  bool shouldThrow = false;

  @override
  Future<List<XFile>> exportarVeiculo(String placa) async {
    if (shouldThrow) throw Exception('Falha simulada');
    exportedPlacas.add(placa);
    return [];
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

Future<void> _seedVeiculo(AppDatabase db, {String placa = 'ABC1D23'}) {
  return db.veiculosDao.insertVeiculo(
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
}

Future<void> _pump(
  WidgetTester tester, {
  required AppDatabase db,
  required ExportService fakeExport,
  String? placaAtiva,
}) async {
  SharedPreferences.setMockInitialValues(
    placaAtiva == null ? {} : {'veiculo_selecionado_placa': placaAtiva},
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        exportServiceProvider.overrideWithValue(fakeExport),
      ],
      child: const MaterialApp(
        locale: localeDefault,
        localizationsDelegates: l10nDelegates,
        supportedLocales: supportedLocales,
        home: ConfigScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _teardownUI(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 10));
}

// ── Testes ──────────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;
  late _FakeExportService fakeExport;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    fakeExport = _FakeExportService();
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('exibe mensagem quando não há veículos', (tester) async {
    await _pump(tester, db: db, fakeExport: fakeExport);
    expect(find.text('Selecione um veículo para exportar.'), findsOneWidget);
    await _teardownUI(tester);
  });

  testWidgets('exibe botão Exportar CSV quando há veículo', (tester) async {
    await _seedVeiculo(db);
    await _pump(tester, db: db, fakeExport: fakeExport, placaAtiva: 'ABC1D23');
    expect(find.text('Exportar CSV'), findsOneWidget);
    await _teardownUI(tester);
  });

  testWidgets('dropdown de veículo é exibido com veículo cadastrado', (
    tester,
  ) async {
    await _seedVeiculo(db);
    await _pump(tester, db: db, fakeExport: fakeExport, placaAtiva: 'ABC1D23');
    // O DropdownButtonFormField exibe o veículo ativo
    expect(find.textContaining('ABC1D23'), findsWidgets);
    await _teardownUI(tester);
  });

  testWidgets('toque no botão chama exportarVeiculo com a placa selecionada', (
    tester,
  ) async {
    await _seedVeiculo(db);
    await _pump(tester, db: db, fakeExport: fakeExport, placaAtiva: 'ABC1D23');

    await tester.tap(find.text('Exportar CSV'));
    await tester.pumpAndSettle();

    expect(fakeExport.exportedPlacas, contains('ABC1D23'));
    await _teardownUI(tester);
  });

  testWidgets('mostra snackbar de sucesso após exportação bem-sucedida', (
    tester,
  ) async {
    await _seedVeiculo(db);
    await _pump(tester, db: db, fakeExport: fakeExport, placaAtiva: 'ABC1D23');

    await tester.tap(find.text('Exportar CSV'));
    await tester.pumpAndSettle();

    expect(find.text('Arquivos exportados com sucesso!'), findsOneWidget);
    await _teardownUI(tester);
  });

  testWidgets('mostra snackbar de erro quando exportação falha', (
    tester,
  ) async {
    fakeExport.shouldThrow = true;
    await _seedVeiculo(db);
    await _pump(tester, db: db, fakeExport: fakeExport, placaAtiva: 'ABC1D23');

    await tester.tap(find.text('Exportar CSV'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Erro ao exportar:'), findsOneWidget);
    await _teardownUI(tester);
  });

  testWidgets('botão Exportar CSV fica desabilitado enquanto exporta', (
    tester,
  ) async {
    // Fake com delay para observar o estado de carregamento.
    final slowFake = _SlowExportService();
    await _seedVeiculo(db);
    await _pump(tester, db: db, fakeExport: slowFake, placaAtiva: 'ABC1D23');

    // Toca o botão e pumpa apenas um frame — exportação ainda em andamento.
    await tester.tap(find.text('Exportar CSV'));
    await tester.pump();

    // Botão deve estar desabilitado (onPressed == null).
    final btn = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Exportar CSV'),
    );
    expect(
      btn.onPressed,
      isNull,
      reason: 'botão deve estar desabilitado durante exportação',
    );

    // CircularProgressIndicator deve estar visível.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Conclui a exportação.
    slowFake.completer.complete([]);
    await tester.pumpAndSettle();
    await _teardownUI(tester);
  });

  testWidgets('sem veículo selecionado botão Exportar CSV não é exibido', (
    tester,
  ) async {
    // Sem veículos: apenas a mensagem de "sem veículo" é exibida.
    await _pump(tester, db: db, fakeExport: fakeExport);
    expect(find.text('Exportar CSV'), findsNothing);
    expect(find.text('Selecione um veículo para exportar.'), findsOneWidget);
    await _teardownUI(tester);
  });
}

// ── Fake lento para testar loading indicator ─────────────────────────────────

class _SlowExportService implements ExportService {
  final completer = Completer<List<XFile>>();

  @override
  Future<List<XFile>> exportarVeiculo(String placa) => completer.future;
}
