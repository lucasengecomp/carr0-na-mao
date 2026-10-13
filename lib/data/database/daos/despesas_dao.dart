import 'package:drift/drift.dart';

import '../app_database.dart';
import '../enums.dart';
import '../tables.dart';

part 'despesas_dao.g.dart';

@DriftAccessor(tables: [DespesasRecorrentes])
class DespesasRecorrentesDao extends DatabaseAccessor<AppDatabase>
    with _$DespesasRecorrentesDaoMixin {
  DespesasRecorrentesDao(super.db);

  Future<int> insertDespesa(DespesasRecorrentesCompanion d) =>
      into(despesasRecorrentes).insert(d);

  Future<bool> updateDespesa(DespesaRecorrente d) =>
      update(despesasRecorrentes).replace(d);

  Future<int> deleteById(int id) =>
      (delete(despesasRecorrentes)..where((t) => t.id.equals(id))).go();

  Future<DespesaRecorrente?> byId(int id) => (select(
    despesasRecorrentes,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<DespesaRecorrente>> listByVeiculo(String placa) =>
      (select(despesasRecorrentes)
            ..where((t) => t.veiculoPlaca.equals(placa))
            ..orderBy([(t) => OrderingTerm(expression: t.nome)]))
          .get();

  Stream<List<DespesaRecorrente>> watchByVeiculo(String placa) =>
      (select(despesasRecorrentes)
            ..where((t) => t.veiculoPlaca.equals(placa))
            ..orderBy([(t) => OrderingTerm(expression: t.nome)]))
          .watch();
}

@DriftAccessor(tables: [OcorrenciasDespesa])
class OcorrenciasDespesaDao extends DatabaseAccessor<AppDatabase>
    with _$OcorrenciasDespesaDaoMixin {
  OcorrenciasDespesaDao(super.db);

  Future<int> insertOcorrencia(OcorrenciasDespesaCompanion o) =>
      into(ocorrenciasDespesa).insert(o);

  Future<int> deleteById(int id) =>
      (delete(ocorrenciasDespesa)..where((t) => t.id.equals(id))).go();

  Future<OcorrenciaDespesa?> byId(int id) => (select(
    ocorrenciasDespesa,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<OcorrenciaDespesa>> listByDespesa(int despesaId) =>
      (select(ocorrenciasDespesa)
            ..where((t) => t.despesaId.equals(despesaId))
            ..orderBy([(t) => OrderingTerm(expression: t.dataVencimento)]))
          .get();

  /// Pendentes de um veículo ordenadas por vencimento. Usa join para filtrar
  /// pelo veículo via despesa_recorrente.
  Future<List<OcorrenciaDespesa>> listPendentesByVeiculo(String placa) async {
    final query =
        select(ocorrenciasDespesa).join([
            innerJoin(
              attachedDatabase.despesasRecorrentes,
              attachedDatabase.despesasRecorrentes.id.equalsExp(
                ocorrenciasDespesa.despesaId,
              ),
            ),
          ])
          ..where(
            attachedDatabase.despesasRecorrentes.veiculoPlaca.equals(placa),
          )
          ..where(
            ocorrenciasDespesa.status.equalsValue(StatusOcorrencia.pendente),
          )
          ..orderBy([
            OrderingTerm(expression: ocorrenciasDespesa.dataVencimento),
          ]);
    final rows = await query.get();
    return rows.map((r) => r.readTable(ocorrenciasDespesa)).toList();
  }

  Future<int> marcarPaga(
    int id, {
    required double valorPago,
    required DateTime dataPagamento,
  }) => (update(ocorrenciasDespesa)..where((t) => t.id.equals(id))).write(
    OcorrenciasDespesaCompanion(
      status: const Value(StatusOcorrencia.paga),
      valorPago: Value(valorPago),
      dataPagamento: Value(dataPagamento),
    ),
  );

  Future<int> marcarPulada(int id) =>
      (update(ocorrenciasDespesa)..where((t) => t.id.equals(id))).write(
        const OcorrenciasDespesaCompanion(
          status: Value(StatusOcorrencia.pulada),
        ),
      );
}
