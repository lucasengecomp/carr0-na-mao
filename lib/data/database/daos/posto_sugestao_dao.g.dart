// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'posto_sugestao_dao.dart';

// ignore_for_file: type=lint
mixin _$PostoSugestaoDaoMixin on DatabaseAccessor<AppDatabase> {
  $PostosSugestaoTable get postosSugestao => attachedDatabase.postosSugestao;
  PostoSugestaoDaoManager get managers => PostoSugestaoDaoManager(this);
}

class PostoSugestaoDaoManager {
  final _$PostoSugestaoDaoMixin _db;
  PostoSugestaoDaoManager(this._db);
  $$PostosSugestaoTableTableManager get postosSugestao =>
      $$PostosSugestaoTableTableManager(
        _db.attachedDatabase,
        _db.postosSugestao,
      );
}
