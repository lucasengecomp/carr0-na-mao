// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lembretes_dao.dart';

// ignore_for_file: type=lint
mixin _$LembretesDaoMixin on DatabaseAccessor<AppDatabase> {
  $VeiculosTable get veiculos => attachedDatabase.veiculos;
  $ManutencoesTable get manutencoes => attachedDatabase.manutencoes;
  $LembretesTable get lembretes => attachedDatabase.lembretes;
  LembretesDaoManager get managers => LembretesDaoManager(this);
}

class LembretesDaoManager {
  final _$LembretesDaoMixin _db;
  LembretesDaoManager(this._db);
  $$VeiculosTableTableManager get veiculos =>
      $$VeiculosTableTableManager(_db.attachedDatabase, _db.veiculos);
  $$ManutencoesTableTableManager get manutencoes =>
      $$ManutencoesTableTableManager(_db.attachedDatabase, _db.manutencoes);
  $$LembretesTableTableManager get lembretes =>
      $$LembretesTableTableManager(_db.attachedDatabase, _db.lembretes);
}
