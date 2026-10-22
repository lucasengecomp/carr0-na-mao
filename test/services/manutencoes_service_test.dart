import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/services/manutencoes_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

ManutencoesCompanion _novaManut({
  String placa = 'ABC1D23',
  TipoManutencao tipo = TipoManutencao.oleoMotor,
  required DateTime data,
  required int km,
  double? valor,
}) => ManutencoesCompanion.insert(
  veiculoPlaca: placa,
  tipo: tipo,
  data: data,
  km: km,
  valor: Value(valor),
);

void main() {
  late AppDatabase db;
  late ManutencoesService service;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.veiculosDao.insertVeiculo(
      VeiculosCompanion.insert(
        placa: 'ABC1D23',
        marca: 'Fiat',
        modelo: 'Uno',
        ano: 2020,
        tipo: TipoVeiculo.carro,
        combustivel: TipoCombustivelVeiculo.flex,
        kmInicial: 10000,
      ),
    );
    service = ManutencoesService(dao: db.manutencoesDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('excluir manutenção', () {
    test(
      'deleteManutencao delega ao DAO e remove apenas o registro solicitado',
      () async {
        final id1 = await service.insertManutencao(
          _novaManut(data: DateTime(2026, 1, 10), km: 10200),
        );
        final id2 = await service.insertManutencao(
          _novaManut(
            tipo: TipoManutencao.pneus,
            data: DateTime(2026, 3, 1),
            km: 10800,
          ),
        );

        await service.deleteManutencao(id1);

        expect(await db.manutencoesDao.byId(id1), isNull);
        expect(await db.manutencoesDao.byId(id2), isNotNull);
      },
    );

    test('deleteManutencao de id inexistente não lança exceção', () async {
      await expectLater(service.deleteManutencao(9999999), completes);
    });
  });

  group('leitura', () {
    test('byId retorna a manutenção inserida', () async {
      final id = await service.insertManutencao(
        _novaManut(data: DateTime(2026, 1, 10), km: 10200, valor: 350),
      );
      final found = await service.byId(id);
      expect(found, isNotNull);
      expect(found!.id, id);
      expect(found.km, 10200);
      expect(found.valor, 350);
    });

    test('byId retorna null para id inexistente', () async {
      final found = await service.byId(999999);
      expect(found, isNull);
    });

    test('listByVeiculo retorna todas as manutenções do veículo', () async {
      await service.insertManutencao(
        _novaManut(data: DateTime(2026, 1, 10), km: 10200),
      );
      await service.insertManutencao(
        _novaManut(
          tipo: TipoManutencao.pneus,
          data: DateTime(2026, 3, 1),
          km: 10800,
        ),
      );
      final list = await service.listByVeiculo('ABC1D23');
      expect(list, hasLength(2));
    });

    test('watchByVeiculo emite lista atualizada após insert', () async {
      await service.insertManutencao(
        _novaManut(data: DateTime(2026, 1, 10), km: 10200),
      );
      final list = await service.watchByVeiculo('ABC1D23').first;
      expect(list, hasLength(1));
    });
  });
}
