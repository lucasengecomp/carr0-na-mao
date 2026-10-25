import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/services/export_labels.dart';
import 'package:carro_na_mao/services/export_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

const _kPlaca = 'ABC1D23';

// ── Helpers de seed ─────────────────────────────────────────────────────────

Future<void> inserirVeiculo(AppDatabase db, {String placa = _kPlaca}) async {
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
}

Future<void> inserirAbastecimento(
  AppDatabase db, {
  String placa = _kPlaca,
  double litros = 40.5,
  double preco = 5.99,
  double valor = 242.595,
  String? posto,
  bool tanqueCheio = true,
}) async {
  await db.abastecimentosDao.insertAbastecimento(
    AbastecimentosCompanion.insert(
      veiculoPlaca: placa,
      data: DateTime(2024, 3, 15),
      km: 50000,
      tipoCombustivel: TipoCombustivelAbastecimento.gasolina,
      precoLitro: preco,
      valorTotal: valor,
      litros: litros,
      posto: Value(posto),
      tanqueCheio: Value(tanqueCheio),
    ),
  );
}

Future<void> inserirManutencao(AppDatabase db) async {
  await db.manutencoesDao.insertManutencao(
    ManutencoesCompanion.insert(
      veiculoPlaca: _kPlaca,
      tipo: TipoManutencao.oleoMotor,
      data: DateTime(2024, 1, 10),
      km: 48000,
      valor: const Value(250.0),
      oficina: const Value('Troca Certa'),
      observacoes: const Value('Troca com filtro'),
    ),
  );
}

Future<int> inserirDespesa(AppDatabase db, {String nome = 'IPVA'}) async {
  return db.despesasRecorrentesDao.insertDespesa(
    DespesasRecorrentesCompanion.insert(
      veiculoPlaca: _kPlaca,
      nome: nome,
      categoria: CategoriaDespesa.outra,
      valor: 1200.50,
      frequencia: FrequenciaDespesa.anual,
      dataInicio: DateTime(2024, 1, 1),
    ),
  );
}

Future<void> inserirOcorrencia(AppDatabase db, int despesaId) async {
  await db.ocorrenciasDespesaDao.insertOcorrencia(
    OcorrenciasDespesaCompanion.insert(
      despesaId: despesaId,
      dataVencimento: DateTime(2024, 3, 31),
      status: StatusOcorrencia.paga,
      valorPago: const Value(1200.50),
      dataPagamento: Value(DateTime(2024, 3, 28)),
    ),
  );
}

Future<void> inserirLembrete(AppDatabase db) async {
  await db.lembretesDao.insertLembrete(
    LembretesCompanion.insert(
      veiculoPlaca: _kPlaca,
      tipo: 'oleoMotor',
      descricao: 'Trocar óleo do motor',
      dataAlvo: const Value(null),
      kmAlvo: const Value(60000),
      status: StatusLembrete.pendente,
    ),
  );
}

/// Lê o conteúdo de um arquivo CSV, removendo o BOM UTF-8 se presente.
Future<String> readCsvContent(String path) async {
  final bytes = await File(path).readAsBytes();
  // Remove BOM (3 bytes: EF BB BF)
  final withoutBom =
      (bytes.length >= 3 &&
          bytes[0] == 0xEF &&
          bytes[1] == 0xBB &&
          bytes[2] == 0xBF)
      ? bytes.sublist(3)
      : bytes;
  return utf8.decode(withoutBom);
}

// ── Testes ───────────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;
  late ExportService service;
  late Directory testTmpDir;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    testTmpDir = await Directory.systemTemp.createTemp('export_test_');
    service = ExportService(
      abastecimentosDao: db.abastecimentosDao,
      manutencoesDao: db.manutencoesDao,
      despesasDao: db.despesasRecorrentesDao,
      ocorrenciasDao: db.ocorrenciasDespesaDao,
      lembretesDao: db.lembretesDao,
      tempDirProvider: () async => testTmpDir,
    );
  });

  tearDown(() async {
    await db.close();
    if (testTmpDir.existsSync()) {
      await testTmpDir.delete(recursive: true);
    }
  });

  // ── Testes de labels PT-BR ────────────────────────────────────────────────

  group('export_labels: labelPt', () {
    test('TipoCombustivelAbastecimento.gasolina => "Gasolina"', () {
      expect(TipoCombustivelAbastecimento.gasolina.labelPt, 'Gasolina');
    });

    test('TipoCombustivelAbastecimento.alcool => "Álcool"', () {
      expect(TipoCombustivelAbastecimento.alcool.labelPt, 'Álcool');
    });

    test('TipoManutencao.oleoMotor => "Óleo do motor"', () {
      expect(TipoManutencao.oleoMotor.labelPt, 'Óleo do motor');
    });

    test('CategoriaDespesa.pedagio => "Pedágio"', () {
      expect(CategoriaDespesa.pedagio.labelPt, 'Pedágio');
    });

    test('FrequenciaDespesa.unica => "Única"', () {
      expect(FrequenciaDespesa.unica.labelPt, 'Única');
    });

    test('StatusOcorrencia.pendente => "Pendente"', () {
      expect(StatusOcorrencia.pendente.labelPt, 'Pendente');
    });

    test('StatusOcorrencia.paga => "Paga"', () {
      expect(StatusOcorrencia.paga.labelPt, 'Paga');
    });

    test('StatusLembrete.adiado => "Adiado"', () {
      expect(StatusLembrete.adiado.labelPt, 'Adiado');
    });

    test('nenhum enum retorna o nome interno (não tem ".name")', () {
      for (final v in TipoCombustivelAbastecimento.values) {
        expect(v.labelPt, isNot(equals(v.name)));
      }
      for (final v in TipoManutencao.values) {
        expect(v.labelPt, isNot(equals(v.name)));
      }
    });
  });

  // ── Testes XLSX ───────────────────────────────────────────────────────────

  group('ExportService.exportarVeiculoXlsx', () {
    test('gera arquivo .xlsx com 5 sheets', () async {
      await inserirVeiculo(db);
      final xFile = await service.exportarVeiculoXlsx(_kPlaca);
      expect(xFile.path, endsWith('.xlsx'));

      final bytes = await File(xFile.path).readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      expect(
        excel.sheets.keys,
        containsAll([
          'Abastecimentos',
          'Manutenções',
          'Despesas',
          'Ocorrências',
          'Lembretes',
        ]),
      );
      expect(excel.sheets.length, equals(5));
    });

    test('sheet Abastecimentos tem headers PT-BR na primeira linha', () async {
      await inserirVeiculo(db);
      final xFile = await service.exportarVeiculoXlsx(_kPlaca);

      final bytes = await File(xFile.path).readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Abastecimentos'];
      final headerRow = sheet.rows.first;
      final headers = headerRow
          .map((c) => (c?.value as TextCellValue?)?.value.text ?? '')
          .toList();

      expect(headers, contains('Data'));
      expect(headers, contains('Tipo de combustível'));
      expect(headers, contains('Tanque cheio'));
    });

    test('linha de dados de abastecimento usa labelPt e Sim/Não', () async {
      await inserirVeiculo(db);
      await inserirAbastecimento(db, tanqueCheio: true);
      final xFile = await service.exportarVeiculoXlsx(_kPlaca);

      final bytes = await File(xFile.path).readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Abastecimentos'];
      // Linha 0 = header, linha 1 = dados
      expect(sheet.rows.length, equals(2));

      final dataRow = sheet.rows[1];
      final values = dataRow.map((c) => c?.value?.toString() ?? '').toList();

      // Deve conter 'Gasolina' (labelPt), não 'gasolina'
      expect(values, contains('Gasolina'));
      // Deve conter 'Sim' (bool), não 'true'
      expect(values, contains('Sim'));
      expect(values, isNot(contains('true')));
      expect(values, isNot(contains('gasolina')));
    });

    test('sheet Manutenções usa labelPt para tipo', () async {
      await inserirVeiculo(db);
      await inserirManutencao(db);
      final xFile = await service.exportarVeiculoXlsx(_kPlaca);

      final bytes = await File(xFile.path).readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Manutenções'];
      expect(sheet.rows.length, equals(2));

      final dataRow = sheet.rows[1];
      final values = dataRow.map((c) => c?.value?.toString() ?? '').toList();
      expect(values, contains('Óleo do motor'));
      expect(values, isNot(contains('oleoMotor')));
    });

    test(
      'exportarVeiculo com format=xlsx delega para exportarVeiculoXlsx',
      () async {
        await inserirVeiculo(db);
        final xFile = await service.exportarVeiculo(
          _kPlaca,
          format: ExportFormat.xlsx,
        );
        expect(xFile.path, endsWith('.xlsx'));
      },
    );
  });

  // ── Testes ZIP ────────────────────────────────────────────────────────────

  group('ExportService.exportarVeiculoZip', () {
    test('gera arquivo .zip com 5 CSVs', () async {
      await inserirVeiculo(db);
      final xFile = await service.exportarVeiculoZip(_kPlaca);
      expect(xFile.path, endsWith('.zip'));

      final bytes = await File(xFile.path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final names = archive.map((f) => f.name).toList();
      expect(
        names,
        containsAll([
          'abastecimentos.csv',
          'manutencoes.csv',
          'despesas.csv',
          'ocorrencias.csv',
          'lembretes.csv',
        ]),
      );
      expect(names.length, equals(5));
    });

    test('CSVs dentro do ZIP têm BOM UTF-8', () async {
      await inserirVeiculo(db);
      final xFile = await service.exportarVeiculoZip(_kPlaca);

      final bytes = await File(xFile.path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final f in archive) {
        final content = f.content as List<int>;
        expect(content.length >= 3, isTrue, reason: '${f.name} não tem BOM');
        expect(content[0], equals(0xEF), reason: '${f.name}: byte 0 do BOM');
        expect(content[1], equals(0xBB), reason: '${f.name}: byte 1 do BOM');
        expect(content[2], equals(0xBF), reason: '${f.name}: byte 2 do BOM');
      }
    });

    test(
      'abastecimentos.csv no ZIP tem headers PT-BR e usa labelPt/Sim',
      () async {
        await inserirVeiculo(db);
        await inserirAbastecimento(db, tanqueCheio: false);
        final xFile = await service.exportarVeiculoZip(_kPlaca);

        final bytes = await File(xFile.path).readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        final f = archive.firstWhere((f) => f.name == 'abastecimentos.csv');
        final raw = f.content as List<int>;
        // Remove BOM
        final content = utf8.decode(raw.sublist(3));

        final lines = content.trim().split('\n');
        expect(lines[0], contains('Tipo de combustível'));
        expect(lines[0], contains('Tanque cheio'));
        expect(lines[0], isNot(contains('observacoes')));
        // Dados na linha 1
        expect(lines[1], contains('Gasolina'));
        expect(lines[1], contains('Não'));
        expect(lines[1], isNot(contains('false')));
        expect(lines[1], isNot(contains('gasolina')));
      },
    );

    test('manutencoes.csv no ZIP usa labelPt para tipo', () async {
      await inserirVeiculo(db);
      await inserirManutencao(db);
      final xFile = await service.exportarVeiculoZip(_kPlaca);

      final bytes = await File(xFile.path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final f = archive.firstWhere((f) => f.name == 'manutencoes.csv');
      final raw = f.content as List<int>;
      final content = utf8.decode(raw.sublist(3));

      expect(content, contains('Óleo do motor'));
      expect(content, isNot(contains('oleoMotor')));
    });

    test(
      'despesas.csv no ZIP usa labelPt para categoria e frequência',
      () async {
        await inserirVeiculo(db);
        await inserirDespesa(db);
        final xFile = await service.exportarVeiculoZip(_kPlaca);

        final bytes = await File(xFile.path).readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        final f = archive.firstWhere((f) => f.name == 'despesas.csv');
        final raw = f.content as List<int>;
        final content = utf8.decode(raw.sublist(3));

        // categoria=outra -> 'Outra', frequencia=anual -> 'Anual'
        expect(content, contains('Outra'));
        expect(content, contains('Anual'));
        expect(content, isNot(contains(',outra,')));
        expect(content, isNot(contains(',anual,')));
      },
    );

    test(
      'exportarVeiculo com format=zip delega para exportarVeiculoZip',
      () async {
        await inserirVeiculo(db);
        final xFile = await service.exportarVeiculo(
          _kPlaca,
          format: ExportFormat.zip,
        );
        expect(xFile.path, endsWith('.zip'));
      },
    );

    test('gera ZIP mesmo sem dados (apenas headers)', () async {
      await inserirVeiculo(db);
      final xFile = await service.exportarVeiculoZip(_kPlaca);

      final bytes = await File(xFile.path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final f in archive) {
        final raw = f.content as List<int>;
        final content = utf8.decode(raw.sublist(3));
        final lines = content.trim().split('\n');
        expect(
          lines.length,
          equals(1),
          reason: '${f.name}: esperado apenas header',
        );
      }
    });
  });

  // ── Testes de compatibilidade (exportarVeiculo sem formato = xlsx) ─────────

  group('ExportService.exportarVeiculo (compatibilidade)', () {
    test('default é XLSX', () async {
      await inserirVeiculo(db);
      final xFile = await service.exportarVeiculo(_kPlaca);
      expect(xFile.path, endsWith('.xlsx'));
    });

    test('nome do arquivo inclui placa e data', () async {
      await inserirVeiculo(db);
      final xFile = await service.exportarVeiculoXlsx(_kPlaca);
      expect(xFile.name, contains(_kPlaca));
      expect(xFile.name, matches(RegExp(r'\d{4}-\d{2}-\d{2}')));
    });

    test(
      'filtra por placa: abastecimentos de outra placa não aparecem',
      () async {
        const outraPlaca = 'XYZ9X99';
        await inserirVeiculo(db);
        await db.veiculosDao.insertVeiculo(
          VeiculosCompanion.insert(
            placa: outraPlaca,
            marca: 'Honda',
            modelo: 'Civic',
            ano: 2021,
            tipo: TipoVeiculo.carro,
            combustivel: TipoCombustivelVeiculo.flex,
            kmInicial: 5000,
          ),
        );
        await inserirAbastecimento(db); // placa = _kPlaca
        await inserirAbastecimento(db, placa: outraPlaca); // outro veículo

        final xFile = await service.exportarVeiculoZip(_kPlaca);
        final bytes = await File(xFile.path).readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        final f = archive.firstWhere((f) => f.name == 'abastecimentos.csv');
        final raw = f.content as List<int>;
        final content = utf8.decode(raw.sublist(3));
        final lines = content.trim().split('\n');
        expect(lines.length, equals(2)); // header + 1 linha
      },
    );

    test('escape: célula com vírgula é envolta em aspas duplas', () async {
      await inserirVeiculo(db);
      await inserirAbastecimento(db, posto: 'Posto A, B');
      final xFile = await service.exportarVeiculoZip(_kPlaca);
      final bytes = await File(xFile.path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final f = archive.firstWhere((f) => f.name == 'abastecimentos.csv');
      final raw = f.content as List<int>;
      final content = utf8.decode(raw.sublist(3));
      expect(content, contains('"Posto A, B"'));
    });

    test('escape: célula com aspas duplas usa ""', () async {
      await inserirVeiculo(db);
      await inserirAbastecimento(db, posto: 'Posto "Top"');
      final xFile = await service.exportarVeiculoZip(_kPlaca);
      final bytes = await File(xFile.path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final f = archive.firstWhere((f) => f.name == 'abastecimentos.csv');
      final raw = f.content as List<int>;
      final content = utf8.decode(raw.sublist(3));
      expect(content, contains('"Posto ""Top"""'));
    });

    test('datas no formato yyyy-MM-dd', () async {
      await inserirVeiculo(db);
      await inserirAbastecimento(db);
      final xFile = await service.exportarVeiculoZip(_kPlaca);
      final bytes = await File(xFile.path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final f = archive.firstWhere((f) => f.name == 'abastecimentos.csv');
      final raw = f.content as List<int>;
      final content = utf8.decode(raw.sublist(3));
      expect(content, contains('2024-03-15'));
    });

    test('decimais sem separador de milhar (usa ponto)', () async {
      await inserirVeiculo(db);
      await inserirAbastecimento(db, litros: 1000.5, valor: 5997.99);
      final xFile = await service.exportarVeiculoZip(_kPlaca);
      final bytes = await File(xFile.path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final f = archive.firstWhere((f) => f.name == 'abastecimentos.csv');
      final raw = f.content as List<int>;
      final content = utf8.decode(raw.sublist(3));
      expect(content, contains('1000.50'));
      expect(content, contains('5997.99'));
      expect(content, isNot(contains('1.000,50')));
    });

    test('manutencoes.csv contém dados corretos', () async {
      await inserirVeiculo(db);
      await inserirManutencao(db);
      final xFile = await service.exportarVeiculoZip(_kPlaca);
      final bytes = await File(xFile.path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final f = archive.firstWhere((f) => f.name == 'manutencoes.csv');
      final raw = f.content as List<int>;
      final content = utf8.decode(raw.sublist(3));
      expect(content, contains('2024-01-10'));
      expect(content, contains('Óleo do motor'));
      expect(content, contains('250.00'));
      expect(content, contains('Troca Certa'));
      expect(content, contains('Troca com filtro'));
    });

    test('ocorrencias.csv contém nome da despesa e status PT-BR', () async {
      await inserirVeiculo(db);
      final id = await inserirDespesa(db, nome: 'Seguro');
      await inserirOcorrencia(db, id);
      final xFile = await service.exportarVeiculoZip(_kPlaca);
      final bytes = await File(xFile.path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final f = archive.firstWhere((f) => f.name == 'ocorrencias.csv');
      final raw = f.content as List<int>;
      final content = utf8.decode(raw.sublist(3));
      expect(content, contains('Seguro'));
      expect(content, contains('2024-03-31'));
      expect(content, contains('Paga'));
      expect(content, contains('2024-03-28'));
    });

    test('lembretes.csv contém dados corretos', () async {
      await inserirVeiculo(db);
      await inserirLembrete(db);
      final xFile = await service.exportarVeiculoZip(_kPlaca);
      final bytes = await File(xFile.path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final f = archive.firstWhere((f) => f.name == 'lembretes.csv');
      final raw = f.content as List<int>;
      final content = utf8.decode(raw.sublist(3));
      expect(content, contains('oleoMotor')); // tipo é texto livre, não enum
      expect(content, contains('Trocar óleo do motor'));
      expect(content, contains('60000'));
      expect(content, contains('Pendente'));
    });
  });
}
