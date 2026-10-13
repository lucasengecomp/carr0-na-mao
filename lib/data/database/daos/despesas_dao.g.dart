// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'despesas_dao.dart';

// ignore_for_file: type=lint
mixin _$DespesasRecorrentesDaoMixin on DatabaseAccessor<AppDatabase> {
  $VeiculosTable get veiculos => attachedDatabase.veiculos;
  $DespesasRecorrentesTable get despesasRecorrentes =>
      attachedDatabase.despesasRecorrentes;
  DespesasRecorrentesDaoManager get managers =>
      DespesasRecorrentesDaoManager(this);
}

class DespesasRecorrentesDaoManager {
  final _$DespesasRecorrentesDaoMixin _db;
  DespesasRecorrentesDaoManager(this._db);
  $$VeiculosTableTableManager get veiculos =>
      $$VeiculosTableTableManager(_db.attachedDatabase, _db.veiculos);
  $$DespesasRecorrentesTableTableManager get despesasRecorrentes =>
      $$DespesasRecorrentesTableTableManager(
        _db.attachedDatabase,
        _db.despesasRecorrentes,
      );
}

mixin _$OcorrenciasDespesaDaoMixin on DatabaseAccessor<AppDatabase> {
  $VeiculosTable get veiculos => attachedDatabase.veiculos;
  $DespesasRecorrentesTable get despesasRecorrentes =>
      attachedDatabase.despesasRecorrentes;
  $OcorrenciasDespesaTable get ocorrenciasDespesa =>
      attachedDatabase.ocorrenciasDespesa;
  OcorrenciasDespesaDaoManager get managers =>
      OcorrenciasDespesaDaoManager(this);
}

class OcorrenciasDespesaDaoManager {
  final _$OcorrenciasDespesaDaoMixin _db;
  OcorrenciasDespesaDaoManager(this._db);
  $$VeiculosTableTableManager get veiculos =>
      $$VeiculosTableTableManager(_db.attachedDatabase, _db.veiculos);
  $$DespesasRecorrentesTableTableManager get despesasRecorrentes =>
      $$DespesasRecorrentesTableTableManager(
        _db.attachedDatabase,
        _db.despesasRecorrentes,
      );
  $$OcorrenciasDespesaTableTableManager get ocorrenciasDespesa =>
      $$OcorrenciasDespesaTableTableManager(
        _db.attachedDatabase,
        _db.ocorrenciasDespesa,
      );
}
