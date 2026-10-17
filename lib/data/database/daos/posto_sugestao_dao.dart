import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'posto_sugestao_dao.g.dart';

@DriftAccessor(tables: [PostosSugestao])
class PostoSugestaoDao extends DatabaseAccessor<AppDatabase>
    with _$PostoSugestaoDaoMixin {
  PostoSugestaoDao(super.db);

  /// Insere ou atualiza um posto pelo nome:
  /// - se já existir, incrementa [usoCount] e atualiza [ultimoUso].
  /// - se não existir, insere com count = 1.
  Future<void> upsert(String nome) async {
    final agora = DateTime.now();
    await customStatement(
      'INSERT INTO postos_sugestao (nome, ultimo_uso, uso_count) '
      'VALUES (?, ?, 1) '
      'ON CONFLICT(nome) DO UPDATE SET '
      'ultimo_uso = excluded.ultimo_uso, '
      'uso_count = uso_count + 1',
      [nome, agora.millisecondsSinceEpoch],
    );
  }

  /// Retorna até [limit] sugestões de posto cujo nome contenha [query],
  /// ordenadas por uso_count desc, ultimo_uso desc.
  Future<List<String>> search(String query, {int limit = 10}) async {
    // Escapa \, % e _ (nessa ordem) para tratá-los como literais no LIKE.
    // O parâmetro escapeChar informa ao SQLite a cláusula ESCAPE '\'.
    final escaped = query
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    final pattern = '%$escaped%';
    final rows =
        await (select(postosSugestao)
              ..where((t) => t.nome.like(pattern, escapeChar: r'\'))
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.usoCount,
                  mode: OrderingMode.desc,
                ),
                (t) => OrderingTerm(
                  expression: t.ultimoUso,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(limit))
            .get();
    return rows.map((r) => r.nome).toList();
  }
}
