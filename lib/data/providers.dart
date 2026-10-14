import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database/app_database.dart';
import 'database/daos/abastecimentos_dao.dart';
import 'database/daos/despesas_dao.dart';
import 'database/daos/lembretes_dao.dart';
import 'database/daos/manutencoes_dao.dart';
import 'database/daos/marcas_modelos_dao.dart';
import 'database/daos/veiculos_dao.dart';

/// Instância singleton do banco. Fechada quando o container Riverpod é
/// descartado. Em testes, sobrescrever com `appDatabaseProvider.overrideWith`.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => unawaited(db.close()));
  return db;
});

final veiculosDaoProvider = Provider<VeiculosDao>(
  (ref) => ref.watch(appDatabaseProvider).veiculosDao,
);

final abastecimentosDaoProvider = Provider<AbastecimentosDao>(
  (ref) => ref.watch(appDatabaseProvider).abastecimentosDao,
);

final manutencoesDaoProvider = Provider<ManutencoesDao>(
  (ref) => ref.watch(appDatabaseProvider).manutencoesDao,
);

final tiposManutencaoPadraoDaoProvider = Provider<TiposManutencaoPadraoDao>(
  (ref) => ref.watch(appDatabaseProvider).tiposManutencaoPadraoDao,
);

final despesasRecorrentesDaoProvider = Provider<DespesasRecorrentesDao>(
  (ref) => ref.watch(appDatabaseProvider).despesasRecorrentesDao,
);

final ocorrenciasDespesaDaoProvider = Provider<OcorrenciasDespesaDao>(
  (ref) => ref.watch(appDatabaseProvider).ocorrenciasDespesaDao,
);

final lembretesDaoProvider = Provider<LembretesDao>(
  (ref) => ref.watch(appDatabaseProvider).lembretesDao,
);

final marcasModelosDaoProvider = Provider<MarcasModelosDao>(
  (ref) => ref.watch(appDatabaseProvider).marcasModelosDao,
);

/// Lista de marcas disponíveis para o form de veículo. Alimentado pelo seed
/// do asset `assets/data/marcas_modelos.json`.
final marcasProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(marcasModelosDaoProvider).listMarcas(),
);

/// Lista de modelos de uma marca específica. Família por marca.
final modelosPorMarcaProvider = FutureProvider.family<List<String>, String>(
  (ref, marca) => ref.watch(marcasModelosDaoProvider).listModelosByMarca(marca),
);
