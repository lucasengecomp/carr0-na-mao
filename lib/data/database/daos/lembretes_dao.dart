import 'package:drift/drift.dart';

import '../app_database.dart';
import '../enums.dart';
import '../tables.dart';

part 'lembretes_dao.g.dart';

@DriftAccessor(tables: [Lembretes])
class LembretesDao extends DatabaseAccessor<AppDatabase>
    with _$LembretesDaoMixin {
  LembretesDao(super.db);

  Future<int> insertLembrete(LembretesCompanion l) => into(lembretes).insert(l);

  Future<bool> updateLembrete(Lembrete l) => update(lembretes).replace(l);

  Future<int> deleteById(int id) =>
      (delete(lembretes)..where((t) => t.id.equals(id))).go();

  Future<Lembrete?> byId(int id) =>
      (select(lembretes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Lembrete>> listByVeiculo(String placa) =>
      (select(lembretes)
            ..where((t) => t.veiculoPlaca.equals(placa))
            ..orderBy([
              (t) => OrderingTerm(expression: t.dataAlvo),
              (t) => OrderingTerm(expression: t.kmAlvo),
            ]))
          .get();

  Future<List<Lembrete>> listPendentesByVeiculo(String placa) =>
      (select(lembretes)
            ..where(
              (t) =>
                  t.veiculoPlaca.equals(placa) &
                  (t.status.equalsValue(StatusLembrete.pendente) |
                      t.status.equalsValue(StatusLembrete.adiado)),
            )
            ..orderBy([
              (t) => OrderingTerm(expression: t.dataAlvo),
              (t) => OrderingTerm(expression: t.kmAlvo),
            ]))
          .get();

  /// Lembretes cujo km_alvo foi atingido/ultrapassado pelo km informado.
  /// Útil para disparar notificação ao salvar um abastecimento (RF-15).
  Future<List<Lembrete>> findVencidosPorKm(String placa, int kmAtual) =>
      (select(lembretes)..where(
            (t) =>
                t.veiculoPlaca.equals(placa) &
                t.status.equalsValue(StatusLembrete.pendente) &
                t.kmAlvo.isNotNull() &
                t.kmAlvo.isSmallerOrEqualValue(kmAtual),
          ))
          .get();

  /// Lembretes pendentes ou adiados do veículo, ordenados por dataAlvo/kmAlvo.
  /// Usado pelo dashboard (card "próximas manutenções") e pelo serviço de
  /// lembretes. Inclui adiados pois, após adiar, o lembrete volta para a fila
  /// de pendentes com nova data_alvo (issue #116).
  Stream<List<Lembrete>> watchPendentesByVeiculo(String placa) =>
      (select(lembretes)
            ..where(
              (t) =>
                  t.veiculoPlaca.equals(placa) &
                  (t.status.equalsValue(StatusLembrete.pendente) |
                      t.status.equalsValue(StatusLembrete.adiado)),
            )
            ..orderBy([
              (t) => OrderingTerm(expression: t.dataAlvo),
              (t) => OrderingTerm(expression: t.kmAlvo),
            ]))
          .watch();

  /// Todos os lembretes de todos os veículos, sem filtro de status.
  /// Usado pela tela de lista global (issue #25), que filtra por status no
  /// Dart via providers.
  Stream<List<Lembrete>> watchAll() =>
      (select(lembretes)..orderBy([
            (t) => OrderingTerm(expression: t.dataAlvo),
            (t) => OrderingTerm(expression: t.kmAlvo),
          ]))
          .watch();

  Future<int> marcarConcluido(int id) =>
      (update(lembretes)..where((t) => t.id.equals(id))).write(
        const LembretesCompanion(status: Value(StatusLembrete.concluido)),
      );

  Future<int> adiar(int id, {DateTime? novaData, int? novoKm}) =>
      (update(lembretes)..where((t) => t.id.equals(id))).write(
        LembretesCompanion(
          dataAlvo: Value(novaData),
          kmAlvo: Value(novoKm),
          status: const Value(StatusLembrete.adiado),
        ),
      );

  /// Substitui (ou cria) o lembrete de manutenção para o par
  /// (veículo, tipo de manutenção) — usado pela regra do RF-14.
  Future<void> upsertByManutencao({
    required String placa,
    required int manutencaoId,
    required String tipo,
    required String descricao,
    DateTime? dataAlvo,
    int? kmAlvo,
  }) async {
    await transaction(() async {
      await (delete(lembretes)..where(
            (t) =>
                t.veiculoPlaca.equals(placa) &
                t.tipo.equals(tipo) &
                t.status.equalsValue(StatusLembrete.pendente),
          ))
          .go();
      await into(lembretes).insert(
        LembretesCompanion.insert(
          veiculoPlaca: placa,
          manutencaoId: Value(manutencaoId),
          tipo: tipo,
          descricao: descricao,
          dataAlvo: Value(dataAlvo),
          kmAlvo: Value(kmAlvo),
          status: StatusLembrete.pendente,
        ),
      );
    });
  }
}
