import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/database/daos/veiculos_dao.dart';
import '../data/providers.dart';
import 'lembretes_service.dart';

/// Serviço que orquestra operações de [VeiculosDao] + cancelamento de
/// notificações ao arquivar.
class VeiculosService {
  VeiculosService({required this._dao, required this._lembretesService});

  final VeiculosDao _dao;
  final LembretesService _lembretesService;

  // ── Leitura (delega ao DAO) ───────────────────────────────────────────────

  Future<Veiculo?> byPlaca(String placa) => _dao.byPlaca(placa);

  Future<List<Veiculo>> listAtivos() => _dao.listAtivos();

  Future<List<Veiculo>> listArquivados() => _dao.listArquivados();

  Stream<List<Veiculo>> watchAtivos() => _dao.watchAtivos();

  Stream<List<Veiculo>> watchArquivados() => _dao.watchArquivados();

  // ── Escrita + notificações ────────────────────────────────────────────────

  Future<int> insertVeiculo(VeiculosCompanion v) => _dao.insertVeiculo(v);

  Future<int> updateByPlaca(String placa, VeiculosCompanion v) =>
      _dao.updateByPlaca(placa, v);

  /// Arquiva o veículo e cancela todas as notificações de lembretes pendentes.
  Future<int> arquivar(String placa) async {
    await _lembretesService.cancelarNotificacoesPorVeiculo(placa);
    return _dao.arquivar(placa);
  }

  Future<int> restaurar(String placa) => _dao.restaurar(placa);

  Future<int> deleteByPlaca(String placa) => _dao.deleteByPlaca(placa);
}

// ── Provider ─────────────────────────────────────────────────────────────────

final veiculosServiceProvider = Provider<VeiculosService>((ref) {
  return VeiculosService(
    dao: ref.watch(veiculosDaoProvider),
    lembretesService: ref.watch(lembretesServiceProvider),
  );
});
