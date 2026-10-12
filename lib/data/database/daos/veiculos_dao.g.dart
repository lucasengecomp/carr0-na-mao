// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'veiculos_dao.dart';

// ignore_for_file: type=lint
mixin _$VeiculosDaoMixin on DatabaseAccessor<AppDatabase> {
  $VeiculosTable get veiculos => attachedDatabase.veiculos;
  VeiculosDaoManager get managers => VeiculosDaoManager(this);
}

class VeiculosDaoManager {
  final _$VeiculosDaoMixin _db;
  VeiculosDaoManager(this._db);
  $$VeiculosTableTableManager get veiculos =>
      $$VeiculosTableTableManager(_db.attachedDatabase, _db.veiculos);
}
