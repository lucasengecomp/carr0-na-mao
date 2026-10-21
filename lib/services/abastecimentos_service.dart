import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/database/daos/abastecimentos_dao.dart';
import '../data/database/enums.dart';
import '../data/providers.dart';
import 'lembretes_service.dart';
import 'notifications_service.dart';

/// Serviço que orquestra operações de [AbastecimentosDao] + verificação de
/// km alvo de lembretes (RF-15).
///
/// Ao inserir um abastecimento, verifica se algum lembrete pendente do veículo
/// teve o km alvo atingido ou ultrapassado e dispara notificação imediata.
class AbastecimentosService {
  AbastecimentosService({
    required this._dao,
    required this._lembretesService,
    required this._notifications,
  });

  final AbastecimentosDao _dao;
  final LembretesService _lembretesService;
  final NotificationsService _notifications;

  // ── Leitura (delega ao DAO) ───────────────────────────────────────────────

  Future<Abastecimento?> byId(int id) => _dao.byId(id);

  Future<List<Abastecimento>> listByVeiculo(String placa) =>
      _dao.listByVeiculo(placa);

  Future<Abastecimento?> lastByVeiculo(String placa) =>
      _dao.lastByVeiculo(placa);

  Stream<List<Abastecimento>> watchByVeiculo(String placa) =>
      _dao.watchByVeiculo(placa);

  Stream<List<Abastecimento>> watchFiltered({
    required String placa,
    DateTime? desde,
    TipoCombustivelAbastecimento? tipoCombustivel,
  }) => _dao.watchFiltered(
    placa: placa,
    desde: desde,
    tipoCombustivel: tipoCombustivel,
  );

  // ── Escrita + notificações ────────────────────────────────────────────────

  /// Insere abastecimento e verifica lembretes com km alvo atingido (RF-15).
  Future<int> insertAbastecimento(AbastecimentosCompanion companion) async {
    final id = await _dao.insertAbastecimento(companion);

    // Verifica lembretes vencidos por km.
    final placa = companion.veiculoPlaca.value;
    final km = companion.km.value;
    final vencidos = await _lembretesService.findVencidosPorKm(placa, km);
    for (final lembrete in vencidos) {
      await _notifications.notifyKmReached(lembrete);
    }

    return id;
  }

  /// Atualiza abastecimento (sem re-verificação de km — edição não revalida).
  Future<bool> updateAbastecimento(Abastecimento a) =>
      _dao.updateAbastecimento(a);

  Future<int> deleteById(int id) => _dao.deleteById(id);

  /// Exclui permanentemente (hard delete) o abastecimento com o [id] dado.
  /// Não há efeito em cascade: outros registros do veículo permanecem intactos.
  Future<int> deleteAbastecimento(int id) => _dao.deleteById(id);
}

// ── Provider ─────────────────────────────────────────────────────────────────

final abastecimentosServiceProvider = Provider<AbastecimentosService>((ref) {
  return AbastecimentosService(
    dao: ref.watch(abastecimentosDaoProvider),
    lembretesService: ref.watch(lembretesServiceProvider),
    notifications: ref.watch(notificationsServiceProvider),
  );
});
