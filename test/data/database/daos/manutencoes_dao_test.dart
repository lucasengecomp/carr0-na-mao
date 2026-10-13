import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

ManutencoesCompanion _novaManut({
  String placa = 'ABC1D23',
  TipoManutencao tipo = TipoManutencao.oleoMotor,
  String? nomeLivre,
  required DateTime data,
  required int km,
  double? valor,
  String? oficina,
}) => ManutencoesCompanion.insert(
  veiculoPlaca: placa,
  tipo: tipo,
  nomeLivre: Value(nomeLivre),
  data: data,
  km: km,
  valor: Value(valor),
  oficina: Value(oficina),
);

void main() {
  late AppDatabase db;

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
  });

  tearDown(() async {
    await db.close();
  });

  group('ManutencoesDao', () {
    test('insert / byId / listByVeiculo em ordem', () async {
      final id1 = await db.manutencoesDao.insertManutencao(
        _novaManut(data: DateTime(2026, 1, 10), km: 10200, valor: 250),
      );
      await db.manutencoesDao.insertManutencao(
        _novaManut(
          tipo: TipoManutencao.pneus,
          data: DateTime(2026, 3, 1),
          km: 10800,
        ),
      );

      final primeira = await db.manutencoesDao.byId(id1);
      expect(primeira!.valor, 250);

      final todas = await db.manutencoesDao.listByVeiculo('ABC1D23');
      expect(todas, hasLength(2));
      expect(todas.first.data, DateTime(2026, 3, 1));
    });

    test('lastByTipo isola por tipo', () async {
      await db.manutencoesDao.insertManutencao(
        _novaManut(data: DateTime(2026, 1, 10), km: 10200),
      );
      await db.manutencoesDao.insertManutencao(
        _novaManut(data: DateTime(2026, 6, 10), km: 11200),
      );
      await db.manutencoesDao.insertManutencao(
        _novaManut(
          tipo: TipoManutencao.pneus,
          data: DateTime(2026, 8, 1),
          km: 12000,
        ),
      );

      final oleo = await db.manutencoesDao.lastByTipo(
        'ABC1D23',
        TipoManutencao.oleoMotor,
      );
      expect(oleo!.km, 11200);

      final velas = await db.manutencoesDao.lastByTipo(
        'ABC1D23',
        TipoManutencao.velas,
      );
      expect(velas, isNull);
    });

    test('watchByVeiculo emite após insert', () async {
      final events = <int>[];
      final sub = db.manutencoesDao
          .watchByVeiculo('ABC1D23')
          .listen((list) => events.add(list.length));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await db.manutencoesDao.insertManutencao(
        _novaManut(data: DateTime(2026, 1, 10), km: 10200),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await sub.cancel();
      expect(events, [0, 1]);
    });
  });

  group('TiposManutencaoPadraoDao', () {
    test('byTipo retorna o intervalo seedado', () async {
      final oleo = await db.tiposManutencaoPadraoDao.byTipo(
        TipoManutencao.oleoMotor,
      );
      expect(oleo!.intervaloKm, 10000);
      expect(oleo.intervaloMeses, 12);

      final fluido = await db.tiposManutencaoPadraoDao.byTipo(
        TipoManutencao.fluidoFreio,
      );
      expect(fluido!.intervaloKm, isNull);
      expect(fluido.intervaloMeses, 24);
    });

    test('byTipo em tipo sem padrão (outros) devolve null', () async {
      final sem = await db.tiposManutencaoPadraoDao.byTipo(
        TipoManutencao.outros,
      );
      expect(sem, isNull);
    });

    test('listAll devolve o seed completo', () async {
      final todos = await db.tiposManutencaoPadraoDao.listAll();
      expect(todos.length, greaterThanOrEqualTo(11));
    });
  });
}
