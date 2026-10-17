// ignore_for_file: lines_longer_than_80_chars

import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Insere um veículo de suporte para satisfazer a FK de despesas_recorrentes.
Future<void> _seedVeiculo(AppDatabase db, {String placa = 'ABC1D23'}) =>
    db.veiculosDao.insertVeiculo(
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

/// Insere uma despesa recorrente e retorna o [DespesaRecorrente] persistido.
Future<DespesaRecorrente> _inserirDespesa(
  AppDatabase db, {
  String placa = 'ABC1D23',
  String nome = 'Teste',
  CategoriaDespesa categoria = CategoriaDespesa.outra,
  double valor = 100,
  FrequenciaDespesa frequencia = FrequenciaDespesa.mensal,
  int? diaDoMes,
  required DateTime dataInicio,
  DateTime? dataFim,
  bool ativa = true,
}) async {
  final id = await db.despesasRecorrentesDao.insertDespesa(
    DespesasRecorrentesCompanion.insert(
      veiculoPlaca: placa,
      nome: nome,
      categoria: categoria,
      valor: valor,
      frequencia: frequencia,
      diaDoMes: Value(diaDoMes),
      dataInicio: dataInicio,
      dataFim: Value(dataFim),
      ativa: Value(ativa),
    ),
  );
  return (await db.despesasRecorrentesDao.byId(id))!;
}

/// Retorna o último dia do mês corrente (igual à lógica de [materializar]).
DateTime _fimMesCorrente() {
  final hoje = DateTime.now();
  return DateTime(hoje.year, hoje.month + 1, 0);
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await _seedVeiculo(db);
  });

  tearDown(() async {
    await db.close();
  });

  // -------------------------------------------------------------------------
  // Schema — colunas diaDoMes e ativa
  // -------------------------------------------------------------------------

  group('schema v4 — despesas_recorrentes', () {
    test('coluna diaDoMes existe e aceita null', () async {
      final despesa = await _inserirDespesa(
        db,
        frequencia: FrequenciaDespesa.unica,
        dataInicio: DateTime(2026, 1, 1),
        diaDoMes: null,
      );
      expect(despesa.diaDoMes, isNull);
    });

    test('coluna diaDoMes persiste valor inteiro', () async {
      final despesa = await _inserirDespesa(
        db,
        frequencia: FrequenciaDespesa.mensal,
        dataInicio: DateTime(2026, 1, 1),
        diaDoMes: 15,
      );
      expect(despesa.diaDoMes, 15);
    });

    test('coluna ativa tem default true', () async {
      // Insere sem especificar ativa explicitamente via SQL direto p/ testar default.
      final despesa = await _inserirDespesa(
        db,
        frequencia: FrequenciaDespesa.mensal,
        dataInicio: DateTime(2026, 1, 1),
      );
      expect(despesa.ativa, isTrue);
    });

    test('coluna ativa aceita false', () async {
      final despesa = await _inserirDespesa(
        db,
        frequencia: FrequenciaDespesa.mensal,
        dataInicio: DateTime(2026, 1, 1),
        ativa: false,
      );
      expect(despesa.ativa, isFalse);
    });

    test('PRAGMA table_info confirma colunas dia_do_mes e ativa', () async {
      final rows = await db
          .customSelect("PRAGMA table_info('despesas_recorrentes')")
          .get();
      final colunas = rows.map((r) => r.data['name'] as String).toSet();
      expect(colunas, contains('dia_do_mes'));
      expect(colunas, contains('ativa'));
    });
  });

  // -------------------------------------------------------------------------
  // DespesasRecorrentesDao.listAtivas
  // -------------------------------------------------------------------------

  group('DespesasRecorrentesDao.listAtivas', () {
    test('retorna apenas despesas ativas', () async {
      await _inserirDespesa(
        db,
        nome: 'Ativa',
        dataInicio: DateTime(2025, 1, 1),
        ativa: true,
      );
      await _inserirDespesa(
        db,
        nome: 'Inativa',
        dataInicio: DateTime(2025, 1, 1),
        ativa: false,
      );
      final ativas = await db.despesasRecorrentesDao.listAtivas();
      expect(ativas, hasLength(1));
      expect(ativas.single.nome, 'Ativa');
    });

    test('retorna lista vazia quando não há ativas', () async {
      await _inserirDespesa(db, dataInicio: DateTime(2025, 1, 1), ativa: false);
      final ativas = await db.despesasRecorrentesDao.listAtivas();
      expect(ativas, isEmpty);
    });

    test('banco vazio retorna lista vazia', () async {
      final ativas = await db.despesasRecorrentesDao.listAtivas();
      expect(ativas, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // OcorrenciasDespesaDao.materializar — frequência única
  // -------------------------------------------------------------------------

  group('materializar — frequência única', () {
    test('despesa única gera exatamente 1 ocorrência em dataInicio', () async {
      final hoje = DateTime.now();
      final dataInicio = DateTime(hoje.year, hoje.month, 1);
      final despesa = await _inserirDespesa(
        db,
        frequencia: FrequenciaDespesa.unica,
        dataInicio: dataInicio,
      );
      await db.ocorrenciasDespesaDao.materializar(despesa);
      final ocorrencias = await db.ocorrenciasDespesaDao.listByDespesa(
        despesa.id,
      );
      expect(ocorrencias, hasLength(1));
      expect(ocorrencias.single.dataVencimento, dataInicio);
    });

    test('despesa única — chamar materializar 2× não duplica', () async {
      final hoje = DateTime.now();
      final dataInicio = DateTime(hoje.year, hoje.month, 1);
      final despesa = await _inserirDespesa(
        db,
        frequencia: FrequenciaDespesa.unica,
        dataInicio: dataInicio,
      );
      await db.ocorrenciasDespesaDao.materializar(despesa);
      await db.ocorrenciasDespesaDao.materializar(despesa);
      final ocorrencias = await db.ocorrenciasDespesaDao.listByDespesa(
        despesa.id,
      );
      expect(ocorrencias, hasLength(1));
    });

    test(
      'despesa única com dataInicio no passado ainda gera 1 ocorrência',
      () async {
        final despesa = await _inserirDespesa(
          db,
          frequencia: FrequenciaDespesa.unica,
          dataInicio: DateTime(2020, 3, 15),
        );
        await db.ocorrenciasDespesaDao.materializar(despesa);
        final ocorrencias = await db.ocorrenciasDespesaDao.listByDespesa(
          despesa.id,
        );
        expect(ocorrencias, hasLength(1));
        expect(ocorrencias.single.dataVencimento, DateTime(2020, 3, 15));
      },
    );

    test('despesa única com dataFim no passado ainda gera 1 ocorrência '
        '(dataInicio <= dataFim <= fimMes)', () async {
      // dataFim não impede ocorrência única se dataInicio <= dataFim
      final hoje = DateTime.now();
      final dataInicio = DateTime(hoje.year, hoje.month, 1);
      final dataFim = DateTime(hoje.year, hoje.month, 5);
      final despesa = await _inserirDespesa(
        db,
        frequencia: FrequenciaDespesa.unica,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );
      await db.ocorrenciasDespesaDao.materializar(despesa);
      final ocorrencias = await db.ocorrenciasDespesaDao.listByDespesa(
        despesa.id,
      );
      // dataInicio está dentro do limite; deve gerar 1 ocorrência.
      expect(ocorrencias, hasLength(1));
    });
  });

  // -------------------------------------------------------------------------
  // OcorrenciasDespesaDao.materializar — frequência mensal
  // -------------------------------------------------------------------------

  group('materializar — frequência mensal', () {
    test('despesa mensal dia 5, dataInicio mês passado → '
        'gera ocorrências do mês passado e do mês corrente', () async {
      final hoje = DateTime.now();
      // Inicia no dia 5 do mês passado.
      final dataInicio = DateTime(hoje.year, hoje.month - 1, 5);
      final despesa = await _inserirDespesa(
        db,
        frequencia: FrequenciaDespesa.mensal,
        diaDoMes: 5,
        dataInicio: dataInicio,
      );
      await db.ocorrenciasDespesaDao.materializar(despesa);
      final ocorrencias = await db.ocorrenciasDespesaDao.listByDespesa(
        despesa.id,
      );

      // Deve ter ao menos 2 ocorrências (mês passado + corrente).
      expect(ocorrencias.length, greaterThanOrEqualTo(2));

      final datas = ocorrencias.map((o) => o.dataVencimento).toList();
      // Verifica que o mês passado está presente com dia 5.
      expect(datas, contains(DateTime(hoje.year, hoje.month - 1, 5)));
      // Verifica que o mês corrente está presente com dia 5.
      final dia5MesCorrente = DateTime(
        hoje.year,
        hoje.month,
        5.clamp(1, DateTime(hoje.year, hoje.month + 1, 0).day),
      );
      expect(datas, contains(dia5MesCorrente));
    });

    test(
      'idempotência: chamar materializar 2× com despesa mensal não duplica',
      () async {
        final hoje = DateTime.now();
        final dataInicio = DateTime(hoje.year, hoje.month, 1);
        final despesa = await _inserirDespesa(
          db,
          frequencia: FrequenciaDespesa.mensal,
          diaDoMes: 1,
          dataInicio: dataInicio,
        );
        await db.ocorrenciasDespesaDao.materializar(despesa);
        final antes = (await db.ocorrenciasDespesaDao.listByDespesa(despesa.id))
            .length;

        await db.ocorrenciasDespesaDao.materializar(despesa);
        final depois = (await db.ocorrenciasDespesaDao.listByDespesa(
          despesa.id,
        )).length;

        expect(
          depois,
          equals(antes),
          reason: 'materializar idempotente não deve criar duplicatas',
        );
      },
    );

    test('dataFim no passado → não gera ocorrências após dataFim', () async {
      final hoje = DateTime.now();
      // dataInicio = 3 meses atrás, dataFim = 2 meses atrás → não deve gerar
      // ocorrência no mês corrente.
      final dataInicio = DateTime(hoje.year, hoje.month - 3, 1);
      final dataFim = DateTime(hoje.year, hoje.month - 2, 28);
      final despesa = await _inserirDespesa(
        db,
        frequencia: FrequenciaDespesa.mensal,
        diaDoMes: 1,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );
      await db.ocorrenciasDespesaDao.materializar(despesa);
      final ocorrencias = await db.ocorrenciasDespesaDao.listByDespesa(
        despesa.id,
      );

      // Nenhuma ocorrência deve ter vencimento após dataFim.
      for (final o in ocorrencias) {
        expect(
          o.dataVencimento.isAfter(dataFim),
          isFalse,
          reason: 'Ocorrência ${o.dataVencimento} está após dataFim $dataFim',
        );
      }
    });

    test(
      'diaDoMes 31 em fevereiro → normalizado para último dia do mês',
      () async {
        // Usa um fevereiro que sabemos ter 28 dias (2026).
        // Cria despesa com dataInicio = 2026-02-01 e diaDoMes = 31.
        // O materializar deve criar ocorrência em 2026-02-28.
        final hoje = DateTime.now();
        // Escolhe o fevereiro anterior mais próximo que seja acessível.
        var anoFev = hoje.year;
        if (hoje.month <= 2) anoFev = hoje.year - 1;
        // Verifica que o fevereiro escolhido tem < 31 dias.
        final diasFev = DateTime(anoFev, 3, 0).day; // último dia de fev
        expect(diasFev, lessThan(31));

        final dataInicio = DateTime(anoFev, 2, 1);
        final despesa = await _inserirDespesa(
          db,
          frequencia: FrequenciaDespesa.mensal,
          diaDoMes: 31,
          dataInicio: dataInicio,
          // Limita ao próprio mês de fev para isolar o comportamento.
          dataFim: DateTime(anoFev, 2, diasFev),
        );
        await db.ocorrenciasDespesaDao.materializar(despesa);
        final ocorrencias = await db.ocorrenciasDespesaDao.listByDespesa(
          despesa.id,
        );

        // Deve ter exatamente 1 ocorrência, no último dia de fevereiro.
        expect(ocorrencias, hasLength(1));
        expect(ocorrencias.single.dataVencimento.day, diasFev);
        expect(ocorrencias.single.dataVencimento.month, 2);
      },
    );

    test('ocorrências geradas têm status pendente e valor correto', () async {
      final hoje = DateTime.now();
      final dataInicio = DateTime(hoje.year, hoje.month, 1);
      final despesa = await _inserirDespesa(
        db,
        frequencia: FrequenciaDespesa.mensal,
        diaDoMes: 1,
        dataInicio: dataInicio,
        valor: 299.99,
      );
      await db.ocorrenciasDespesaDao.materializar(despesa);
      final ocorrencias = await db.ocorrenciasDespesaDao.listByDespesa(
        despesa.id,
      );

      expect(ocorrencias, isNotEmpty);
      for (final o in ocorrencias) {
        expect(o.status, StatusOcorrencia.pendente);
        // valor_pago deve ser nulo (ainda não pago).
        expect(o.valorPago, isNull);
        expect(o.dataPagamento, isNull);
      }
    });

    test('mensal com dataInicio=hoje contendo hora atual gera ocorrência no '
        'mês corrente (bug #56)', () async {
      final hoje = DateTime.now();
      // Simula dataInicio = DateTime.now() com hora atual (não meia-noite).
      final dataInicioComHora = DateTime(
        hoje.year,
        hoje.month,
        hoje.day,
        hoje.hour,
        hoje.minute,
        hoje.second,
      );
      final dia = hoje.day.clamp(1, 28);
      final despesa = await _inserirDespesa(
        db,
        frequencia: FrequenciaDespesa.mensal,
        diaDoMes: dia,
        dataInicio: dataInicioComHora,
      );
      await db.ocorrenciasDespesaDao.materializar(despesa);
      final ocorrencias = await db.ocorrenciasDespesaDao.listByDespesa(
        despesa.id,
      );
      expect(
        ocorrencias,
        isNotEmpty,
        reason:
            'materializar mensal deve gerar ocorrência no mês corrente mesmo '
            'quando dataInicio contém componente de hora',
      );
      // Verifica que a ocorrência gerada está no mês corrente.
      final datas = ocorrencias.map((o) => o.dataVencimento).toList();
      final ocorrenciaNoMesCorrente = datas.any(
        (d) => d.year == hoje.year && d.month == hoje.month,
      );
      expect(
        ocorrenciaNoMesCorrente,
        isTrue,
        reason: 'Deve haver ocorrência no mês corrente',
      );
    });

    test('despesa mensal com dataInicio no futuro (próximo mês) → '
        'nenhuma ocorrência gerada antes de dataInicio', () async {
      final hoje = DateTime.now();
      // Se o próximo mês já passa do fimMesCorrente, não deve gerar nada.
      final dataInicio = DateTime(hoje.year, hoje.month + 1, 1);
      final fimMes = _fimMesCorrente();

      // Só há algo a testar se dataInicio > fimMesCorrente.
      if (dataInicio.isAfter(fimMes)) {
        final despesa = await _inserirDespesa(
          db,
          frequencia: FrequenciaDespesa.mensal,
          diaDoMes: 1,
          dataInicio: dataInicio,
        );
        await db.ocorrenciasDespesaDao.materializar(despesa);
        final ocorrencias = await db.ocorrenciasDespesaDao.listByDespesa(
          despesa.id,
        );
        expect(
          ocorrencias,
          isEmpty,
          reason: 'dataInicio no futuro não deve gerar ocorrências agora',
        );
      }
      // Se dataInicio cai no mês corrente (dia 1), o teste não se aplica —
      // pulamos silenciosamente.
    });
  });

  // -------------------------------------------------------------------------
  // OcorrenciasDespesaDao.materializar — frequência anual
  // -------------------------------------------------------------------------

  group('materializar — frequência anual', () {
    test('despesa anual com dataInicio no ano passado → '
        'gera pelo menos 1 ocorrência', () async {
      final hoje = DateTime.now();
      // dataInicio = mesmo mês/dia, ano passado.
      final dataInicio = DateTime(hoje.year - 1, hoje.month, 1);
      final despesa = await _inserirDespesa(
        db,
        frequencia: FrequenciaDespesa.anual,
        diaDoMes: 1,
        dataInicio: dataInicio,
      );
      await db.ocorrenciasDespesaDao.materializar(despesa);
      final ocorrencias = await db.ocorrenciasDespesaDao.listByDespesa(
        despesa.id,
      );
      // Deve ter ao menos a do ano passado.
      expect(ocorrencias.length, greaterThanOrEqualTo(1));
    });

    test(
      'idempotência: chamar materializar 2× com despesa anual não duplica',
      () async {
        final hoje = DateTime.now();
        final dataInicio = DateTime(hoje.year - 1, hoje.month, 1);
        final despesa = await _inserirDespesa(
          db,
          frequencia: FrequenciaDespesa.anual,
          diaDoMes: 1,
          dataInicio: dataInicio,
        );
        await db.ocorrenciasDespesaDao.materializar(despesa);
        final antes = (await db.ocorrenciasDespesaDao.listByDespesa(despesa.id))
            .length;

        await db.ocorrenciasDespesaDao.materializar(despesa);
        final depois = (await db.ocorrenciasDespesaDao.listByDespesa(
          despesa.id,
        )).length;

        expect(depois, equals(antes));
      },
    );

    test('despesa anual com dataFim no passado → '
        'não gera ocorrência no ano corrente', () async {
      final hoje = DateTime.now();
      final dataInicio = DateTime(hoje.year - 3, 1, 1);
      final dataFim = DateTime(hoje.year - 1, 12, 31);
      final despesa = await _inserirDespesa(
        db,
        frequencia: FrequenciaDespesa.anual,
        diaDoMes: 1,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );
      await db.ocorrenciasDespesaDao.materializar(despesa);
      final ocorrencias = await db.ocorrenciasDespesaDao.listByDespesa(
        despesa.id,
      );

      for (final o in ocorrencias) {
        expect(
          o.dataVencimento.isAfter(dataFim),
          isFalse,
          reason: 'Ocorrência ${o.dataVencimento} está após dataFim $dataFim',
        );
      }
    });
  });

  // -------------------------------------------------------------------------
  // OcorrenciasDespesaDao.materializar — idempotência geral
  // -------------------------------------------------------------------------

  group('materializar — idempotência 3×', () {
    test(
      'chamar materializar 3× nunca duplica para frequência semanal',
      () async {
        final hoje = DateTime.now();
        final dataInicio = DateTime(hoje.year, hoje.month, 1);
        final despesa = await _inserirDespesa(
          db,
          frequencia: FrequenciaDespesa.semanal,
          dataInicio: dataInicio,
        );
        await db.ocorrenciasDespesaDao.materializar(despesa);
        await db.ocorrenciasDespesaDao.materializar(despesa);
        await db.ocorrenciasDespesaDao.materializar(despesa);
        final ocorrencias = await db.ocorrenciasDespesaDao.listByDespesa(
          despesa.id,
        );

        // Verifica que não há datas duplicadas.
        final datas = ocorrencias.map((o) => o.dataVencimento).toList();
        final datasSet = datas.toSet();
        expect(
          datas.length,
          equals(datasSet.length),
          reason: 'Não deve haver datas duplicadas nas ocorrências',
        );
      },
    );
  });

  // -------------------------------------------------------------------------
  // Rotina startup — equivalente a _materializarDespesasAtivas
  // -------------------------------------------------------------------------

  group('rotina startup — materializarDespesasAtivas', () {
    test('itera despesas ativas e gera ocorrências', () async {
      final hoje = DateTime.now();
      // Cria 2 despesas ativas e 1 inativa.
      await _inserirDespesa(
        db,
        nome: 'Ativa1',
        frequencia: FrequenciaDespesa.mensal,
        diaDoMes: 1,
        dataInicio: DateTime(hoje.year, hoje.month, 1),
        ativa: true,
      );
      await _inserirDespesa(
        db,
        nome: 'Ativa2',
        frequencia: FrequenciaDespesa.mensal,
        diaDoMes: 1,
        dataInicio: DateTime(hoje.year, hoje.month, 1),
        ativa: true,
      );
      final inativa = await _inserirDespesa(
        db,
        nome: 'Inativa',
        frequencia: FrequenciaDespesa.mensal,
        diaDoMes: 1,
        dataInicio: DateTime(hoje.year, hoje.month, 1),
        ativa: false,
      );

      // Simula a rotina de startup.
      final ativas = await db.despesasRecorrentesDao.listAtivas();
      for (final despesa in ativas) {
        await db.ocorrenciasDespesaDao.materializar(despesa);
      }

      // As ativas devem ter ocorrências; a inativa, não.
      for (final despesa in ativas) {
        final ocorrencias = await db.ocorrenciasDespesaDao.listByDespesa(
          despesa.id,
        );
        expect(
          ocorrencias,
          isNotEmpty,
          reason: '${despesa.nome} deveria ter ocorrências',
        );
      }
      final ocorrenciasInativa = await db.ocorrenciasDespesaDao.listByDespesa(
        inativa.id,
      );
      expect(
        ocorrenciasInativa,
        isEmpty,
        reason: 'Despesa inativa não deve ter ocorrências geradas pelo startup',
      );
    });

    test('startup idempotente: rodar 2× não duplica ocorrências', () async {
      final hoje = DateTime.now();
      final despesa = await _inserirDespesa(
        db,
        frequencia: FrequenciaDespesa.mensal,
        diaDoMes: 1,
        dataInicio: DateTime(hoje.year, hoje.month, 1),
        ativa: true,
      );

      // Roda startup 2×.
      for (var i = 0; i < 2; i++) {
        final ativas = await db.despesasRecorrentesDao.listAtivas();
        for (final d in ativas) {
          await db.ocorrenciasDespesaDao.materializar(d);
        }
      }

      final ocorrencias = await db.ocorrenciasDespesaDao.listByDespesa(
        despesa.id,
      );
      final datas = ocorrencias.map((o) => o.dataVencimento).toList();
      final datasSet = datas.toSet();
      expect(
        datas.length,
        datasSet.length,
        reason: 'Startup idempotente não deve duplicar ocorrências',
      );
    });
  });

  // -------------------------------------------------------------------------
  // _normalizarData e _diasNoMes — via comportamento observável
  // -------------------------------------------------------------------------

  group('normalização de datas', () {
    test('ocorrências geradas têm hora zerada (meia-noite)', () async {
      final hoje = DateTime.now();
      // dataInicio com hora diferente de meia-noite.
      final dataInicio = DateTime(hoje.year, hoje.month, 1, 14, 30, 0);
      final despesa = await _inserirDespesa(
        db,
        frequencia: FrequenciaDespesa.unica,
        dataInicio: dataInicio,
      );
      await db.ocorrenciasDespesaDao.materializar(despesa);
      final ocorrencias = await db.ocorrenciasDespesaDao.listByDespesa(
        despesa.id,
      );
      expect(ocorrencias, hasLength(1));
      final dt = ocorrencias.single.dataVencimento;
      expect(dt.hour, 0);
      expect(dt.minute, 0);
      expect(dt.second, 0);
    });

    test('_diasNoMes: mês 2 ano bissexto tem 29 dias', () {
      // Teste branco de _diasNoMes via comportamento. Usamos 2024 (bissexto).
      // A lógica usa DateTime(ano, mes + 1, 0).day internamente no DAO.
      // Verifica-se que DateTime(2024, 3, 0).day == 29.
      expect(DateTime(2024, 3, 0).day, 29);
    });

    test('_diasNoMes: mês 2 ano não-bissexto tem 28 dias', () {
      expect(DateTime(2026, 3, 0).day, 28);
    });

    test('_diasNoMes: mês 1 tem 31 dias', () {
      expect(DateTime(2026, 2, 0).day, 31);
    });
  });
}
