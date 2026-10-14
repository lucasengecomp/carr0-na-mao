import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/providers.dart';
import '../../../domain/comparador_service.dart';

final comparadorServiceProvider = Provider<ComparadorService>(
  (ref) => const ComparadorService(),
);

/// Carrega o histórico de abastecimentos de um veículo para alimentar o
/// comparador. Família por placa para suportar troca de veículo na tela.
final historicoAbastecimentosProvider =
    FutureProvider.family<List<Abastecimento>, String>((ref, placa) {
      return ref.watch(abastecimentosDaoProvider).listByVeiculo(placa);
    });
