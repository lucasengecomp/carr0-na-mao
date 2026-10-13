// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'abastecimentos_dao.dart';

// ignore_for_file: type=lint
mixin _$AbastecimentosDaoMixin on DatabaseAccessor<AppDatabase> {
  $VeiculosTable get veiculos => attachedDatabase.veiculos;
  $AbastecimentosTable get abastecimentos => attachedDatabase.abastecimentos;
  AbastecimentosDaoManager get managers => AbastecimentosDaoManager(this);
}

class AbastecimentosDaoManager {
  final _$AbastecimentosDaoMixin _db;
  AbastecimentosDaoManager(this._db);
  $$VeiculosTableTableManager get veiculos =>
      $$VeiculosTableTableManager(_db.attachedDatabase, _db.veiculos);
  $$AbastecimentosTableTableManager get abastecimentos =>
      $$AbastecimentosTableTableManager(
        _db.attachedDatabase,
        _db.abastecimentos,
      );
}
