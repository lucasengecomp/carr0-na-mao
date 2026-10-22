import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/database/daos/manutencoes_dao.dart';
import '../data/providers.dart';

/// Serviço que orquestra operações sobre [ManutencoesDao].
///
/// Centraliza a lógica de escrita de manutenções para que a UI não dependa
/// diretamente do DAO — espelhando o padrão de [AbastecimentosService].
class ManutencoesService {
  ManutencoesService({required this._dao});

  final ManutencoesDao _dao;

  // ── Leitura (delega ao DAO) ───────────────────────────────────────────────

  Future<Manutencao?> byId(int id) => _dao.byId(id);

  Future<List<Manutencao>> listByVeiculo(String placa) =>
      _dao.listByVeiculo(placa);

  Stream<List<Manutencao>> watchByVeiculo(String placa) =>
      _dao.watchByVeiculo(placa);

  // ── Escrita ───────────────────────────────────────────────────────────────

  Future<int> insertManutencao(ManutencoesCompanion companion) =>
      _dao.insertManutencao(companion);

  Future<bool> updateManutencao(Manutencao m) => _dao.updateManutencao(m);

  /// Exclui permanentemente (hard delete) a manutenção com o [id] dado.
  /// Não há efeito em cascade: outros registros do veículo permanecem intactos.
  Future<int> deleteManutencao(int id) => _dao.deleteById(id);
}

// ── Provider ─────────────────────────────────────────────────────────────────

final manutencoesServiceProvider = Provider<ManutencoesService>((ref) {
  return ManutencoesService(dao: ref.watch(manutencoesDaoProvider));
});
