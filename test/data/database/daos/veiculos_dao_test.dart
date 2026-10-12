import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

VeiculosCompanion _novo({
  String placa = 'ABC1D23',
  String? apelido,
  String marca = 'Fiat',
  String modelo = 'Uno',
  int ano = 2020,
  TipoVeiculo tipo = TipoVeiculo.carro,
  TipoCombustivelVeiculo combustivel = TipoCombustivelVeiculo.flex,
  int kmInicial = 10000,
}) => VeiculosCompanion.insert(
  placa: placa,
  apelido: Value(apelido),
  marca: marca,
  modelo: modelo,
  ano: ano,
  tipo: tipo,
  combustivel: combustivel,
  kmInicial: kmInicial,
);

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('insere e busca por placa', () async {
    await db.veiculosDao.insertVeiculo(_novo(apelido: 'Uninho'));

    final v = await db.veiculosDao.byPlaca('ABC1D23');
    expect(v, isNotNull);
    expect(v!.apelido, 'Uninho');
    expect(v.arquivado, isFalse);
  });

  test('placa duplicada falha', () async {
    await db.veiculosDao.insertVeiculo(_novo());

    expect(
      () => db.veiculosDao.insertVeiculo(_novo()),
      throwsA(isA<Exception>()),
    );
  });

  test('arquivar e restaurar', () async {
    await db.veiculosDao.insertVeiculo(_novo());

    final rowsArq = await db.veiculosDao.arquivar('ABC1D23');
    expect(rowsArq, 1);
    expect((await db.veiculosDao.byPlaca('ABC1D23'))!.arquivado, isTrue);

    final rowsRes = await db.veiculosDao.restaurar('ABC1D23');
    expect(rowsRes, 1);
    expect((await db.veiculosDao.byPlaca('ABC1D23'))!.arquivado, isFalse);
  });

  test('listAtivos ignora arquivados', () async {
    await db.veiculosDao.insertVeiculo(
      _novo(placa: 'ABC1D23', apelido: 'Ativo'),
    );
    await db.veiculosDao.insertVeiculo(
      _novo(placa: 'XYZ9A99', apelido: 'Arquivado'),
    );
    await db.veiculosDao.arquivar('XYZ9A99');

    final ativos = await db.veiculosDao.listAtivos();
    expect(ativos, hasLength(1));
    expect(ativos.single.placa, 'ABC1D23');

    final arquivados = await db.veiculosDao.listArquivados();
    expect(arquivados, hasLength(1));
    expect(arquivados.single.placa, 'XYZ9A99');
  });

  test('updateByPlaca modifica campos', () async {
    await db.veiculosDao.insertVeiculo(_novo());

    final rows = await db.veiculosDao.updateByPlaca(
      'ABC1D23',
      const VeiculosCompanion(apelido: Value('Novo nome'), ano: Value(2021)),
    );
    expect(rows, 1);

    final v = await db.veiculosDao.byPlaca('ABC1D23');
    expect(v!.apelido, 'Novo nome');
    expect(v.ano, 2021);
    expect(v.modelo, 'Uno', reason: 'campos não enviados ficam intactos');
  });

  test('deleteByPlaca remove o registro', () async {
    await db.veiculosDao.insertVeiculo(_novo());

    final rows = await db.veiculosDao.deleteByPlaca('ABC1D23');
    expect(rows, 1);
    expect(await db.veiculosDao.byPlaca('ABC1D23'), isNull);
  });

  test('watchAtivos emite mudanças', () async {
    final events = <int>[];
    final sub = db.veiculosDao.watchAtivos().listen(
      (list) => events.add(list.length),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    await db.veiculosDao.insertVeiculo(_novo());
    await Future<void>.delayed(const Duration(milliseconds: 10));

    await db.veiculosDao.arquivar('ABC1D23');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    await sub.cancel();
    expect(events, [0, 1, 0]);
  });
}
