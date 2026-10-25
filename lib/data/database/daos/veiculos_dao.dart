import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'veiculos_dao.g.dart';

@DriftAccessor(tables: [Veiculos])
class VeiculosDao extends DatabaseAccessor<AppDatabase>
    with _$VeiculosDaoMixin {
  VeiculosDao(super.db);

  Future<int> insertVeiculo(VeiculosCompanion v) => into(veiculos).insert(v);

  Future<int> updateByPlaca(String placa, VeiculosCompanion v) =>
      (update(veiculos)..where((t) => t.placa.equals(placa))).write(v);

  Future<int> arquivar(String placa) =>
      (update(veiculos)..where((t) => t.placa.equals(placa))).write(
        const VeiculosCompanion(arquivado: Value(true)),
      );

  Future<int> restaurar(String placa) =>
      (update(veiculos)..where((t) => t.placa.equals(placa))).write(
        const VeiculosCompanion(arquivado: Value(false)),
      );

  Future<int> deleteByPlaca(String placa) =>
      (delete(veiculos)..where((t) => t.placa.equals(placa))).go();

  Future<Veiculo?> byPlaca(String placa) =>
      (select(veiculos)..where((t) => t.placa.equals(placa))).getSingleOrNull();

  Future<List<Veiculo>> listAtivos() =>
      (select(veiculos)
            ..where((t) => t.arquivado.equals(false))
            ..orderBy([(t) => OrderingTerm(expression: t.apelido)]))
          .get();

  Future<List<Veiculo>> listArquivados() =>
      (select(veiculos)..where((t) => t.arquivado.equals(true))).get();

  Stream<List<Veiculo>> watchAtivos() =>
      (select(veiculos)
            ..where((t) => t.arquivado.equals(false))
            ..orderBy([(t) => OrderingTerm(expression: t.apelido)]))
          .watch();

  Stream<List<Veiculo>> watchArquivados() =>
      (select(veiculos)
            ..where((t) => t.arquivado.equals(true))
            ..orderBy([(t) => OrderingTerm(expression: t.apelido)]))
          .watch();

  /// Retorna todos os veículos (ativos e arquivados), ordenados por apelido.
  Stream<List<Veiculo>> watchTodos() => (select(
    veiculos,
  )..orderBy([(t) => OrderingTerm(expression: t.apelido)])).watch();
}
