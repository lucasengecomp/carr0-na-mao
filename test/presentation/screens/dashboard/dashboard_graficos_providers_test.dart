// ignore_for_file: avoid_print

import 'dart:async';

import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/data/providers.dart';
import 'package:carro_na_mao/presentation/screens/dashboard/dashboard_graficos_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _placa = 'TST1A11';

VeiculosCompanion _novoVeiculo({String placa = _placa}) =>
    VeiculosCompanion.insert(
      placa: placa,
      marca: 'Fiat',
      modelo: 'Uno',
      ano: 2020,
      tipo: TipoVeiculo.carro,
      combustivel: TipoCombustivelVeiculo.flex,
      kmInicial: 1000,
    );

AbastecimentosCompanion _novoAbast({
  String placa = _placa,
  required DateTime data,
  required int km,
  double litros = 40.0,
  double valorTotal = 200.0,
  bool tanqueCheio = false,
}) => AbastecimentosCompanion.insert(
  veiculoPlaca: placa,
  data: data,
  km: km,
  tipoCombustivel: TipoCombustivelAbastecimento.gasolina,
  precoLitro: valorTotal / litros,
  valorTotal: valorTotal,
  litros: litros,
  tanqueCheio: Value(tanqueCheio),
);

ManutencoesCompanion _novaManut({
  String placa = _placa,
  required DateTime data,
  required int km,
  double? valor,
}) => ManutencoesCompanion.insert(
  veiculoPlaca: placa,
  tipo: TipoManutencao.oleoMotor,
  data: data,
  km: km,
  valor: Value(valor),
);

DespesasRecorrentesCompanion _novaDespesa({
  String placa = _placa,
  CategoriaDespesa categoria = CategoriaDespesa.lavagem,
  double valor = 50.0,
}) => DespesasRecorrentesCompanion.insert(
  veiculoPlaca: placa,
  nome: 'Despesa teste',
  categoria: categoria,
  valor: valor,
  frequencia: FrequenciaDespesa.mensal,
  dataInicio: DateTime(2024, 1, 1),
);

OcorrenciasDespesaCompanion _novaOcorrencia({
  required int despesaId,
  required DateTime dataVencimento,
  DateTime? dataPagamento,
  double? valorPago,
  StatusOcorrencia status = StatusOcorrencia.pendente,
}) => OcorrenciasDespesaCompanion.insert(
  despesaId: despesaId,
  dataVencimento: dataVencimento,
  dataPagamento: Value(dataPagamento),
  valorPago: Value(valorPago),
  status: status,
);

ProviderContainer _makeContainer(AppDatabase db) {
  SharedPreferences.setMockInitialValues({'veiculo_selecionado_placa': _placa});
  return ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
}

/// Awaits the first non-loading value from gastosMensaisProvider.
Future<AsyncValue<List<GastoMensal>>> _awaitGastos(ProviderContainer c) async {
  final completer = Completer<AsyncValue<List<GastoMensal>>>();
  final sub = c.listen<AsyncValue<List<GastoMensal>>>(
    gastosMensaisProvider(_placa),
    (_, next) {
      if (!next.isLoading && !completer.isCompleted) completer.complete(next);
    },
    fireImmediately: true,
  );
  try {
    return await completer.future.timeout(const Duration(seconds: 10));
  } finally {
    sub.close();
  }
}

/// Awaits the first non-loading value from consumoMensalProvider.
Future<AsyncValue<List<ConsumoMensal>>> _awaitConsumo(
  ProviderContainer c,
) async {
  final completer = Completer<AsyncValue<List<ConsumoMensal>>>();
  final sub = c.listen<AsyncValue<List<ConsumoMensal>>>(
    consumoMensalProvider(_placa),
    (_, next) {
      if (!next.isLoading && !completer.isCompleted) completer.complete(next);
    },
    fireImmediately: true,
  );
  try {
    return await completer.future.timeout(const Duration(seconds: 10));
  } finally {
    sub.close();
  }
}

/// Awaits the first non-loading value from distribuicaoCategoriaProvider.
Future<AsyncValue<List<CategoriaGasto>>> _awaitDistribuicao(
  ProviderContainer c,
) async {
  final completer = Completer<AsyncValue<List<CategoriaGasto>>>();
  final sub = c.listen<AsyncValue<List<CategoriaGasto>>>(
    distribuicaoCategoriaProvider(_placa),
    (_, next) {
      if (!next.isLoading && !completer.isCompleted) completer.complete(next);
    },
    fireImmediately: true,
  );
  try {
    return await completer.future.timeout(const Duration(seconds: 10));
  } finally {
    sub.close();
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.veiculosDao.insertVeiculo(_novoVeiculo());
    container = _makeContainer(db);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  // =========================================================================
  // gastosMensaisProvider
  // =========================================================================

  group('gastosMensaisProvider', () {
    test(
      'always returns exactly 12 entries even with empty database',
      () async {
        final val = await _awaitGastos(container);
        expect(val.value, isNotNull);
        expect(val.value!.length, 12);
      },
    );

    test('empty months have all-zero values', () async {
      final val = await _awaitGastos(container);
      for (final m in val.value!) {
        expect(m.abastec, 0.0);
        expect(m.manut, 0.0);
        expect(m.despesas, 0.0);
        expect(m.total, 0.0);
      }
    });

    test(
      'months are in ascending chronological order (oldest to newest)',
      () async {
        final val = await _awaitGastos(container);
        final meses = val.value!;
        for (var i = 1; i < meses.length; i++) {
          expect(
            meses[i].mes.isAfter(meses[i - 1].mes),
            isTrue,
            reason: 'month $i should be after month ${i - 1}',
          );
        }
      },
    );

    test('the newest month equals the current month', () async {
      final val = await _awaitGastos(container);
      final now = DateTime.now();
      final newest = val.value!.last.mes;
      expect(newest.year, now.year);
      expect(newest.month, now.month);
    });

    test('abastecimento in current month is counted in abastec', () async {
      final now = DateTime.now();
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(now.year, now.month, 10),
          km: 5000,
          valorTotal: 300.0,
        ),
      );

      final val = await _awaitGastos(container);
      final current = val.value!.last;
      expect(current.abastec, closeTo(300.0, 0.01));
      expect(current.manut, 0.0);
      expect(current.despesas, 0.0);
    });

    test(
      'manutencao with valor in current month is counted in manut',
      () async {
        final now = DateTime.now();
        await db.manutencoesDao.insertManutencao(
          _novaManut(
            data: DateTime(now.year, now.month, 5),
            km: 5000,
            valor: 450.0,
          ),
        );

        final val = await _awaitGastos(container);
        final current = val.value!.last;
        expect(current.manut, closeTo(450.0, 0.01));
        expect(current.abastec, 0.0);
      },
    );

    test('manutencao without valor is NOT counted', () async {
      final now = DateTime.now();
      await db.manutencoesDao.insertManutencao(
        _novaManut(
          data: DateTime(now.year, now.month, 5),
          km: 5000,
          valor: null,
        ),
      );

      final val = await _awaitGastos(container);
      final current = val.value!.last;
      expect(current.manut, 0.0);
      expect(current.total, 0.0);
    });

    test(
      'abastec + manut + despesas are summed correctly in the same month',
      () async {
        final now = DateTime.now();
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(now.year, now.month, 1),
            km: 5000,
            valorTotal: 100.0,
          ),
        );
        await db.manutencoesDao.insertManutencao(
          _novaManut(
            data: DateTime(now.year, now.month, 2),
            km: 5100,
            valor: 80.0,
          ),
        );
        // Add paid occurrence
        final despId = await db.despesasRecorrentesDao.insertDespesa(
          _novaDespesa(valor: 50.0),
        );
        await db.ocorrenciasDespesaDao.insertOcorrencia(
          _novaOcorrencia(
            despesaId: despId,
            dataVencimento: DateTime(now.year, now.month, 5),
            dataPagamento: DateTime(now.year, now.month, 5),
            valorPago: 60.0,
            status: StatusOcorrencia.paga,
          ),
        );

        final val = await _awaitGastos(container);
        final current = val.value!.last;
        expect(current.abastec, closeTo(100.0, 0.01));
        expect(current.manut, closeTo(80.0, 0.01));
        expect(current.despesas, closeTo(60.0, 0.01));
        expect(current.total, closeTo(240.0, 0.01));
      },
    );

    test('data outside 12-month window does NOT appear in any month', () async {
      final now = DateTime.now();
      // Insert abastecimento 13 months ago (outside window)
      final old = DateTime(now.year, now.month - 13);
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: old, km: 1000, valorTotal: 999.0),
      );

      final val = await _awaitGastos(container);
      for (final m in val.value!) {
        expect(
          m.abastec,
          0.0,
          reason: 'old abastecimento should not appear in any month',
        );
      }
    });

    test(
      'occurrence with null dataPagamento does NOT count as despesas',
      () async {
        final now = DateTime.now();
        final despId = await db.despesasRecorrentesDao.insertDespesa(
          _novaDespesa(valor: 50.0),
        );
        // paga status but null dataPagamento
        await db.ocorrenciasDespesaDao.insertOcorrencia(
          _novaOcorrencia(
            despesaId: despId,
            dataVencimento: DateTime(now.year, now.month, 5),
            dataPagamento: null, // null payment date
            valorPago: 50.0,
            status: StatusOcorrencia.paga,
          ),
        );

        final val = await _awaitGastos(container);
        final current = val.value!.last;
        expect(current.despesas, 0.0);
      },
    );

    test(
      'occurrence with status pendente does NOT count as despesas',
      () async {
        final now = DateTime.now();
        final despId = await db.despesasRecorrentesDao.insertDespesa(
          _novaDespesa(valor: 50.0),
        );
        await db.ocorrenciasDespesaDao.insertOcorrencia(
          _novaOcorrencia(
            despesaId: despId,
            dataVencimento: DateTime(now.year, now.month, 5),
            dataPagamento: DateTime(now.year, now.month, 5),
            valorPago: 50.0,
            status: StatusOcorrencia.pendente, // not paga
          ),
        );

        final val = await _awaitGastos(container);
        final current = val.value!.last;
        expect(current.despesas, 0.0);
      },
    );

    test('occurrence with status pulada does NOT count as despesas', () async {
      final now = DateTime.now();
      final despId = await db.despesasRecorrentesDao.insertDespesa(
        _novaDespesa(valor: 50.0),
      );
      await db.ocorrenciasDespesaDao.insertOcorrencia(
        _novaOcorrencia(
          despesaId: despId,
          dataVencimento: DateTime(now.year, now.month, 5),
          dataPagamento: DateTime(now.year, now.month, 5),
          valorPago: 50.0,
          status: StatusOcorrencia.pulada,
        ),
      );

      final val = await _awaitGastos(container);
      final current = val.value!.last;
      expect(current.despesas, 0.0);
    });

    test(
      'despesas are bucketed by dataPagamento, not dataVencimento',
      () async {
        final now = DateTime.now();
        // Vencimento last month but pagamento this month
        final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
        final lastMonthMonth = now.month == 1 ? 12 : now.month - 1;
        final despId = await db.despesasRecorrentesDao.insertDespesa(
          _novaDespesa(valor: 75.0),
        );
        await db.ocorrenciasDespesaDao.insertOcorrencia(
          _novaOcorrencia(
            despesaId: despId,
            dataVencimento: DateTime(lastMonthYear, lastMonthMonth, 5),
            dataPagamento: DateTime(now.year, now.month, 2), // paid this month
            valorPago: 75.0,
            status: StatusOcorrencia.paga,
          ),
        );

        final val = await _awaitGastos(container);
        final current = val.value!.last; // this month
        final previous = val.value![val.value!.length - 2]; // last month
        expect(
          current.despesas,
          closeTo(75.0, 0.01),
          reason: 'paid this month => counted in current month',
        );
        expect(
          previous.despesas,
          0.0,
          reason: 'vencimento date should not determine bucket',
        );
      },
    );

    test('multiple abastecimentos in same month are all summed', () async {
      final now = DateTime.now();
      for (var i = 0; i < 3; i++) {
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(now.year, now.month, i + 1),
            km: 5000 + i * 100,
            valorTotal: 100.0,
          ),
        );
      }

      final val = await _awaitGastos(container);
      final current = val.value!.last;
      expect(current.abastec, closeTo(300.0, 0.01));
    });
  });

  // =========================================================================
  // consumoMensalProvider
  // =========================================================================

  group('consumoMensalProvider', () {
    test('always returns exactly 12 entries', () async {
      final val = await _awaitConsumo(container);
      expect(val.value, isNotNull);
      expect(val.value!.length, 12);
    });

    test('all months have null kmPorLitro when database is empty', () async {
      final val = await _awaitConsumo(container);
      for (final m in val.value!) {
        expect(m.kmPorLitro, isNull);
      }
    });

    test('months are in ascending chronological order', () async {
      final val = await _awaitConsumo(container);
      final meses = val.value!;
      for (var i = 1; i < meses.length; i++) {
        expect(meses[i].mes.isAfter(meses[i - 1].mes), isTrue);
      }
    });

    test('month with only 1 full-tank has null kmPorLitro', () async {
      final now = DateTime.now();
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(now.year, now.month, 10),
          km: 10000,
          litros: 40.0,
          tanqueCheio: true,
        ),
      );

      final val = await _awaitConsumo(container);
      final current = val.value!.last;
      expect(current.kmPorLitro, isNull);
    });

    test(
      'month with 2 full-tanks computes kmPorLitro correctly: 1000km/40L = 25',
      () async {
        final now = DateTime.now();
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(now.year, now.month, 1),
            km: 10000,
            litros: 30.0,
            tanqueCheio: true,
          ),
        );
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(now.year, now.month, 15),
            km: 11000,
            litros: 40.0,
            tanqueCheio: true,
          ),
        );

        final val = await _awaitConsumo(container);
        final current = val.value!.last;
        expect(current.kmPorLitro, isNotNull);
        // km=1000, litros of second tank=40 → 1000/40=25
        expect(current.kmPorLitro, closeTo(25.0, 0.01));
      },
    );

    test(
      '3 full-tanks: weighted average (1000+900)/(50+45) = 1900/95 ≈ 20.0',
      () async {
        final now = DateTime.now();
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(now.year, now.month, 1),
            km: 10000,
            litros: 30.0,
            tanqueCheio: true,
          ),
        );
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(now.year, now.month, 10),
            km: 11000,
            litros: 50.0,
            tanqueCheio: true,
          ),
        );
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(now.year, now.month, 20),
            km: 11900,
            litros: 45.0,
            tanqueCheio: true,
          ),
        );

        final val = await _awaitConsumo(container);
        final current = val.value!.last;
        expect(current.kmPorLitro, isNotNull);
        expect(current.kmPorLitro, closeTo(1900 / 95, 0.01));
      },
    );

    test(
      'non-full-tank (tanqueCheio=false) is ignored in consumption calc',
      () async {
        final now = DateTime.now();
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(now.year, now.month, 1),
            km: 10000,
            litros: 30.0,
            tanqueCheio: true,
          ),
        );
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(now.year, now.month, 8),
            km: 10500,
            litros: 20.0,
            tanqueCheio: false, // partial fill
          ),
        );
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(now.year, now.month, 15),
            km: 11000,
            litros: 40.0,
            tanqueCheio: true,
          ),
        );

        final val = await _awaitConsumo(container);
        final current = val.value!.last;
        expect(current.kmPorLitro, isNotNull);
        // 1000km / 40L = 25 (partial fill at 10500 ignored)
        expect(current.kmPorLitro, closeTo(25.0, 0.01));
      },
    );

    test('full-tanks in different months are NOT mixed together', () async {
      final now = DateTime.now();
      final prevYear = now.month == 1 ? now.year - 1 : now.year;
      final prevMonth = now.month == 1 ? 12 : now.month - 1;

      // One tank last month, one this month → no pair in either month alone
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(prevYear, prevMonth, 28),
          km: 10000,
          litros: 40.0,
          tanqueCheio: true,
        ),
      );
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(now.year, now.month, 5),
          km: 11000,
          litros: 40.0,
          tanqueCheio: true,
        ),
      );

      final val = await _awaitConsumo(container);
      final current = val.value!.last;
      final previous = val.value![val.value!.length - 2];
      // Each month has only 1 full-tank → both null
      expect(current.kmPorLitro, isNull);
      expect(previous.kmPorLitro, isNull);
    });

    test(
      'pair with same km (km delta = 0) results in null kmPorLitro',
      () async {
        final now = DateTime.now();
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(now.year, now.month, 1),
            km: 10000,
            litros: 40.0,
            tanqueCheio: true,
          ),
        );
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(now.year, now.month, 10),
            km: 10000, // same km
            litros: 40.0,
            tanqueCheio: true,
          ),
        );

        final val = await _awaitConsumo(container);
        final current = val.value!.last;
        expect(current.kmPorLitro, isNull);
      },
    );
  });

  // =========================================================================
  // distribuicaoCategoriaProvider
  // =========================================================================

  group('distribuicaoCategoriaProvider', () {
    test('returns empty list when database has no data', () async {
      final val = await _awaitDistribuicao(container);
      expect(val.value, isNotNull);
      expect(val.value!, isEmpty);
    });

    test('abastecimentos within 12m create Combustível category', () async {
      final now = DateTime.now();
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(now.year, now.month, 10),
          km: 5000,
          valorTotal: 300.0,
        ),
      );

      final val = await _awaitDistribuicao(container);
      expect(val.value, isNotNull);
      final combustivel = val.value!.firstWhere(
        (c) => c.rotulo == 'Combustível',
        orElse: () => throw Exception('Combustível category missing'),
      );
      expect(combustivel.total, closeTo(300.0, 0.01));
    });

    test(
      'manutencao with valor within 12m creates Manutenção category',
      () async {
        final now = DateTime.now();
        await db.manutencoesDao.insertManutencao(
          _novaManut(
            data: DateTime(now.year, now.month, 5),
            km: 5000,
            valor: 450.0,
          ),
        );

        final val = await _awaitDistribuicao(container);
        expect(val.value, isNotNull);
        final manut = val.value!.firstWhere(
          (c) => c.rotulo == 'Manutenção',
          orElse: () => throw Exception('Manutenção category missing'),
        );
        expect(manut.total, closeTo(450.0, 0.01));
      },
    );

    test('manutencao without valor does NOT create Manutenção entry', () async {
      final now = DateTime.now();
      await db.manutencoesDao.insertManutencao(
        _novaManut(
          data: DateTime(now.year, now.month, 5),
          km: 5000,
          valor: null,
        ),
      );

      final val = await _awaitDistribuicao(container);
      expect(val.value!.any((c) => c.rotulo == 'Manutenção'), isFalse);
    });

    test(
      'paid occurrence within 12m creates category entry by CategoriaDespesa',
      () async {
        final now = DateTime.now();
        final despId = await db.despesasRecorrentesDao.insertDespesa(
          _novaDespesa(categoria: CategoriaDespesa.estacionamento, valor: 30.0),
        );
        await db.ocorrenciasDespesaDao.insertOcorrencia(
          _novaOcorrencia(
            despesaId: despId,
            dataVencimento: DateTime(now.year, now.month, 5),
            dataPagamento: DateTime(now.year, now.month, 5),
            valorPago: 35.0,
            status: StatusOcorrencia.paga,
          ),
        );

        final val = await _awaitDistribuicao(container);
        final estac = val.value!.firstWhere(
          (c) => c.rotulo == 'Estacionamento',
          orElse: () => throw Exception('Estacionamento category missing'),
        );
        expect(estac.total, closeTo(35.0, 0.01));
      },
    );

    test(
      'unpaid occurrence (pendente) does NOT appear in distribution',
      () async {
        final now = DateTime.now();
        final despId = await db.despesasRecorrentesDao.insertDespesa(
          _novaDespesa(categoria: CategoriaDespesa.pedagio, valor: 20.0),
        );
        await db.ocorrenciasDespesaDao.insertOcorrencia(
          _novaOcorrencia(
            despesaId: despId,
            dataVencimento: DateTime(now.year, now.month, 5),
            dataPagamento: DateTime(now.year, now.month, 5),
            valorPago: 20.0,
            status: StatusOcorrencia.pendente,
          ),
        );

        final val = await _awaitDistribuicao(container);
        expect(val.value!.any((c) => c.rotulo == 'Pedágio'), isFalse);
      },
    );

    test(
      'occurrence with null dataPagamento does NOT appear even if paga',
      () async {
        final now = DateTime.now();
        final despId = await db.despesasRecorrentesDao.insertDespesa(
          _novaDespesa(categoria: CategoriaDespesa.lavagem, valor: 25.0),
        );
        await db.ocorrenciasDespesaDao.insertOcorrencia(
          _novaOcorrencia(
            despesaId: despId,
            dataVencimento: DateTime(now.year, now.month, 5),
            dataPagamento: null, // null payment date
            valorPago: 25.0,
            status: StatusOcorrencia.paga,
          ),
        );

        final val = await _awaitDistribuicao(container);
        expect(val.value!.any((c) => c.rotulo == 'Lavagem'), isFalse);
      },
    );

    test(
      'multiple occurrences of same CategoriaDespesa are aggregated',
      () async {
        final now = DateTime.now();
        final despId = await db.despesasRecorrentesDao.insertDespesa(
          _novaDespesa(categoria: CategoriaDespesa.lavagem, valor: 30.0),
        );
        for (var i = 0; i < 3; i++) {
          await db.ocorrenciasDespesaDao.insertOcorrencia(
            _novaOcorrencia(
              despesaId: despId,
              dataVencimento: DateTime(now.year, now.month, i + 1),
              dataPagamento: DateTime(now.year, now.month, i + 1),
              valorPago: 30.0,
              status: StatusOcorrencia.paga,
            ),
          );
        }

        final val = await _awaitDistribuicao(container);
        final lavagem = val.value!.firstWhere(
          (c) => c.rotulo == 'Lavagem',
          orElse: () => throw Exception('Lavagem missing'),
        );
        expect(lavagem.total, closeTo(90.0, 0.01));
      },
    );

    test('entries are sorted descending by total value', () async {
      final now = DateTime.now();
      // Add smaller amount: Manutenção
      await db.manutencoesDao.insertManutencao(
        _novaManut(
          data: DateTime(now.year, now.month, 1),
          km: 5000,
          valor: 100.0,
        ),
      );
      // Add larger amount: Combustível
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(now.year, now.month, 5),
          km: 5100,
          valorTotal: 500.0,
        ),
      );

      final val = await _awaitDistribuicao(container);
      final values = val.value!.map((c) => c.total).toList();
      for (var i = 1; i < values.length; i++) {
        expect(
          values[i],
          lessThanOrEqualTo(values[i - 1]),
          reason: 'should be sorted descending',
        );
      }
    });

    test(
      'all CategoriaDespesa values map to distinct Portuguese labels',
      () async {
        final now = DateTime.now();
        final categories = [
          (CategoriaDespesa.lavagem, 'Lavagem'),
          (CategoriaDespesa.estacionamento, 'Estacionamento'),
          (CategoriaDespesa.pedagio, 'Pedágio'),
          (CategoriaDespesa.financiamento, 'Financiamento'),
          (CategoriaDespesa.outra, 'Outra'),
        ];

        for (final (cat, _) in categories) {
          final despId = await db.despesasRecorrentesDao.insertDespesa(
            _novaDespesa(categoria: cat, valor: 10.0),
          );
          await db.ocorrenciasDespesaDao.insertOcorrencia(
            _novaOcorrencia(
              despesaId: despId,
              dataVencimento: DateTime(now.year, now.month, 5),
              dataPagamento: DateTime(now.year, now.month, 5),
              valorPago: 10.0,
              status: StatusOcorrencia.paga,
            ),
          );
        }

        final val = await _awaitDistribuicao(container);
        for (final (_, label) in categories) {
          expect(
            val.value!.any((c) => c.rotulo == label),
            isTrue,
            reason: 'category $label should appear',
          );
        }
      },
    );
  });

  // =========================================================================
  // Consistência de janela: pizza e barras usam o mesmo limite (#82)
  // =========================================================================

  group('window consistency — pizza e barras usam a mesma janela 12m', () {
    // Garante que um abastecimento exatamente no 1º dia do mês mais antigo
    // aparece TANTO no gráfico de barras (gastosMensaisProvider) QUANTO no
    // gráfico de pizza (distribuicaoCategoriaProvider).
    // Isso verifica a correção do bug #82: antes o pizza usava
    // isAfter(DateTime(ano-1, mês, dia)) que excluía os primeiros ~30 dias
    // do intervalo coberto pelas barras.
    test(
      'registro no 1º dia do mês mais antigo aparece nas barras e na pizza',
      () async {
        final now = DateTime.now();
        // 1º dia do mês mais antigo da janela de 12 meses.
        final inicio = DateTime(now.year, now.month - 11);
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(data: inicio, km: 5000, valorTotal: 150.0),
        );

        final gastosVal = await _awaitGastos(container);
        final distribuicaoVal = await _awaitDistribuicao(container);

        // Barras: deve haver exatamente um mês com abastec == 150.0 (o mais antigo).
        final totalNasBarras = gastosVal.value!.fold<double>(
          0,
          (acc, m) => acc + m.abastec,
        );
        expect(
          totalNasBarras,
          closeTo(150.0, 0.01),
          reason: 'abastecimento no início da janela deve aparecer nas barras',
        );

        // Pizza: deve existir a categoria Combustível com 150.0.
        final combustivel = distribuicaoVal.value!.firstWhere(
          (c) => c.rotulo == 'Combustível',
          orElse: () => throw Exception(
            'Combustível ausente na pizza — janela inconsistente (bug #82)',
          ),
        );
        expect(
          combustivel.total,
          closeTo(150.0, 0.01),
          reason: 'abastecimento no início da janela deve aparecer na pizza',
        );
      },
    );

    // Um abastecimento um dia ANTES do início da janela não deve aparecer
    // em nenhum dos dois gráficos.
    test(
      'registro um dia antes do início da janela não aparece em nenhum gráfico',
      () async {
        final now = DateTime.now();
        // 1 dia antes do 1º dia do mês mais antigo = último dia do mês
        // anterior ao início da janela.
        final antes = DateTime(now.year, now.month - 12, 28);
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(data: antes, km: 5000, valorTotal: 999.0),
        );

        final gastosVal = await _awaitGastos(container);
        final distribuicaoVal = await _awaitDistribuicao(container);

        // Barras: nenhuma barra deve ter esse valor.
        final totalNasBarras = gastosVal.value!.fold<double>(
          0,
          (acc, m) => acc + m.abastec,
        );
        expect(
          totalNasBarras,
          0.0,
          reason: 'registro fora da janela não deve aparecer nas barras',
        );

        // Pizza: não deve haver nenhuma categoria Combustível.
        expect(
          distribuicaoVal.value!.any((c) => c.rotulo == 'Combustível'),
          isFalse,
          reason: 'registro fora da janela não deve aparecer na pizza',
        );
      },
    );
  });
}
