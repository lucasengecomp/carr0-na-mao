import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/providers.dart';

/// Lista reativa de abastecimentos de um veículo. Vazia (não-erro) quando a
/// placa é `null` — permite que a UI mostre estado "sem veículo ativo" sem
/// precisar de override no provider.
final abastecimentosDoVeiculoProvider =
    StreamProvider.family<List<Abastecimento>, String?>((ref, placa) {
      if (placa == null) return Stream.value(const <Abastecimento>[]);
      return ref.watch(abastecimentosDaoProvider).watchByVeiculo(placa);
    });
