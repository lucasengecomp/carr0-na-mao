import 'package:drift/drift.dart';

import '../app_database.dart';
import '../enums.dart';
import '../tables.dart';

part 'abastecimentos_dao.g.dart';

@DriftAccessor(tables: [Abastecimentos])
class AbastecimentosDao extends DatabaseAccessor<AppDatabase>
    with _$AbastecimentosDaoMixin {
  AbastecimentosDao(super.db);

  Future<int> insertAbastecimento(AbastecimentosCompanion a) =>
      into(abastecimentos).insert(a);

  Future<bool> updateAbastecimento(Abastecimento a) =>
      update(abastecimentos).replace(a);

  Future<int> deleteById(int id) =>
      (delete(abastecimentos)..where((t) => t.id.equals(id))).go();

  Future<Abastecimento?> byId(int id) =>
      (select(abastecimentos)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Abastecimento>> listByVeiculo(String placa) =>
      (select(abastecimentos)
            ..where((t) => t.veiculoPlaca.equals(placa))
            ..orderBy([
              (t) => OrderingTerm(expression: t.data, mode: OrderingMode.desc),
              (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
            ]))
          .get();

  /// Último abastecimento do veículo por km registrado — base da validação
  /// não-bloqueante de km (RF-06).
  Future<Abastecimento?> lastByVeiculo(String placa) =>
      (select(abastecimentos)
            ..where((t) => t.veiculoPlaca.equals(placa))
            ..orderBy([
              (t) => OrderingTerm(expression: t.km, mode: OrderingMode.desc),
            ])
            ..limit(1))
          .getSingleOrNull();

  Stream<List<Abastecimento>> watchByVeiculo(String placa) =>
      (select(abastecimentos)
            ..where((t) => t.veiculoPlaca.equals(placa))
            ..orderBy([
              (t) => OrderingTerm(expression: t.data, mode: OrderingMode.desc),
              (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
            ]))
          .watch();

  /// Stream filtrado por veículo, com filtros opcionais de período e tipo de
  /// combustível. Usado pela tela de lista com filtros (RF-08 / issue #14).
  Stream<List<Abastecimento>> watchFiltered({
    required String placa,
    DateTime? desde,
    TipoCombustivelAbastecimento? tipoCombustivel,
  }) {
    final query = select(abastecimentos)
      ..where((t) {
        Expression<bool> expr = t.veiculoPlaca.equals(placa);
        if (desde != null) {
          expr = expr & t.data.isBiggerOrEqualValue(desde);
        }
        if (tipoCombustivel != null) {
          expr = expr & t.tipoCombustivel.equalsValue(tipoCombustivel);
        }
        return expr;
      })
      ..orderBy([
        (t) => OrderingTerm(expression: t.data, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
      ]);
    return query.watch();
  }
}
