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

  // ---------------------------------------------------------------------------
  // watchFiltered – sem filtros (tudo)
  // ---------------------------------------------------------------------------
  group('watchFiltered – sem filtros', () {
    test(
      'retorna todos os abastecimentos do veículo em ordem data desc',
      () async {
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(data: DateTime(2026, 1, 10), km: 100),
        );
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(data: DateTime(2026, 3, 5), km: 300),
        );
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(data: DateTime(2026, 2, 1), km: 200),
        );

        final lista = await db.abastecimentosDao
            .watchFiltered(placa: 'ABC1D23')
            .first;

        expect(lista.map((a) => a.data), [
          DateTime(2026, 3, 5),
          DateTime(2026, 2, 1),
          DateTime(2026, 1, 10),
        ]);
      },
    );

    test('banco vazio retorna lista vazia', () async {
      final lista = await db.abastecimentosDao
          .watchFiltered(placa: 'ABC1D23')
          .first;
      expect(lista, isEmpty);
    });

    test('não vaza abastecimentos de outro veículo', () async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo(placa: 'XYZ9A99'));

      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: DateTime(2026, 1, 1), km: 100),
      );
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(placa: 'XYZ9A99', data: DateTime(2026, 1, 2), km: 200),
      );

      final lista = await db.abastecimentosDao
          .watchFiltered(placa: 'ABC1D23')
          .first;
      expect(lista, hasLength(1));
      expect(lista.single.veiculoPlaca, 'ABC1D23');
    });
  });

  // ---------------------------------------------------------------------------
  // watchFiltered – filtro de período (desde)
  // ---------------------------------------------------------------------------
  group('watchFiltered – filtro de período', () {
    test(
      'retorna apenas registros a partir da data de corte (inclusive)',
      () async {
        final corte = DateTime(2026, 2, 1);
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(data: DateTime(2026, 1, 31), km: 100),
        );
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(data: corte, km: 200),
        );
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(data: DateTime(2026, 3, 1), km: 300),
        );

        final lista = await db.abastecimentosDao
            .watchFiltered(placa: 'ABC1D23', desde: corte)
            .first;

        expect(lista, hasLength(2));
        expect(lista.every((a) => !a.data.isBefore(corte)), isTrue);
      },
    );

    test('date de corte no futuro retorna lista vazia', () async {
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: DateTime(2026, 1, 10), km: 100),
      );

      final lista = await db.abastecimentosDao
          .watchFiltered(placa: 'ABC1D23', desde: DateTime(2030, 1, 1))
          .first;

      expect(lista, isEmpty);
    });

    test('quando desde=null, nenhum filtro de data é aplicado', () async {
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: DateTime(2020, 1, 1), km: 100),
      );
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: DateTime(2024, 6, 15), km: 200),
      );

      final lista = await db.abastecimentosDao
          .watchFiltered(placa: 'ABC1D23')
          .first;
      expect(lista, hasLength(2));
    });
  });

  // ---------------------------------------------------------------------------
  // watchFiltered – filtro de tipo de combustível (multi-select, issue #77)
  // ---------------------------------------------------------------------------
  group('watchFiltered – filtro de combustível', () {
    test('filtra corretamente por 1 tipo (set com 1 elemento)', () async {
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(2026, 1, 1),
          km: 100,
          combustivel: TipoCombustivelAbastecimento.gasolina,
        ),
      );
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(2026, 1, 2),
          km: 200,
          combustivel: TipoCombustivelAbastecimento.alcool,
        ),
      );
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(2026, 1, 3),
          km: 300,
          combustivel: TipoCombustivelAbastecimento.gasolina,
        ),
      );

      final lista = await db.abastecimentosDao
          .watchFiltered(
            placa: 'ABC1D23',
            tiposCombustivel: {TipoCombustivelAbastecimento.gasolina},
          )
          .first;

      expect(lista, hasLength(2));
      expect(
        lista.every(
          (a) => a.tipoCombustivel == TipoCombustivelAbastecimento.gasolina,
        ),
        isTrue,
      );
    });

    test(
      'filtra corretamente por 2 tipos (set com 2 elementos) — IN (?)',
      () async {
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(2026, 1, 1),
            km: 100,
            combustivel: TipoCombustivelAbastecimento.gasolina,
          ),
        );
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(2026, 1, 2),
            km: 200,
            combustivel: TipoCombustivelAbastecimento.alcool,
          ),
        );
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(2026, 1, 3),
            km: 300,
            combustivel: TipoCombustivelAbastecimento.diesel,
          ),
        );

        final lista = await db.abastecimentosDao
            .watchFiltered(
              placa: 'ABC1D23',
              tiposCombustivel: {
                TipoCombustivelAbastecimento.gasolina,
                TipoCombustivelAbastecimento.alcool,
              },
            )
            .first;

        expect(lista, hasLength(2));
        expect(
          lista.every(
            (a) =>
                a.tipoCombustivel == TipoCombustivelAbastecimento.gasolina ||
                a.tipoCombustivel == TipoCombustivelAbastecimento.alcool,
          ),
          isTrue,
        );
      },
    );

    test('set vazio retorna lista vazia imediatamente', () async {
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(2026, 1, 1),
          km: 100,
          combustivel: TipoCombustivelAbastecimento.gasolina,
        ),
      );

      final lista = await db.abastecimentosDao
          .watchFiltered(placa: 'ABC1D23', tiposCombustivel: {})
          .first;

      expect(lista, isEmpty);
    });

    test('combustível sem registros retorna lista vazia', () async {
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(2026, 1, 1),
          km: 100,
          combustivel: TipoCombustivelAbastecimento.gasolina,
        ),
      );

      final lista = await db.abastecimentosDao
          .watchFiltered(
            placa: 'ABC1D23',
            tiposCombustivel: {TipoCombustivelAbastecimento.diesel},
          )
          .first;

      expect(lista, isEmpty);
    });

    test(
      'quando tiposCombustivel=null, todos os combustíveis aparecem',
      () async {
        for (final tipo in TipoCombustivelAbastecimento.values) {
          await db.abastecimentosDao.insertAbastecimento(
            _novoAbast(data: DateTime(2026, 1, 1), km: 100, combustivel: tipo),
          );
        }

        final lista = await db.abastecimentosDao
            .watchFiltered(placa: 'ABC1D23')
            .first;

        expect(lista, hasLength(TipoCombustivelAbastecimento.values.length));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // watchFiltered – combinação de filtros
  // ---------------------------------------------------------------------------
  group('watchFiltered – filtros combinados', () {
    test('período + 1 combustível filtram corretamente', () async {
      final corte = DateTime(2026, 2, 1);

      // Dentro do período, gasolina → DEVE aparecer
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(2026, 3, 1),
          km: 300,
          combustivel: TipoCombustivelAbastecimento.gasolina,
        ),
      );
      // Dentro do período, álcool → NÃO deve aparecer
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(2026, 2, 15),
          km: 200,
          combustivel: TipoCombustivelAbastecimento.alcool,
        ),
      );
      // Fora do período, gasolina → NÃO deve aparecer
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(2026, 1, 31),
          km: 100,
          combustivel: TipoCombustivelAbastecimento.gasolina,
        ),
      );

      final lista = await db.abastecimentosDao
          .watchFiltered(
            placa: 'ABC1D23',
            desde: corte,
            tiposCombustivel: {TipoCombustivelAbastecimento.gasolina},
          )
          .first;

      expect(lista, hasLength(1));
      expect(lista.single.data, DateTime(2026, 3, 1));
      expect(
        lista.single.tipoCombustivel,
        TipoCombustivelAbastecimento.gasolina,
      );
    });

    test(
      'período + 2 combustíveis (flex: gasolina+álcool) retorna união',
      () async {
        final corte = DateTime(2026, 2, 1);

        // Dentro do período, gasolina → DEVE aparecer
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(2026, 3, 1),
            km: 300,
            combustivel: TipoCombustivelAbastecimento.gasolina,
          ),
        );
        // Dentro do período, álcool → DEVE aparecer (multi-select)
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(2026, 2, 15),
            km: 200,
            combustivel: TipoCombustivelAbastecimento.alcool,
          ),
        );
        // Dentro do período, diesel → NÃO deve aparecer
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(2026, 2, 10),
            km: 150,
            combustivel: TipoCombustivelAbastecimento.diesel,
          ),
        );
        // Fora do período, gasolina → NÃO deve aparecer
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(2026, 1, 31),
            km: 100,
            combustivel: TipoCombustivelAbastecimento.gasolina,
          ),
        );

        final lista = await db.abastecimentosDao
            .watchFiltered(
              placa: 'ABC1D23',
              desde: corte,
              tiposCombustivel: {
                TipoCombustivelAbastecimento.gasolina,
                TipoCombustivelAbastecimento.alcool,
              },
            )
            .first;

        expect(lista, hasLength(2));
        expect(lista.map((a) => a.tipoCombustivel).toSet(), {
          TipoCombustivelAbastecimento.gasolina,
          TipoCombustivelAbastecimento.alcool,
        });
      },
    );
  });

  // ---------------------------------------------------------------------------
  // watchFiltered – reatividade (stream)
  // ---------------------------------------------------------------------------
  group('watchFiltered – reatividade', () {
    test('emite novo evento quando registro compatível é inserido', () async {
      final events = <int>[];
      final sub = db.abastecimentosDao
          .watchFiltered(placa: 'ABC1D23')
          .listen((list) => events.add(list.length));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(data: DateTime(2026, 1, 1), km: 100),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await sub.cancel();
      expect(events, [0, 1]);
    });

    test('não emite evento para veículo diferente', () async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo(placa: 'XYZ9A99'));

      final events = <int>[];
      final sub = db.abastecimentosDao
          .watchFiltered(placa: 'ABC1D23')
          .listen((list) => events.add(list.length));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(placa: 'XYZ9A99', data: DateTime(2026, 1, 1), km: 100),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await sub.cancel();
      // Drift pode emitir para qualquer mudança na tabela, mas o resultado
      // deve permanecer 0 (sem registros para ABC1D23)
      expect(events.last, 0);
    });
  });
}
