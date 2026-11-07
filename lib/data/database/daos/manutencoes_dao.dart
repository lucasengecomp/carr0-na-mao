import 'package:drift/drift.dart';

import '../app_database.dart';
import '../enums.dart';
import '../tables.dart';

part 'manutencoes_dao.g.dart';

@DriftAccessor(tables: [Manutencoes])
class ManutencoesDao extends DatabaseAccessor<AppDatabase>
    with _$ManutencoesDaoMixin {
  ManutencoesDao(super.db);

  Future<int> insertManutencao(ManutencoesCompanion m) =>
      into(manutencoes).insert(m);

  Future<bool> updateManutencao(Manutencao m) => update(manutencoes).replace(m);

  Future<int> deleteById(int id) =>
      (delete(manutencoes)..where((t) => t.id.equals(id))).go();

  Future<Manutencao?> byId(int id) =>
      (select(manutencoes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Manutencao>> listByVeiculo(String placa) =>
      (select(manutencoes)
            ..where((t) => t.veiculoPlaca.equals(placa))
            ..orderBy([
              (t) => OrderingTerm(expression: t.data, mode: OrderingMode.desc),
              (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
            ]))
          .get();

  /// Sugestões de oficina/local a partir do histórico de manutenções: até
  /// [limit] valores distintos de `oficina` contendo [query], ordenados por
  /// frequência de uso desc e data mais recente desc (mesmo critério do
  /// autocomplete de posto). Não exige tabela auxiliar: novos cadastros
  /// alimentam as sugestões automaticamente.
  Future<List<String>> searchOficinas(String query, {int limit = 10}) async {
    final escaped = query
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    final rows = await customSelect(
      'SELECT oficina FROM manutencoes '
      "WHERE oficina IS NOT NULL AND TRIM(oficina) <> '' "
      "AND oficina LIKE ? ESCAPE '\\' "
      'GROUP BY oficina '
      'ORDER BY COUNT(*) DESC, MAX(data) DESC, oficina ASC '
      'LIMIT ?',
      variables: [Variable.withString('%$escaped%'), Variable.withInt(limit)],
    ).get();
    return rows.map((r) => r.read<String>('oficina')).toList();
  }

  /// Última manutenção do tipo registrada para o veículo — usada para calcular
  /// o próximo intervalo e disparar lembretes.
  Future<Manutencao?> lastByTipo(String placa, TipoManutencao tipo) =>
      (select(manutencoes)
            ..where(
              (t) => t.veiculoPlaca.equals(placa) & t.tipo.equalsValue(tipo),
            )
            ..orderBy([
              (t) => OrderingTerm(expression: t.data, mode: OrderingMode.desc),
              (t) => OrderingTerm(expression: t.km, mode: OrderingMode.desc),
            ])
            ..limit(1))
          .getSingleOrNull();

  Stream<List<Manutencao>> watchByVeiculo(String placa) =>
      (select(manutencoes)
            ..where((t) => t.veiculoPlaca.equals(placa))
            ..orderBy([
              (t) => OrderingTerm(expression: t.data, mode: OrderingMode.desc),
              (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
            ]))
          .watch();
}

@DriftAccessor(tables: [TiposManutencaoPadrao])
class TiposManutencaoPadraoDao extends DatabaseAccessor<AppDatabase>
    with _$TiposManutencaoPadraoDaoMixin {
  TiposManutencaoPadraoDao(super.db);

  Future<TipoManutencaoPadrao?> byTipo(TipoManutencao tipo) => (select(
    tiposManutencaoPadrao,
  )..where((t) => t.tipo.equalsValue(tipo))).getSingleOrNull();

  Future<List<TipoManutencaoPadrao>> listAll() =>
      select(tiposManutencaoPadrao).get();
}
