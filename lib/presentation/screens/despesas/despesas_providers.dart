import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/providers.dart';

/// Stream de despesas recorrentes de um veículo, ordenadas por nome.
final despesasRecorrentesProvider =
    StreamProvider.family<List<DespesaRecorrente>, String>((ref, placa) {
      return ref.watch(despesasRecorrentesDaoProvider).watchByVeiculo(placa);
    });
