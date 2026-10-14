import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _jsonBase = '''
{
  "assetsVersion": 1,
  "marcas": [
    { "marca": "Fiat", "modelos": ["Uno", "Mobi"] },
    { "marca": "Volkswagen", "modelos": ["Gol", "Polo"] }
  ]
}
''';

const _jsonExpandido = '''
{
  "assetsVersion": 2,
  "marcas": [
    { "marca": "Fiat", "modelos": ["Uno", "Mobi", "Argo"] },
    { "marca": "Volkswagen", "modelos": ["Gol", "Polo"] },
    { "marca": "Honda", "modelos": ["Civic"] }
  ]
}
''';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('seed popula marcas e modelos', () async {
    await db.marcasModelosDao.seedFromJson(_jsonBase);

    expect(await db.marcasModelosDao.listMarcas(), ['Fiat', 'Volkswagen']);
    expect(await db.marcasModelosDao.listModelosByMarca('Fiat'), [
      'Mobi',
      'Uno',
    ]);
    expect(await db.marcasModelosDao.listModelosByMarca('Volkswagen'), [
      'Gol',
      'Polo',
    ]);
  });

  test('seed é idempotente', () async {
    await db.marcasModelosDao.seedFromJson(_jsonBase);
    await db.marcasModelosDao.seedFromJson(_jsonBase);
    await db.marcasModelosDao.seedFromJson(_jsonBase);

    expect(await db.marcasModelosDao.listMarcas(), ['Fiat', 'Volkswagen']);
    expect(await db.marcasModelosDao.listModelosByMarca('Fiat'), [
      'Mobi',
      'Uno',
    ]);
  });

  test('seed subsequente adiciona novos itens sem perder os antigos', () async {
    await db.marcasModelosDao.seedFromJson(_jsonBase);
    await db.marcasModelosDao.seedFromJson(_jsonExpandido);

    expect(await db.marcasModelosDao.listMarcas(), [
      'Fiat',
      'Honda',
      'Volkswagen',
    ]);
    expect(await db.marcasModelosDao.listModelosByMarca('Fiat'), [
      'Argo',
      'Mobi',
      'Uno',
    ]);
    expect(await db.marcasModelosDao.listModelosByMarca('Honda'), ['Civic']);
  });

  test('listModelosByMarca de marca inexistente devolve lista vazia', () async {
    await db.marcasModelosDao.seedFromJson(_jsonBase);
    expect(
      await db.marcasModelosDao.listModelosByMarca('Inexistente'),
      isEmpty,
    );
  });

  test('watchMarcas emite inicial e ao inserir', () async {
    final events = <int>[];
    final sub = db.marcasModelosDao.watchMarcas().listen(
      (l) => events.add(l.length),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    await db.marcasModelosDao.seedFromJson(_jsonBase);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    await sub.cancel();
    expect(events.first, 0);
    expect(events.last, 2);
  });
}
