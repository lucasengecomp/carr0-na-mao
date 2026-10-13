// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manutencoes_dao.dart';

// ignore_for_file: type=lint
mixin _$ManutencoesDaoMixin on DatabaseAccessor<AppDatabase> {
  $VeiculosTable get veiculos => attachedDatabase.veiculos;
  $ManutencoesTable get manutencoes => attachedDatabase.manutencoes;
  ManutencoesDaoManager get managers => ManutencoesDaoManager(this);
}

class ManutencoesDaoManager {
  final _$ManutencoesDaoMixin _db;
  ManutencoesDaoManager(this._db);
  $$VeiculosTableTableManager get veiculos =>
      $$VeiculosTableTableManager(_db.attachedDatabase, _db.veiculos);
  $$ManutencoesTableTableManager get manutencoes =>
      $$ManutencoesTableTableManager(_db.attachedDatabase, _db.manutencoes);
}

mixin _$TiposManutencaoPadraoDaoMixin on DatabaseAccessor<AppDatabase> {
  $TiposManutencaoPadraoTable get tiposManutencaoPadrao =>
      attachedDatabase.tiposManutencaoPadrao;
  TiposManutencaoPadraoDaoManager get managers =>
      TiposManutencaoPadraoDaoManager(this);
}

class TiposManutencaoPadraoDaoManager {
  final _$TiposManutencaoPadraoDaoMixin _db;
  TiposManutencaoPadraoDaoManager(this._db);
  $$TiposManutencaoPadraoTableTableManager get tiposManutencaoPadrao =>
      $$TiposManutencaoPadraoTableTableManager(
        _db.attachedDatabase,
        _db.tiposManutencaoPadrao,
      );
}
