import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

VeiculosCompanion _novoVeiculo({String placa = 'ABC1D23'}) =>
    VeiculosCompanion.insert(
      placa: placa,
      marca: 'Fiat',
      modelo: 'Uno',
      ano: 2020,
      tipo: TipoVeiculo.carro,
      combustivel: TipoCombustivelVeiculo.flex,
      kmInicial: 10000,
    );

AbastecimentosCompanion _novoAbast({
  String placa = 'ABC1D23',
  required DateTime data,
  required int km,
  double litros = 40,
  double precoLitro = 6,
  double valorTotal = 240,
  String? posto,
  bool tanqueCheio = true,
  TipoCombustivelAbastecimento combustivel =
      TipoCombustivelAbastecimento.gasolina,
}) => AbastecimentosCompanion.insert(
  veiculoPlaca: placa,
  data: data,
  km: km,
  tipoCombustivel: combustivel,
  precoLitro: precoLitro,
  valorTotal: valorTotal,
  litros: litros,
  posto: Value(posto),
  tanqueCheio: Value(tanqueCheio),
);

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.veiculosDao.insertVeiculo(_novoVeiculo());
  });

  tearDown(() async {
    await db.close();
  });

  test('insere e busca por id', () async {
    final id = await db.abastecimentosDao.insertAbastecimento(
      _novoAbast(data: DateTime(2026, 1, 10), km: 10100, posto: 'Shell'),
    );

    final a = await db.abastecimentosDao.byId(id);
    expect(a, isNotNull);
    expect(a!.posto, 'Shell');
    expect(a.litros, 40);
    expect(a.tanqueCheio, isTrue);
  });

  test('listByVeiculo retorna por data descendente', () async {
    await db.abastecimentosDao.insertAbastecimento(
      _novoAbast(data: DateTime(2026, 1, 10), km: 10100),
    );
    await db.abastecimentosDao.insertAbastecimento(
      _novoAbast(data: DateTime(2026, 3, 5), km: 10800),
    );
    await db.abastecimentosDao.insertAbastecimento(
      _novoAbast(data: DateTime(2026, 2, 1), km: 10400),
    );

    final lista = await db.abastecimentosDao.listByVeiculo('ABC1D23');
    expect(lista.map((a) => a.data), [
      DateTime(2026, 3, 5),
      DateTime(2026, 2, 1),
      DateTime(2026, 1, 10),
    ]);
  });

  test('lastByVeiculo devolve o maior km', () async {
    await db.abastecimentosDao.insertAbastecimento(
      _novoAbast(data: DateTime(2026, 1, 10), km: 10100),
    );
    await db.abastecimentosDao.insertAbastecimento(
      _novoAbast(data: DateTime(2026, 2, 10), km: 10800),
    );
    await db.abastecimentosDao.insertAbastecimento(
      _novoAbast(data: DateTime(2026, 3, 1), km: 10500),
    );

    final last = await db.abastecimentosDao.lastByVeiculo('ABC1D23');
    expect(last!.km, 10800);
  });

  test('lastByVeiculo em veículo sem registros devolve null', () async {
    final last = await db.abastecimentosDao.lastByVeiculo('ABC1D23');
    expect(last, isNull);
  });

  test('updateAbastecimento altera campos', () async {
    final id = await db.abastecimentosDao.insertAbastecimento(
      _novoAbast(data: DateTime(2026, 1, 10), km: 10100, posto: 'Shell'),
    );

    final existing = (await db.abastecimentosDao.byId(id))!;
    final atualizado = existing.copyWith(
      posto: const Value('Ipiranga'),
      litros: 42,
    );
    final ok = await db.abastecimentosDao.updateAbastecimento(atualizado);
    expect(ok, isTrue);

    final novo = await db.abastecimentosDao.byId(id);
    expect(novo!.posto, 'Ipiranga');
    expect(novo.litros, 42);
  });

  test('deleteById remove o registro', () async {
    final id = await db.abastecimentosDao.insertAbastecimento(
      _novoAbast(data: DateTime(2026, 1, 10), km: 10100),
    );

    final rows = await db.abastecimentosDao.deleteById(id);
    expect(rows, 1);
    expect(await db.abastecimentosDao.byId(id), isNull);
  });

  test(
    'deleteById remove apenas o registro solicitado — outros permanecem',
    () async {
      final id1 = await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: DateTime(2026, 1, 10), km: 10100),
      );
      final id2 = await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: DateTime(2026, 2, 10), km: 10500),
      );
      final id3 = await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: DateTime(2026, 3, 10), km: 10900),
      );

      // Deleta o do meio (intermediário)
      final rows = await db.abastecimentosDao.deleteById(id2);
      expect(rows, 1);
      expect(await db.abastecimentosDao.byId(id1), isNotNull);
      expect(await db.abastecimentosDao.byId(id2), isNull);
      expect(await db.abastecimentosDao.byId(id3), isNotNull);
    },
  );

  test('watchByVeiculo emite ao inserir', () async {
    final events = <int>[];
    final sub = db.abastecimentosDao
        .watchByVeiculo('ABC1D23')
        .listen((list) => events.add(list.length));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    await db.abastecimentosDao.insertAbastecimento(
      _novoAbast(data: DateTime(2026, 1, 10), km: 10100),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    await sub.cancel();
    expect(events, [0, 1]);
  });
}
