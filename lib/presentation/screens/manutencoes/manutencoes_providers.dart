import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/enums.dart';
import '../../../data/providers.dart';

/// Lista reativa de manutenções de um veículo. Vazia (não-erro) quando a
/// placa é `null` — permite que a UI mostre estado "sem veículo ativo" sem
/// precisar de override no provider.
final manutencoesDoVeiculoProvider =
    StreamProvider.family<List<Manutencao>, String?>((ref, placa) {
      if (placa == null) return Stream.value(const <Manutencao>[]);
      return ref.watch(manutencoesDaoProvider).watchByVeiculo(placa);
    });

/// Padrão de manutenção para um tipo específico. Retorna `null` quando não
/// há registro para o tipo (ex.: `outros`).
final tipoManutencaoPadraoProvider =
    FutureProvider.family<TipoManutencaoPadrao?, TipoManutencao>(
      (ref, tipo) => ref.watch(tiposManutencaoPadraoDaoProvider).byTipo(tipo),
    );
