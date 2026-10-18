import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/database/daos/lembretes_dao.dart';
import '../data/providers.dart';
import 'notifications_service.dart';

/// Serviço que orquestra operações de [LembretesDao] + agendamento de
/// notificações via [NotificationsService].
///
/// Use este serviço nos formulários de criação/edição/conclusão de lembretes,
/// em vez de chamar o DAO diretamente.
class LembretesService {
  LembretesService({required this._dao, required this._notifications});

  final LembretesDao _dao;
  final NotificationsService _notifications;

  // ── Leitura (delega ao DAO) ───────────────────────────────────────────────

  Future<Lembrete?> byId(int id) => _dao.byId(id);

  Future<List<Lembrete>> listByVeiculo(String placa) =>
      _dao.listByVeiculo(placa);

  Future<List<Lembrete>> listPendentesByVeiculo(String placa) =>
      _dao.listPendentesByVeiculo(placa);

  Stream<List<Lembrete>> watchPendentesByVeiculo(String placa) =>
      _dao.watchPendentesByVeiculo(placa);

  Future<List<Lembrete>> findVencidosPorKm(String placa, int kmAtual) =>
      _dao.findVencidosPorKm(placa, kmAtual);

  // ── Escrita + notificações ────────────────────────────────────────────────

  /// Insere um novo lembrete e agenda a notificação de data.
  Future<int> insertLembrete(LembretesCompanion companion) async {
    final id = await _dao.insertLembrete(companion);
    final lembrete = await _dao.byId(id);
    if (lembrete != null) {
      await _notifications.scheduleLembrete(lembrete);
    }
    return id;
  }

  /// Atualiza um lembrete e re-agenda a notificação.
  Future<bool> updateLembrete(Lembrete lembrete) async {
    final ok = await _dao.updateLembrete(lembrete);
    if (ok) {
      await _notifications.scheduleLembrete(lembrete);
    }
    return ok;
  }

  /// Exclui um lembrete e cancela a notificação.
  Future<int> deleteById(int id) async {
    await _notifications.cancelLembrete(id);
    return _dao.deleteById(id);
  }

  /// Marca lembrete como concluído e cancela a notificação agendada.
  Future<int> marcarConcluido(int id) async {
    final count = await _dao.marcarConcluido(id);
    await _notifications.cancelLembrete(id);
    return count;
  }

  /// Adia um lembrete e re-agenda a notificação.
  Future<int> adiar(int id, {DateTime? novaData, int? novoKm}) async {
    final count = await _dao.adiar(id, novaData: novaData, novoKm: novoKm);
    final lembrete = await _dao.byId(id);
    if (lembrete != null) {
      await _notifications.scheduleLembrete(lembrete);
    }
    return count;
  }

  /// Upsert de manutenção (RF-14) + re-agenda notificação.
  Future<void> upsertByManutencao({
    required String placa,
    required int manutencaoId,
    required String tipo,
    required String descricao,
    DateTime? dataAlvo,
    int? kmAlvo,
  }) async {
    await _dao.upsertByManutencao(
      placa: placa,
      manutencaoId: manutencaoId,
      tipo: tipo,
      descricao: descricao,
      dataAlvo: dataAlvo,
      kmAlvo: kmAlvo,
    );
    // Busca o lembrete recém-inserido para agendar.
    final pendentes = await _dao.listPendentesByVeiculo(placa);
    final lembrete = pendentes
        .where((Lembrete l) => l.tipo == tipo)
        .firstOrNull;
    if (lembrete != null) {
      await _notifications.scheduleLembrete(lembrete);
    }
  }

  /// Cancela todas as notificações de lembretes de um veículo (chamado ao
  /// arquivar).
  Future<void> cancelarNotificacoesPorVeiculo(String placa) async {
    final lembretes = await _dao.listPendentesByVeiculo(placa);
    await _notifications.cancelByVeiculoLembretes(lembretes);
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final lembretesServiceProvider = Provider<LembretesService>((ref) {
  return LembretesService(
    dao: ref.watch(lembretesDaoProvider),
    notifications: ref.watch(notificationsServiceProvider),
  );
});
