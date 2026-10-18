import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/providers.dart';

/// Stream de despesas recorrentes de um veículo, ordenadas por nome.
final despesasRecorrentesProvider =
    StreamProvider.family<List<DespesaRecorrente>, String>((ref, placa) {
      return ref.watch(despesasRecorrentesDaoProvider).watchByVeiculo(placa);
    });

/// Modelo de apresentação: ocorrência + despesa recorrente associada.
class OcorrenciaComDespesa {
  const OcorrenciaComDespesa({required this.ocorrencia, required this.despesa});

  final OcorrenciaDespesa ocorrencia;
  final DespesaRecorrente despesa;
}

/// Stream de ocorrências próximas de um veículo (pendentes + pagas/puladas
/// dos últimos 90 dias), enriquecidas com o nome da despesa recorrente.
final ocorrenciasProximasProvider =
    StreamProvider.family<List<OcorrenciaComDespesa>, String>((
      ref,
      placa,
    ) async* {
      final ocorrenciasDao = ref.watch(ocorrenciasDespesaDaoProvider);
      final despesasDao = ref.watch(despesasRecorrentesDaoProvider);

      await for (final ocorrencias in ocorrenciasDao.watchProximasByVeiculo(
        placa,
      )) {
        // Carrega todas as despesas do veículo uma vez (lista pequena).
        final despesas = await despesasDao.listByVeiculo(placa);
        final despesasById = {for (final d in despesas) d.id: d};

        final resultado = <OcorrenciaComDespesa>[];
        for (final o in ocorrencias) {
          final d = despesasById[o.despesaId];
          if (d != null) {
            resultado.add(OcorrenciaComDespesa(ocorrencia: o, despesa: d));
          }
        }
        yield resultado;
      }
    });
