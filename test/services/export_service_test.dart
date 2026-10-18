import 'dart:convert';
import 'dart:io';

import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/services/export_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
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
    // Cria um diretório temporário real para os testes (evita MissingPluginException
    // do path_provider em ambiente de teste sem plataforma).
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
    // Limpa o diretório temporário de teste
    if (testTmpDir.existsSync()) {
      await testTmpDir.delete(recursive: true);
    }
  });

  group('ExportService.exportarVeiculo', () {
    test('gera exatamente 5 arquivos CSV', () async {
      await inserirVeiculo(db);
      final files = await service.exportarVeiculo(_kPlaca);
      expect(files, hasLength(5));
      final names = files.map((f) => f.name).toList();
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
    });

    test('todos os arquivos têm UTF-8 BOM no início', () async {
      await inserirVeiculo(db);
      final files = await service.exportarVeiculo(_kPlaca);
      for (final xfile in files) {
        final bytes = await File(xfile.path).readAsBytes();
        expect(bytes.length >= 3, isTrue, reason: '${xfile.name} está vazio');
        expect(bytes[0], equals(0xEF), reason: '${xfile.name}: byte 0 do BOM');
        expect(bytes[1], equals(0xBB), reason: '${xfile.name}: byte 1 do BOM');
        expect(bytes[2], equals(0xBF), reason: '${xfile.name}: byte 2 do BOM');
      }
    });

    test(
      'abastecimentos.csv contém dados corretos e usa ponto decimal',
      () async {
        await inserirVeiculo(db);
        await inserirAbastecimento(
          db,
          litros: 40.5,
          preco: 5.99,
          valor: 242.60,
        );
        final files = await service.exportarVeiculo(_kPlaca);
        final csv = files.firstWhere((f) => f.name == 'abastecimentos.csv');
        final content = await readCsvContent(csv.path);

        expect(content, contains('2024-03-15'));
        expect(content, contains('40.50'));
        expect(content, contains('5.99'));
        expect(content, contains('242.60'));
        expect(content, contains('gasolina'));
        expect(content, contains('true'));
      },
    );

    test('datas no formato yyyy-MM-dd', () async {
      await inserirVeiculo(db);
      await inserirAbastecimento(db);
      await inserirManutencao(db);
      final files = await service.exportarVeiculo(_kPlaca);

      final csvAbast = files.firstWhere((f) => f.name == 'abastecimentos.csv');
      expect(await readCsvContent(csvAbast.path), contains('2024-03-15'));

      final csvManut = files.firstWhere((f) => f.name == 'manutencoes.csv');
      expect(await readCsvContent(csvManut.path), contains('2024-01-10'));
    });

    test('escape: célula com vírgula é envolta em aspas duplas', () async {
      await inserirVeiculo(db);
      await inserirAbastecimento(db, posto: 'Posto A, B');
      final files = await service.exportarVeiculo(_kPlaca);
      final csv = files.firstWhere((f) => f.name == 'abastecimentos.csv');
      final content = await readCsvContent(csv.path);
      expect(content, contains('"Posto A, B"'));
    });

    test('escape: célula com aspas duplas usa ""', () async {
      await inserirVeiculo(db);
      await inserirAbastecimento(db, posto: 'Posto "Top"');
      final files = await service.exportarVeiculo(_kPlaca);
      final csv = files.firstWhere((f) => f.name == 'abastecimentos.csv');
      final content = await readCsvContent(csv.path);
      expect(content, contains('"Posto ""Top"""'));
    });

    test(
      'filtra por placa: exporta apenas dados do veículo selecionado',
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
        final files = await service.exportarVeiculo(_kPlaca);
        final csv = files.firstWhere((f) => f.name == 'abastecimentos.csv');
        final lines = (await readCsvContent(csv.path)).trim().split('\n');
        // Header + 1 linha de dados (apenas o veículo filtrado)
        expect(lines.length, equals(2));
      },
    );

    test('decimais sem separador de milhar (usa ponto)', () async {
      await inserirVeiculo(db);
      await inserirAbastecimento(db, litros: 1000.5, valor: 5997.99);
      final files = await service.exportarVeiculo(_kPlaca);
      final csv = files.firstWhere((f) => f.name == 'abastecimentos.csv');
      final content = await readCsvContent(csv.path);
      expect(content, contains('1000.50'));
      expect(content, contains('5997.99'));
      expect(content, isNot(contains('1.000,50')));
    });

    test('manutencoes.csv contém dados corretos', () async {
      await inserirVeiculo(db);
      await inserirManutencao(db);
      final files = await service.exportarVeiculo(_kPlaca);
      final csv = files.firstWhere((f) => f.name == 'manutencoes.csv');
      final content = await readCsvContent(csv.path);
      expect(content, contains('2024-01-10'));
      expect(content, contains('oleoMotor'));
      expect(content, contains('250.00'));
      expect(content, contains('Troca Certa'));
      expect(content, contains('Troca com filtro'));
    });

    test('despesas.csv contém dados corretos', () async {
      await inserirVeiculo(db);
      await inserirDespesa(db, nome: 'IPVA');
      final files = await service.exportarVeiculo(_kPlaca);
      final csv = files.firstWhere((f) => f.name == 'despesas.csv');
      final content = await readCsvContent(csv.path);
      expect(content, contains('IPVA'));
      expect(content, contains('1200.50'));
      expect(content, contains('anual'));
      expect(content, contains('2024-01-01'));
    });

    test('ocorrencias.csv contém nome da despesa e status', () async {
      await inserirVeiculo(db);
      final id = await inserirDespesa(db, nome: 'Seguro');
      await inserirOcorrencia(db, id);
      final files = await service.exportarVeiculo(_kPlaca);
      final csv = files.firstWhere((f) => f.name == 'ocorrencias.csv');
      final content = await readCsvContent(csv.path);
      expect(content, contains('Seguro'));
      expect(content, contains('2024-03-31'));
      expect(content, contains('paga'));
      expect(content, contains('2024-03-28'));
    });

    test('lembretes.csv contém dados corretos', () async {
      await inserirVeiculo(db);
      await inserirLembrete(db);
      final files = await service.exportarVeiculo(_kPlaca);
      final csv = files.firstWhere((f) => f.name == 'lembretes.csv');
      final content = await readCsvContent(csv.path);
      expect(content, contains('oleoMotor'));
      expect(content, contains('Trocar óleo do motor'));
      expect(content, contains('60000'));
      expect(content, contains('pendente'));
    });

    test('gera CSVs mesmo sem dados (apenas header)', () async {
      await inserirVeiculo(db);
      final files = await service.exportarVeiculo(_kPlaca);
      for (final xfile in files) {
        final lines = (await readCsvContent(xfile.path)).trim().split('\n');
        expect(
          lines.length,
          equals(1),
          reason: '${xfile.name}: esperado apenas header',
        );
      }
    });

    test(
      'escape: célula com quebra de linha é envolta em aspas duplas',
      () async {
        // Cobre o terceiro caso do _cell(): value.contains('\n')
        await inserirVeiculo(db);
        await inserirAbastecimento(db, posto: 'Posto\nNova Linha');
        final files = await service.exportarVeiculo(_kPlaca);
        final csv = files.firstWhere((f) => f.name == 'abastecimentos.csv');
        final content = await readCsvContent(csv.path);
        // A célula deve estar envolta em aspas e o \n preservado internamente.
        expect(content, contains('"Posto\nNova Linha"'));
      },
    );

    test('header de abastecimentos.csv é exatamente o esperado', () async {
      await inserirVeiculo(db);
      final files = await service.exportarVeiculo(_kPlaca);
      final csv = files.firstWhere((f) => f.name == 'abastecimentos.csv');
      final lines = (await readCsvContent(csv.path)).split('\n');
      expect(
        lines.first,
        equals(
          'data,km,tipo_combustivel,litros,preco,valor,posto,tanque_cheio,observacoes',
        ),
      );
    });

    test('header de lembretes.csv é exatamente o esperado', () async {
      await inserirVeiculo(db);
      final files = await service.exportarVeiculo(_kPlaca);
      final csv = files.firstWhere((f) => f.name == 'lembretes.csv');
      final lines = (await readCsvContent(csv.path)).split('\n');
      expect(lines.first, equals('tipo,descricao,data_alvo,km_alvo,status'));
    });

    test('header de ocorrencias.csv é exatamente o esperado', () async {
      await inserirVeiculo(db);
      final files = await service.exportarVeiculo(_kPlaca);
      final csv = files.firstWhere((f) => f.name == 'ocorrencias.csv');
      final lines = (await readCsvContent(csv.path)).split('\n');
      expect(
        lines.first,
        equals(
          'despesa_nome,data_vencimento,valor,status,data_pagamento,valor_pago',
        ),
      );
    });

    test('abastecimento de outra placa não aparece no CSV — linha de dados ausente', () async {
      const outraPlaca = 'OUT0O00';
      await inserirVeiculo(db);
      await db.veiculosDao.insertVeiculo(
        VeiculosCompanion.insert(
          placa: outraPlaca,
          marca: 'VW',
          modelo: 'Gol',
          ano: 2019,
          tipo: TipoVeiculo.carro,
          combustivel: TipoCombustivelVeiculo.flex,
          kmInicial: 1000,
        ),
      );
      // Insere apenas para outraPlaca; _kPlaca não tem dados.
      await inserirAbastecimento(db, placa: outraPlaca);
      final files = await service.exportarVeiculo(_kPlaca);
      final csv = files.firstWhere((f) => f.name == 'abastecimentos.csv');
      final lines = (await readCsvContent(csv.path)).trim().split('\n');
      // Deve haver somente o header (1 linha), pois _kPlaca não tem abastecimentos.
      expect(
        lines.length,
        equals(1),
        reason:
            'abastecimento de $outraPlaca não deve aparecer no CSV de $_kPlaca',
      );
    });

    test('ocorrencias.csv: valor usa o valor da despesa, não um campo inexistente', () async {
      // Garante que o campo "valor" em ocorrencias.csv vem de despesa.valor
      // (1200.50) e que valorPago distinto (999.99) aparece na coluna correta.
      await inserirVeiculo(db);
      final id = await inserirDespesa(db, nome: 'Seguro Auto');
      await db.ocorrenciasDespesaDao.insertOcorrencia(
        OcorrenciasDespesaCompanion.insert(
          despesaId: id,
          dataVencimento: DateTime(2024, 6, 1),
          status: StatusOcorrencia.paga,
          valorPago: const Value(999.99),
          dataPagamento: Value(DateTime(2024, 6, 1)),
        ),
      );
      final files = await service.exportarVeiculo(_kPlaca);
      final csv = files.firstWhere((f) => f.name == 'ocorrencias.csv');
      final content = await readCsvContent(csv.path);
      // Coluna "valor" deve conter 1200.50 (da despesa), não 999.99.
      final dataLine = content
          .split('\n')
          .skip(1)
          .firstWhere((l) => l.contains('Seguro Auto'));
      final cols = dataLine.split(',');
      // Ordem: despesa_nome(0), data_vencimento(1), valor(2), status(3),
      //        data_pagamento(4), valor_pago(5)
      expect(cols[2], equals('1200.50'), reason: 'valor deve ser o da despesa');
      expect(cols[5], equals('999.99'), reason: 'valor_pago deve ser o pago');
    });
  });
}
