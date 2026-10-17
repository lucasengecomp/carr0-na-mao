import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/enums.dart';
import '../../../data/providers.dart';
import '../veiculos/veiculos_providers.dart';

// ---------------------------------------------------------------------------
// Helper: resolve o veículo ativo aguardando os sub-streams estarem prontos.
//
// Retorna:
//   AsyncLoading  — qualquer dep ainda está carregando.
//   AsyncData(null) — deps carregados mas sem veículo ativo.
//   AsyncData(v)  — veículo ativo encontrado.
// ---------------------------------------------------------------------------

AsyncValue<Veiculo?> _resolveVeiculoAtivo(Ref ref) {
  final ativosAsync = ref.watch(veiculosAtivosProvider);
  final selecionadoAsync = ref.watch(veiculoSelecionadoProvider);
  if (ativosAsync.isLoading || selecionadoAsync.isLoading) {
    return const AsyncValue.loading();
  }
  final ativos = ativosAsync.value ?? const [];
  if (ativos.isEmpty) return const AsyncValue.data(null);
  final selecionada = selecionadoAsync.value;
  if (selecionada != null) {
    for (final v in ativos) {
      if (v.placa == selecionada) return AsyncValue.data(v);
    }
  }
  return AsyncValue.data(ativos.first);
}

// ---------------------------------------------------------------------------
// Card 1 — Custo total no mês corrente
// ---------------------------------------------------------------------------

/// Resultado do card de custo mensal.
class CustoMensalResult {
  const CustoMensalResult({required this.total});

  final double total;
}

/// Calcula custo total do mês corrente:
///   - Abastecimentos com data no mês/ano corrente.
///   - Manutenções com data no mês/ano corrente e valor não-nulo.
///   - Ocorrências pagas (status = paga) no mês/ano corrente.
///
/// Retorna null quando não há veículo ativo.
/// Permanece em loading enquanto deps não estiverem prontos.
final custoMensalProvider = StreamProvider.autoDispose<CustoMensalResult?>((
  ref,
) {
  final veiculoAsync = _resolveVeiculoAtivo(ref);

  // Deps ainda carregando — stream vazio mantém o provider em loading.
  if (veiculoAsync.isLoading) return const Stream.empty();

  final controller = StreamController<CustoMensalResult?>();
  final veiculo = veiculoAsync.value;

  if (veiculo == null) {
    controller.add(null);
    unawaited(controller.close());
    return controller.stream;
  }

  final placa = veiculo.placa;
  final now = DateTime.now();
  final anoMes = (now.year, now.month);
  final ocorrenciasDao = ref.watch(ocorrenciasDespesaDaoProvider);
  final despesasDao = ref.watch(despesasRecorrentesDaoProvider);
  final abastDao = ref.watch(abastecimentosDaoProvider);
  final manutDao = ref.watch(manutencoesDaoProvider);

  List<Abastecimento>? abastecimentos;
  List<Manutencao>? manutencoes;

  Future<void> recalcular() async {
    if (controller.isClosed) return;
    final ab = abastecimentos;
    final ma = manutencoes;
    if (ab == null || ma == null) return;

    double totalAbast = 0;
    for (final a in ab) {
      if (a.data.year == anoMes.$1 && a.data.month == anoMes.$2) {
        totalAbast += a.valorTotal;
      }
    }

    double totalManut = 0;
    for (final m in ma) {
      if (m.data.year == anoMes.$1 &&
          m.data.month == anoMes.$2 &&
          m.valor != null) {
        totalManut += m.valor!;
      }
    }

    double totalOcorr = 0;
    try {
      final despesas = await despesasDao.listByVeiculo(placa);
      for (final d in despesas) {
        final ocorrencias = await ocorrenciasDao.listByDespesa(d.id);
        for (final o in ocorrencias) {
          if (o.status == StatusOcorrencia.paga &&
              o.dataPagamento != null &&
              o.dataPagamento!.year == anoMes.$1 &&
              o.dataPagamento!.month == anoMes.$2) {
            totalOcorr += o.valorPago ?? 0;
          }
        }
      }
    } catch (_) {}

    if (!controller.isClosed) {
      controller.add(
        CustoMensalResult(total: totalAbast + totalManut + totalOcorr),
      );
    }
  }

  StreamSubscription<List<Abastecimento>>? abastSub;
  StreamSubscription<List<Manutencao>>? manutSub;

  abastSub = abastDao.watchByVeiculo(placa).listen((list) {
    abastecimentos = list;
    unawaited(recalcular());
  });

  manutSub = manutDao.watchByVeiculo(placa).listen((list) {
    manutencoes = list;
    unawaited(recalcular());
  });

  ref.onDispose(() {
    unawaited(abastSub?.cancel() ?? Future.value());
    unawaited(manutSub?.cancel() ?? Future.value());
    if (!controller.isClosed) unawaited(controller.close());
  });

  return controller.stream;
});

// ---------------------------------------------------------------------------
// Card 2 — Custo por km (últimos 12 meses)
// ---------------------------------------------------------------------------
//
// Fórmula: (soma de todos os gastos nos últimos 12m) / (km rodado nos últimos 12m)
// km rodado = km máx registrado nos últimos 12m  − km mín registrado nos últimos 12m
// (mín e máx considerando abastecimentos + manutenções)
// Requer ao menos 2 km distintos → caso contrário: null.

class CustoPorKmResult {
  const CustoPorKmResult({required this.custoPorKm});

  final double custoPorKm;
}

final custoPorKmProvider = StreamProvider.autoDispose<CustoPorKmResult?>((ref) {
  final veiculoAsync = _resolveVeiculoAtivo(ref);

  if (veiculoAsync.isLoading) return const Stream.empty();

  final controller = StreamController<CustoPorKmResult?>();
  final veiculo = veiculoAsync.value;

  if (veiculo == null) {
    controller.add(null);
    unawaited(controller.close());
    return controller.stream;
  }

  final placa = veiculo.placa;
  final limite12m = DateTime(
    DateTime.now().year - 1,
    DateTime.now().month,
    DateTime.now().day,
  );
  final despesasDao = ref.watch(despesasRecorrentesDaoProvider);
  final ocorrenciasDao = ref.watch(ocorrenciasDespesaDaoProvider);
  final abastDao = ref.watch(abastecimentosDaoProvider);
  final manutDao = ref.watch(manutencoesDaoProvider);

  List<Abastecimento>? abastecimentos;
  List<Manutencao>? manutencoes;

  Future<void> recalcular() async {
    if (controller.isClosed) return;
    final ab = abastecimentos;
    final ma = manutencoes;
    if (ab == null || ma == null) return;

    final abast12m = ab.where((a) => a.data.isAfter(limite12m)).toList();
    final manut12m = ma.where((m) => m.data.isAfter(limite12m)).toList();

    if (abast12m.isEmpty) {
      if (!controller.isClosed) controller.add(null);
      return;
    }

    final kms = [...abast12m.map((a) => a.km), ...manut12m.map((m) => m.km)];
    if (kms.length < 2) {
      if (!controller.isClosed) controller.add(null);
      return;
    }
    final kmMin = kms.reduce((a, b) => a < b ? a : b);
    final kmMax = kms.reduce((a, b) => a > b ? a : b);
    final kmRodado = kmMax - kmMin;
    if (kmRodado <= 0) {
      if (!controller.isClosed) controller.add(null);
      return;
    }

    double total = abast12m.fold(0, (s, a) => s + a.valorTotal);
    for (final m in manut12m) {
      if (m.valor != null) total += m.valor!;
    }

    try {
      final despesas = await despesasDao.listByVeiculo(placa);
      for (final d in despesas) {
        final ocorrencias = await ocorrenciasDao.listByDespesa(d.id);
        for (final o in ocorrencias) {
          if (o.status == StatusOcorrencia.paga &&
              o.dataPagamento != null &&
              o.dataPagamento!.isAfter(limite12m)) {
            total += o.valorPago ?? 0;
          }
        }
      }
    } catch (_) {}

    if (total <= 0) {
      if (!controller.isClosed) controller.add(null);
      return;
    }

    if (!controller.isClosed) {
      controller.add(CustoPorKmResult(custoPorKm: total / kmRodado));
    }
  }

  StreamSubscription<List<Abastecimento>>? abastSub;
  StreamSubscription<List<Manutencao>>? manutSub;

  abastSub = abastDao.watchByVeiculo(placa).listen((list) {
    abastecimentos = list;
    unawaited(recalcular());
  });

  manutSub = manutDao.watchByVeiculo(placa).listen((list) {
    manutencoes = list;
    unawaited(recalcular());
  });

  ref.onDispose(() {
    unawaited(abastSub?.cancel() ?? Future.value());
    unawaited(manutSub?.cancel() ?? Future.value());
    if (!controller.isClosed) unawaited(controller.close());
  });

  return controller.stream;
});

// ---------------------------------------------------------------------------
// Card 3 — Consumo médio km/l (últimos 12 meses)
// ---------------------------------------------------------------------------
//
// Apenas abastecimentos marcados como tanque cheio.
// Algoritmo entre tanques cheios consecutivos (ordenados por km crescente):
//   Para cada par consecutivo (A_i, A_{i+1}) com tanque cheio:
//     litros_segmento = litros do A_{i+1}
//     km_segmento = km[A_{i+1}] − km[A_i]
// Consumo médio = (soma dos km_segmento) / (soma dos litros_segmento)
// Requer ao menos 2 tanques cheios distintos → null.

class ConsumoMedioResult {
  const ConsumoMedioResult({required this.kmPorLitro});

  final double kmPorLitro;
}

final consumoMedioProvider = StreamProvider.autoDispose<ConsumoMedioResult?>((
  ref,
) {
  final veiculoAsync = _resolveVeiculoAtivo(ref);

  if (veiculoAsync.isLoading) return const Stream.empty();

  final controller = StreamController<ConsumoMedioResult?>();
  final veiculo = veiculoAsync.value;

  if (veiculo == null) {
    controller.add(null);
    unawaited(controller.close());
    return controller.stream;
  }

  final placa = veiculo.placa;
  final limite12m = DateTime(
    DateTime.now().year - 1,
    DateTime.now().month,
    DateTime.now().day,
  );
  final abastDao = ref.watch(abastecimentosDaoProvider);

  void recalcular(List<Abastecimento> abastecimentos) {
    if (controller.isClosed) return;

    final cheiOs =
        abastecimentos
            .where((a) => a.data.isAfter(limite12m) && a.tanqueCheio)
            .toList()
          ..sort((a, b) => a.km.compareTo(b.km));

    if (cheiOs.length < 2) {
      controller.add(null);
      return;
    }

    double totalKm = 0;
    double totalLitros = 0;
    for (var i = 1; i < cheiOs.length; i++) {
      final anterior = cheiOs[i - 1];
      final atual = cheiOs[i];
      final km = (atual.km - anterior.km).toDouble();
      if (km <= 0) continue;
      totalKm += km;
      totalLitros += atual.litros;
    }

    if (totalLitros <= 0) {
      controller.add(null);
      return;
    }

    controller.add(ConsumoMedioResult(kmPorLitro: totalKm / totalLitros));
  }

  StreamSubscription<List<Abastecimento>>? abastSub;
  abastSub = abastDao.watchByVeiculo(placa).listen(recalcular);

  ref.onDispose(() {
    unawaited(abastSub?.cancel() ?? Future.value());
    if (!controller.isClosed) unawaited(controller.close());
  });

  return controller.stream;
});

// ---------------------------------------------------------------------------
// Card 4 — Próximas 3 manutenções (lembretes pendentes)
// ---------------------------------------------------------------------------

/// Retorna os 3 primeiros lembretes pendentes do veículo ativo,
/// ordenados por dataAlvo/kmAlvo mais próximo.
/// Null quando não há veículo ativo.
final proximasManutencoeProvider = StreamProvider.autoDispose<List<Lembrete>?>((
  ref,
) {
  final veiculoAsync = _resolveVeiculoAtivo(ref);

  if (veiculoAsync.isLoading) return const Stream.empty();

  final controller = StreamController<List<Lembrete>?>();
  final veiculo = veiculoAsync.value;

  if (veiculo == null) {
    controller.add(null);
    unawaited(controller.close());
    return controller.stream;
  }

  final placa = veiculo.placa;
  final lembretesDao = ref.watch(lembretesDaoProvider);

  StreamSubscription<List<Lembrete>>? lembretesSub;
  lembretesSub = lembretesDao.watchPendentesByVeiculo(placa).listen((lista) {
    if (!controller.isClosed) {
      controller.add(lista.take(3).toList());
    }
  });

  ref.onDispose(() {
    unawaited(lembretesSub?.cancel() ?? Future.value());
    if (!controller.isClosed) unawaited(controller.close());
  });

  return controller.stream;
});
