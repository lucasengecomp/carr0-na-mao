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

  /// Todos os abastecimentos de todos os veículos, sem filtro.
  /// Usado para montar o mapa de km atual por placa (issue #68).
  Stream<List<Abastecimento>> watchAll() =>
      (select(abastecimentos)..orderBy([
            (t) => OrderingTerm(expression: t.km, mode: OrderingMode.desc),
          ]))
          .watch();

  Stream<List<Abastecimento>> watchByVeiculo(String placa) =>
      (select(abastecimentos)
            ..where((t) => t.veiculoPlaca.equals(placa))
            ..orderBy([
              (t) => OrderingTerm(expression: t.data, mode: OrderingMode.desc),
              (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
            ]))
          .watch();

  /// Stream filtrado por veículo, com filtros opcionais de período e tipos de
  /// combustível. Usado pela tela de lista com filtros (RF-08 / issue #14).
  ///
  /// [tiposCombustivel]:
  ///   - null → sem filtro (todos os combustíveis).
  ///   - Set não-vazio → WHERE combustivel IN (...).
  ///   - Set vazio → chamador deve exibir estado vazio; este método retorna
  ///     stream vazio imediatamente para evitar query desnecessária.
  Stream<List<Abastecimento>> watchFiltered({
    required String placa,
    DateTime? desde,
    Set<TipoCombustivelAbastecimento>? tiposCombustivel,
  }) {
    // Nenhum tipo selecionado → estado vazio sem consultar o banco.
    if (tiposCombustivel != null && tiposCombustivel.isEmpty) {
      return Stream.value(const []);
    }

    final query = select(abastecimentos)
      ..where((t) {
        Expression<bool> expr = t.veiculoPlaca.equals(placa);
        if (desde != null) {
          expr = expr & t.data.isBiggerOrEqualValue(desde);
        }
        if (tiposCombustivel != null && tiposCombustivel.isNotEmpty) {
          expr =
              expr &
              t.tipoCombustivel.isIn(tiposCombustivel.map((e) => e.name));
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
