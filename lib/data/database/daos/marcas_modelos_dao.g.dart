// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marcas_modelos_dao.dart';

// ignore_for_file: type=lint
mixin _$MarcasModelosDaoMixin on DatabaseAccessor<AppDatabase> {
  $MarcasTable get marcas => attachedDatabase.marcas;
  $ModelosTable get modelos => attachedDatabase.modelos;
  MarcasModelosDaoManager get managers => MarcasModelosDaoManager(this);
}

class MarcasModelosDaoManager {
  final _$MarcasModelosDaoMixin _db;
  MarcasModelosDaoManager(this._db);
  $$MarcasTableTableManager get marcas =>
      $$MarcasTableTableManager(_db.attachedDatabase, _db.marcas);
  $$ModelosTableTableManager get modelos =>
      $$ModelosTableTableManager(_db.attachedDatabase, _db.modelos);
}
