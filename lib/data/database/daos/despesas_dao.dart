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

  /// Retorna todas as despesas ativas de todos os veículos (para rotina
  /// de startup).
  Future<List<DespesaRecorrente>> listAtivas() =>
      (select(despesasRecorrentes)..where((t) => t.ativa.equals(true))).get();
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

  /// Gera ocorrências para [despesa] até o último dia do mês corrente,
  /// de forma idempotente — não duplica datas já existentes.
  ///
  /// Regras:
  /// - `unica`: gera uma única ocorrência em [dataInicio].
  /// - `mensal`: gera uma ocorrência por mês entre [dataInicio] e o fim do
  ///   mês corrente, usando [diaDoMes] como dia (ou o dia de [dataInicio]).
  /// - `anual`: gera uma ocorrência por ano nas mesmas condições, restrita
  ///   ao mês/dia de [dataInicio].
  /// - `semanal`: gera uma ocorrência por semana a partir de [dataInicio].
  ///
  /// A data de [dataFim] da despesa é respeitada como limite superior.
  Future<void> materializar(DespesaRecorrente despesa) async {
    final hoje = DateTime.now();
    final fimMesCorrente = DateTime(hoje.year, hoje.month + 1, 0);
    final limiteMax =
        despesa.dataFim != null && despesa.dataFim!.isBefore(fimMesCorrente)
        ? despesa.dataFim!
        : fimMesCorrente;

    // Busca todas as datas de vencimento já existentes para evitar duplicatas.
    final existentes = await (select(
      ocorrenciasDespesa,
    )..where((t) => t.despesaId.equals(despesa.id))).get();
    final datasExistentes = existentes
        .map((o) => _normalizarData(o.dataVencimento))
        .toSet();

    final novas = <OcorrenciasDespesaCompanion>[];

    switch (despesa.frequencia) {
      case FrequenciaDespesa.unica:
        final dt = _normalizarData(despesa.dataInicio);
        if (!dt.isAfter(limiteMax) && !datasExistentes.contains(dt)) {
          novas.add(_novaOcorrencia(despesa.id, dt, despesa.valor));
        }

      case FrequenciaDespesa.mensal:
        final dia = despesa.diaDoMes ?? despesa.dataInicio.day;
        final dataInicioNormMensal = _normalizarData(despesa.dataInicio);
        var cursor = DateTime(
          despesa.dataInicio.year,
          despesa.dataInicio.month,
          dia.clamp(
            1,
            _diasNoMes(despesa.dataInicio.year, despesa.dataInicio.month),
          ),
        );
        // Avança para o mês de dataInicio se o dia calculado ficou antes.
        if (cursor.isBefore(dataInicioNormMensal)) {
          cursor = DateTime(
            despesa.dataInicio.year,
            despesa.dataInicio.month + 1,
            dia.clamp(
              1,
              _diasNoMes(despesa.dataInicio.year, despesa.dataInicio.month + 1),
            ),
          );
        }
        while (!cursor.isAfter(limiteMax)) {
          final dt = _normalizarData(cursor);
          if (!datasExistentes.contains(dt)) {
            novas.add(_novaOcorrencia(despesa.id, dt, despesa.valor));
          }
          cursor = DateTime(
            cursor.year,
            cursor.month + 1,
            dia.clamp(1, _diasNoMes(cursor.year, cursor.month + 1)),
          );
        }

      case FrequenciaDespesa.anual:
        final dia = despesa.diaDoMes ?? despesa.dataInicio.day;
        final dataInicioNormAnual = _normalizarData(despesa.dataInicio);
        var cursor = DateTime(
          despesa.dataInicio.year,
          despesa.dataInicio.month,
          dia.clamp(
            1,
            _diasNoMes(despesa.dataInicio.year, despesa.dataInicio.month),
          ),
        );
        if (cursor.isBefore(dataInicioNormAnual)) {
          cursor = DateTime(
            despesa.dataInicio.year + 1,
            despesa.dataInicio.month,
            dia.clamp(
              1,
              _diasNoMes(despesa.dataInicio.year + 1, despesa.dataInicio.month),
            ),
          );
        }
        while (!cursor.isAfter(limiteMax)) {
          final dt = _normalizarData(cursor);
          if (!datasExistentes.contains(dt)) {
            novas.add(_novaOcorrencia(despesa.id, dt, despesa.valor));
          }
          cursor = DateTime(
            cursor.year + 1,
            cursor.month,
            dia.clamp(1, _diasNoMes(cursor.year + 1, cursor.month)),
          );
        }

      case FrequenciaDespesa.semanal:
        var cursor = _normalizarData(despesa.dataInicio);
        while (!cursor.isAfter(limiteMax)) {
          if (!datasExistentes.contains(cursor)) {
            novas.add(_novaOcorrencia(despesa.id, cursor, despesa.valor));
          }
          cursor = cursor.add(const Duration(days: 7));
        }
    }

    if (novas.isNotEmpty) {
      await batch((b) => b.insertAll(ocorrenciasDespesa, novas));
    }
  }

  OcorrenciasDespesaCompanion _novaOcorrencia(
    int despesaId,
    DateTime dataVencimento,
    double valor,
  ) => OcorrenciasDespesaCompanion.insert(
    despesaId: despesaId,
    dataVencimento: dataVencimento,
    status: StatusOcorrencia.pendente,
    valorPago: const Value(null),
    dataPagamento: const Value(null),
  );

  /// Normaliza para meia-noite UTC local (remove hora/minuto/segundo) para
  /// comparação de datas sem conflito de fuso.
  static DateTime _normalizarData(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  /// Retorna o número de dias no mês, tratando overflow (mês 13 vira jan
  /// do ano seguinte via DateTime do Dart).
  static int _diasNoMes(int ano, int mes) => DateTime(ano, mes + 1, 0).day;
}
