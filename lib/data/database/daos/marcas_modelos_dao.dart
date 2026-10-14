import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'marcas_modelos_dao.g.dart';

@DriftAccessor(tables: [Marcas, Modelos])
class MarcasModelosDao extends DatabaseAccessor<AppDatabase>
    with _$MarcasModelosDaoMixin {
  MarcasModelosDao(super.db);

  /// Popula marcas e modelos a partir do JSON do asset. Idempotente: usa
  /// INSERT OR IGNORE, então rodar várias vezes não duplica nem sobrescreve
  /// dados que o usuário possa ter adicionado.
  Future<void> seedFromJson(String json) async {
    final parsed = jsonDecode(json) as Map<String, dynamic>;
    final list = (parsed['marcas'] as List).cast<Map<String, dynamic>>();

    await batch((b) {
      for (final entry in list) {
        final nomeMarca = entry['marca'] as String;
        b.insert(
          marcas,
          MarcasCompanion.insert(nome: nomeMarca),
          mode: InsertMode.insertOrIgnore,
        );
        for (final nomeModelo in (entry['modelos'] as List).cast<String>()) {
          b.insert(
            modelos,
            ModelosCompanion.insert(marca: nomeMarca, nome: nomeModelo),
            mode: InsertMode.insertOrIgnore,
          );
        }
      }
    });
  }

  Future<List<String>> listMarcas() async {
    final rows = await (select(
      marcas,
    )..orderBy([(t) => OrderingTerm(expression: t.nome)])).get();
    return rows.map((m) => m.nome).toList();
  }

  Stream<List<String>> watchMarcas() =>
      (select(marcas)..orderBy([(t) => OrderingTerm(expression: t.nome)]))
          .watch()
          .map((rows) => rows.map((m) => m.nome).toList());

  Future<List<String>> listModelosByMarca(String marca) async {
    final rows =
        await (select(modelos)
              ..where((t) => t.marca.equals(marca))
              ..orderBy([(t) => OrderingTerm(expression: t.nome)]))
            .get();
    return rows.map((m) => m.nome).toList();
  }
}
