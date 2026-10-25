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
  final List<ExportFormat> exportedFormats = [];
  bool shouldThrow = false;

  @override
  Future<XFile> exportarVeiculo(
    String placa, {
    ExportFormat format = ExportFormat.xlsx,
  }) async {
    if (shouldThrow) throw Exception('Falha simulada');
    exportedPlacas.add(placa);
    exportedFormats.add(format);
    return XFile('fake.xlsx');
  }

  @override
  Future<XFile> exportarVeiculoXlsx(String placa) async {
    exportedPlacas.add(placa);
    return XFile('fake.xlsx');
  }

  @override
  Future<XFile> exportarVeiculoZip(String placa) async {
    exportedPlacas.add(placa);
    return XFile('fake.zip');
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

Future<void> _seedVeiculo(
  AppDatabase db, {
  String placa = 'ABC1D23',
  bool arquivado = false,
}) async {
  await db.veiculosDao.insertVeiculo(
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
  if (arquivado) {
    await db.veiculosDao.arquivar(placa);
  }
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

  testWidgets('exibe botão Exportar quando há veículo', (tester) async {
    await _seedVeiculo(db);
    await _pump(tester, db: db, fakeExport: fakeExport, placaAtiva: 'ABC1D23');
    expect(find.text('Exportar'), findsOneWidget);
    await _teardownUI(tester);
  });

  testWidgets('dropdown de veículo é exibido com veículo cadastrado', (
    tester,
  ) async {
    await _seedVeiculo(db);
    await _pump(tester, db: db, fakeExport: fakeExport, placaAtiva: 'ABC1D23');
    expect(find.textContaining('ABC1D23'), findsWidgets);
    await _teardownUI(tester);
  });

  testWidgets('toque no botão chama exportarVeiculo com a placa selecionada', (
    tester,
  ) async {
    await _seedVeiculo(db);
    await _pump(tester, db: db, fakeExport: fakeExport, placaAtiva: 'ABC1D23');

    await tester.tap(find.text('Exportar'));
    // Pump para deixar o Future do fake completar; share_plus pode não estar
    // disponível no ambiente de teste (MissingPluginException).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(fakeExport.exportedPlacas, contains('ABC1D23'));
    await _teardownUI(tester);
  });

  testWidgets('mostra snackbar de sucesso após exportação bem-sucedida', (
    tester,
  ) async {
    await _seedVeiculo(db);
    await _pump(tester, db: db, fakeExport: fakeExport, placaAtiva: 'ABC1D23');

    await tester.tap(find.text('Exportar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Arquivo exportado com sucesso!'), findsOneWidget);
    await _teardownUI(tester);
  });

  testWidgets('mostra snackbar de erro quando exportação falha', (
    tester,
  ) async {
    fakeExport.shouldThrow = true;
    await _seedVeiculo(db);
    await _pump(tester, db: db, fakeExport: fakeExport, placaAtiva: 'ABC1D23');

    await tester.tap(find.text('Exportar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Erro ao exportar:'), findsOneWidget);
    await _teardownUI(tester);
  });

  testWidgets('botão Exportar fica desabilitado enquanto exporta', (
    tester,
  ) async {
    final slowFake = _SlowExportService();
    await _seedVeiculo(db);
    await _pump(tester, db: db, fakeExport: slowFake, placaAtiva: 'ABC1D23');

    await tester.tap(find.text('Exportar'));
    await tester.pump();

    final btn = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Exportar'),
    );
    expect(
      btn.onPressed,
      isNull,
      reason: 'botão deve estar desabilitado durante exportação',
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Completa o fake — mas NÃO usa pumpAndSettle pois SharePlus pode não
    // estar disponível no ambiente de teste e causaria timeout.
    slowFake.completer.complete(XFile('fake.xlsx'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await _teardownUI(tester);
  });

  testWidgets('sem veículo selecionado botão Exportar não é exibido', (
    tester,
  ) async {
    await _pump(tester, db: db, fakeExport: fakeExport);
    expect(find.text('Exportar'), findsNothing);
    expect(find.text('Selecione um veículo para exportar.'), findsOneWidget);
    await _teardownUI(tester);
  });

  // ── Testes do toggle de formato ─────────────────────────────────────────────

  testWidgets('toggle de formato XLSX/ZIP é exibido quando há veículo', (
    tester,
  ) async {
    await _seedVeiculo(db);
    await _pump(tester, db: db, fakeExport: fakeExport, placaAtiva: 'ABC1D23');

    expect(find.text('Formato'), findsOneWidget);
    expect(find.text('XLSX (planilha)'), findsOneWidget);
    expect(find.text('ZIP (CSVs)'), findsOneWidget);
    await _teardownUI(tester);
  });

  testWidgets('default é XLSX e chama exportarVeiculo com format=xlsx', (
    tester,
  ) async {
    await _seedVeiculo(db);
    await _pump(tester, db: db, fakeExport: fakeExport, placaAtiva: 'ABC1D23');

    await tester.tap(find.text('Exportar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(fakeExport.exportedFormats.last, ExportFormat.xlsx);
    await _teardownUI(tester);
  });

  testWidgets('selecionando ZIP e exportando chama com format=zip', (
    tester,
  ) async {
    await _seedVeiculo(db);
    await _pump(tester, db: db, fakeExport: fakeExport, placaAtiva: 'ABC1D23');

    // Seleciona ZIP
    await tester.tap(find.text('ZIP (CSVs)'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Exportar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(fakeExport.exportedFormats.last, ExportFormat.zip);
    await _teardownUI(tester);
  });

  // ── Testes do badge de arquivado ────────────────────────────────────────────

  testWidgets('veículo arquivado aparece no dropdown com badge "arquivado"', (
    tester,
  ) async {
    await _seedVeiculo(db, placa: 'ABC1D23'); // ativo
    await _seedVeiculo(db, placa: 'XYZ9X99', arquivado: true); // arquivado
    await _pump(tester, db: db, fakeExport: fakeExport, placaAtiva: 'ABC1D23');

    // Abre o dropdown
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('arquivado'), findsOneWidget);
    await _teardownUI(tester);
  });
}

// ── Fake lento para testar loading indicator ─────────────────────────────────

class _SlowExportService implements ExportService {
  final completer = Completer<XFile>();

  @override
  Future<XFile> exportarVeiculo(
    String placa, {
    ExportFormat format = ExportFormat.xlsx,
  }) => completer.future;

  @override
  Future<XFile> exportarVeiculoXlsx(String placa) => completer.future;

  @override
  Future<XFile> exportarVeiculoZip(String placa) => completer.future;
}
