import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/enums.dart';
import '../../../data/providers.dart';
import '../veiculos/veiculos_providers.dart';

// ---------------------------------------------------------------------------
// Modelos de dados para os gráficos
// ---------------------------------------------------------------------------

/// Um mês de gastos agregados por categoria.
class GastoMensal {
  const GastoMensal({
    required this.mes,
    required this.abastec,
    required this.manut,
    required this.despesas,
  });

  final DateTime mes; // 1º dia do mês, hora zerada
  final double abastec;
  final double manut;
  final double despesas;

  double get total => abastec + manut + despesas;
}

/// Um mês com consumo médio calculado (km/l).
/// [kmPorLitro] é nulo quando não há par de tanques cheios suficiente.
class ConsumoMensal {
  const ConsumoMensal({required this.mes, required this.kmPorLitro});

  final DateTime mes;
  final double? kmPorLitro;
}

/// Gasto total por categoria (agrupado nos últimos 12 meses).
class CategoriaGasto {
  const CategoriaGasto({required this.rotulo, required this.total});

  final String rotulo;
  final double total;
}

// ---------------------------------------------------------------------------
// Helper interno: resolve veículo ativo (cópia do dashboard_providers.dart)
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

/// Retorna o 1º dia do mês, sem hora.
DateTime _primeiroDiaMes(int ano, int mes) => DateTime(ano, mes);

/// Os últimos 12 meses a partir do mês corrente (inclusive), em ordem
/// cronológica crescente.
List<DateTime> _ultimos12Meses() {
  final now = DateTime.now();
  return List.generate(12, (i) {
    final offset = 11 - i;
    return _primeiroDiaMes(now.year, now.month - offset);
  });
}

/// Início da janela de 12 meses: 1º dia do 13º mês anterior ao corrente.
/// Todos os três providers (gastos, consumo, pizza) usam este mesmo limite
/// para garantir consistência.
DateTime _janela12mInicio() => _ultimos12Meses().first;

// ---------------------------------------------------------------------------
// Provider 1 — Gastos mensais (últimos 12 meses)
// ---------------------------------------------------------------------------
//
// Agrega por mês:
//   abastec  = soma de valorTotal dos abastecimentos no mês.
//   manut    = soma de valor (não-nulo) das manutenções no mês.
//   despesas = soma de valorPago das ocorrências com status=paga e
//              dataPagamento no mês.

final gastosMensaisProvider = StreamProvider.autoDispose
    .family<List<GastoMensal>, String>((ref, placa) {
      final veiculoAsync = _resolveVeiculoAtivo(ref);
      if (veiculoAsync.isLoading) return const Stream.empty();

      final controller = StreamController<List<GastoMensal>>();

      final meses = _ultimos12Meses();
      final abastDao = ref.watch(abastecimentosDaoProvider);
      final manutDao = ref.watch(manutencoesDaoProvider);
      final despesasDao = ref.watch(despesasRecorrentesDaoProvider);
      final ocorrenciasDao = ref.watch(ocorrenciasDespesaDaoProvider);

      List<Abastecimento>? abastecimentos;
      List<Manutencao>? manutencoes;

      Future<void> recalcular() async {
        if (controller.isClosed) return;
        final ab = abastecimentos;
        final ma = manutencoes;
        if (ab == null || ma == null) return;

        // Acumula ocorrências pagas por mês (async).
        final ocorrPorMes = <String, double>{};
        try {
          final despesasLista = await despesasDao.listByVeiculo(placa);
          for (final d in despesasLista) {
            final ocorrencias = await ocorrenciasDao.listByDespesa(d.id);
            for (final o in ocorrencias) {
              if (o.status == StatusOcorrencia.paga &&
                  o.dataPagamento != null) {
                final key =
                    '${o.dataPagamento!.year}-${o.dataPagamento!.month}';
                ocorrPorMes[key] = (ocorrPorMes[key] ?? 0) + (o.valorPago ?? 0);
              }
            }
          }
        } catch (_) {}

        final resultado = <GastoMensal>[];
        for (final mes in meses) {
          double totalAbast = 0;
          for (final a in ab) {
            if (a.data.year == mes.year && a.data.month == mes.month) {
              totalAbast += a.valorTotal;
            }
          }

          double totalManut = 0;
          for (final m in ma) {
            if (m.data.year == mes.year &&
                m.data.month == mes.month &&
                m.valor != null) {
              totalManut += m.valor!;
            }
          }

          final key = '${mes.year}-${mes.month}';
          final totalOcorr = ocorrPorMes[key] ?? 0;

          resultado.add(
            GastoMensal(
              mes: mes,
              abastec: totalAbast,
              manut: totalManut,
              despesas: totalOcorr,
            ),
          );
        }

        if (!controller.isClosed) controller.add(resultado);
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
// Provider 2 — Consumo mensal km/l (últimos 12 meses)
// ---------------------------------------------------------------------------
//
// Para cada mês, aplica o mesmo algoritmo do consumoMedioProvider (issue #28),
// mas restrito aos abastecimentos cujas datas estão dentro do mês.
//
// Fórmula: entre tanques cheios consecutivos (ordenados por km crescente)
// cujos abastecimentos pertençam ao mesmo mês:
//   km_segmento   = km[i+1] - km[i]
//   litros_segmento = litros[i+1]
// kmPorLitro = Σ km_segmento / Σ litros_segmento
//
// Requer ao menos 2 registros de tanque cheio no mês → null se insuficiente.

final consumoMensalProvider = StreamProvider.autoDispose
    .family<List<ConsumoMensal>, String>((ref, placa) {
      final veiculoAsync = _resolveVeiculoAtivo(ref);
      if (veiculoAsync.isLoading) return const Stream.empty();

      final controller = StreamController<List<ConsumoMensal>>();
      final abastDao = ref.watch(abastecimentosDaoProvider);
      final meses = _ultimos12Meses();

      StreamSubscription<List<Abastecimento>>? abastSub;

      abastSub = abastDao.watchByVeiculo(placa).listen((todos) {
        if (controller.isClosed) return;

        final resultado = <ConsumoMensal>[];
        for (final mes in meses) {
          // Filtra apenas tanques cheios do mês.
          final cheiOs =
              todos
                  .where(
                    (a) =>
                        a.tanqueCheio &&
                        a.data.year == mes.year &&
                        a.data.month == mes.month,
                  )
                  .toList()
                ..sort((a, b) => a.km.compareTo(b.km));

          if (cheiOs.length < 2) {
            resultado.add(ConsumoMensal(mes: mes, kmPorLitro: null));
            continue;
          }

          double totalKm = 0;
          double totalLitros = 0;
          for (var i = 1; i < cheiOs.length; i++) {
            final km = (cheiOs[i].km - cheiOs[i - 1].km).toDouble();
            if (km <= 0) continue;
            totalKm += km;
            totalLitros += cheiOs[i].litros;
          }

          if (totalLitros <= 0) {
            resultado.add(ConsumoMensal(mes: mes, kmPorLitro: null));
          } else {
            resultado.add(
              ConsumoMensal(mes: mes, kmPorLitro: totalKm / totalLitros),
            );
          }
        }

        if (!controller.isClosed) controller.add(resultado);
      });

      ref.onDispose(() {
        unawaited(abastSub?.cancel() ?? Future.value());
        if (!controller.isClosed) unawaited(controller.close());
      });

      return controller.stream;
    });

// ---------------------------------------------------------------------------
// Provider 3 — Distribuição por categoria (últimos 12 meses)
// ---------------------------------------------------------------------------
//
// Agrega em 3 categorias fixas:
//   "Combustível" — todos os abastecimentos.
//   "Manutenção"  — manutenções com valor não-nulo.
//   + uma entrada por CategoriaDespesa das ocorrências pagas.

final distribuicaoCategoriaProvider = StreamProvider.autoDispose
    .family<List<CategoriaGasto>, String>((ref, placa) {
      final veiculoAsync = _resolveVeiculoAtivo(ref);
      if (veiculoAsync.isLoading) return const Stream.empty();

      final controller = StreamController<List<CategoriaGasto>>();

      // Usa o mesmo início de janela que gastosMensaisProvider e
      // consumoMensalProvider: 1º dia do 13º mês anterior ao corrente.
      final limite12m = _janela12mInicio();

      final abastDao = ref.watch(abastecimentosDaoProvider);
      final manutDao = ref.watch(manutencoesDaoProvider);
      final despesasDao = ref.watch(despesasRecorrentesDaoProvider);
      final ocorrenciasDao = ref.watch(ocorrenciasDespesaDaoProvider);

      List<Abastecimento>? abastecimentos;
      List<Manutencao>? manutencoes;

      Future<void> recalcular() async {
        if (controller.isClosed) return;
        final ab = abastecimentos;
        final ma = manutencoes;
        if (ab == null || ma == null) return;

        final totais = <String, double>{};

        // Combustível.
        double totalAbast = 0;
        for (final a in ab) {
          if (!a.data.isBefore(limite12m)) totalAbast += a.valorTotal;
        }
        if (totalAbast > 0) totais['Combustível'] = totalAbast;

        // Manutenção.
        double totalManut = 0;
        for (final m in ma) {
          if (!m.data.isBefore(limite12m) && m.valor != null) {
            totalManut += m.valor!;
          }
        }
        if (totalManut > 0) totais['Manutenção'] = totalManut;

        // Despesas por categoria.
        try {
          final despesasLista = await despesasDao.listByVeiculo(placa);
          for (final d in despesasLista) {
            final ocorrencias = await ocorrenciasDao.listByDespesa(d.id);
            for (final o in ocorrencias) {
              if (o.status == StatusOcorrencia.paga &&
                  o.dataPagamento != null &&
                  !o.dataPagamento!.isBefore(limite12m)) {
                final rotulo = _rotuloCategoria(d.categoria);
                totais[rotulo] = (totais[rotulo] ?? 0) + (o.valorPago ?? 0);
              }
            }
          }
        } catch (_) {}

        final resultado =
            totais.entries
                .where((e) => e.value > 0)
                .map((e) => CategoriaGasto(rotulo: e.key, total: e.value))
                .toList()
              ..sort((a, b) => b.total.compareTo(a.total));

        if (!controller.isClosed) controller.add(resultado);
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

String _rotuloCategoria(CategoriaDespesa c) {
  switch (c) {
    case CategoriaDespesa.lavagem:
      return 'Lavagem';
    case CategoriaDespesa.estacionamento:
      return 'Estacionamento';
    case CategoriaDespesa.pedagio:
      return 'Pedágio';
    case CategoriaDespesa.financiamento:
      return 'Financiamento';
    case CategoriaDespesa.outra:
      return 'Outra';
  }
}
