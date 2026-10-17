import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/data/providers.dart';
import 'package:carro_na_mao/presentation/screens/manutencoes/manutencoes_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _seedVeiculo(AppDatabase db, {String placa = 'TST0001'}) {
  return db.veiculosDao.insertVeiculo(
    VeiculosCompanion.insert(
      placa: placa,
      marca: 'Toyota',
      modelo: 'Corolla',
      ano: 2022,
      tipo: TipoVeiculo.carro,
      combustivel: TipoCombustivelVeiculo.flex,
      kmInicial: 5000,
    ),
  );
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await _seedVeiculo(db);
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  // -----------------------------------------------------------------------
  // tipoManutencaoPadraoProvider
  // -----------------------------------------------------------------------
  group('tipoManutencaoPadraoProvider', () {
    test(
      'retorna padrão seedado para oleoMotor (km=10000, meses=12)',
      () async {
        final result = await container.read(
          tipoManutencaoPadraoProvider(TipoManutencao.oleoMotor).future,
        );

        expect(result, isNotNull);
        expect(result!.intervaloKm, 10000);
        expect(result.intervaloMeses, 12);
      },
    );

    test(
      'retorna padrão seedado para correiaDentada (km=60000, meses=60)',
      () async {
        final result = await container.read(
          tipoManutencaoPadraoProvider(TipoManutencao.correiaDentada).future,
        );

        expect(result, isNotNull);
        expect(result!.intervaloKm, 60000);
        expect(result.intervaloMeses, 60);
      },
    );

    test('retorna padrão para fluidoFreio (km=null, meses=24)', () async {
      final result = await container.read(
        tipoManutencaoPadraoProvider(TipoManutencao.fluidoFreio).future,
      );

      expect(result, isNotNull);
      expect(result!.intervaloKm, isNull);
      expect(result.intervaloMeses, 24);
    });

    test('retorna null para tipo "outros" (sem padrão seedado)', () async {
      final result = await container.read(
        tipoManutencaoPadraoProvider(TipoManutencao.outros).future,
      );

      expect(result, isNull);
    });
  });

  // -----------------------------------------------------------------------
  // manutencoesDoVeiculoProvider
  // Nota: StreamProvider<List<Manutencao>>.future não resolve bem em testes
  // sem uma UI que segure a assinatura. Testamos o comportamento reativo
  // via DAO diretamente — é o contrato garantido pela provider.
  // -----------------------------------------------------------------------
  group('manutencoesDoVeiculoProvider', () {
    test(
      'watchByVeiculo emite lista vazia quando não há manutenções',
      () async {
        final first = await db.manutencoesDao.watchByVeiculo('TST0001').first;
        expect(first, isEmpty);
      },
    );

    test('watchByVeiculo reage a insert emitindo lista atualizada', () async {
      final events = <int>[];
      final sub = db.manutencoesDao
          .watchByVeiculo('TST0001')
          .listen((list) => events.add(list.length));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      await db.manutencoesDao.insertManutencao(
        ManutencoesCompanion.insert(
          veiculoPlaca: 'TST0001',
          tipo: TipoManutencao.oleoMotor,
          data: DateTime(2026, 1, 15),
          km: 15000,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      await db.manutencoesDao.insertManutencao(
        ManutencoesCompanion.insert(
          veiculoPlaca: 'TST0001',
          tipo: TipoManutencao.velas,
          data: DateTime(2026, 6, 10),
          km: 20000,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      await sub.cancel();
      expect(events, [0, 1, 2]);
    });

    test('watchByVeiculo não reage a inserts de outra placa', () async {
      await _seedVeiculo(db, placa: 'OUT0002');

      final events = <int>[];
      final sub = db.manutencoesDao
          .watchByVeiculo('TST0001')
          .listen((list) => events.add(list.length));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      await db.manutencoesDao.insertManutencao(
        ManutencoesCompanion.insert(
          veiculoPlaca: 'OUT0002',
          tipo: TipoManutencao.pneus,
          data: DateTime(2026, 3, 1),
          km: 8000,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      await sub.cancel();
      // Conteúdo filtrado para TST0001 permanece vazio.
      expect(events.last, 0);
    });

    test('lista retornada ordenada por data decrescente', () async {
      await db.manutencoesDao.insertManutencao(
        ManutencoesCompanion.insert(
          veiculoPlaca: 'TST0001',
          tipo: TipoManutencao.filtroAr,
          data: DateTime(2026, 1, 1),
          km: 10000,
        ),
      );
      await db.manutencoesDao.insertManutencao(
        ManutencoesCompanion.insert(
          veiculoPlaca: 'TST0001',
          tipo: TipoManutencao.oleoMotor,
          data: DateTime(2026, 6, 1),
          km: 20000,
        ),
      );

      final result = await db.manutencoesDao.watchByVeiculo('TST0001').first;

      expect(result, hasLength(2));
      expect(result.first.data, DateTime(2026, 6, 1));
      expect(result.last.data, DateTime(2026, 1, 1));
    });

    test(
      'tipoManutencaoPadraoProvider provider retorna padrão via container',
      () async {
        final result = await container.read(
          tipoManutencaoPadraoProvider(TipoManutencao.oleoMotor).future,
        );
        expect(result, isNotNull);
        expect(result!.intervaloKm, 10000);
      },
    );
  });

  // -----------------------------------------------------------------------
  // TiposManutencaoPadraoDao.listAll (via provider indireto)
  // -----------------------------------------------------------------------
  group('TiposManutencaoPadraoDao.listAll', () {
    test('seed completo tem pelo menos 11 tipos', () async {
      final todos = await db.tiposManutencaoPadraoDao.listAll();
      expect(todos.length, greaterThanOrEqualTo(11));
    });
  });

  // -----------------------------------------------------------------------
  // ManutencoesDao — inserção, byId e nomeLivre
  // -----------------------------------------------------------------------
  group('ManutencoesDao insert / byId', () {
    test('salva e recupera manutenção com nomeLivre', () async {
      final id = await db.manutencoesDao.insertManutencao(
        ManutencoesCompanion.insert(
          veiculoPlaca: 'TST0001',
          tipo: TipoManutencao.outros,
          nomeLivre: const Value('Limpeza de bico'),
          data: DateTime(2026, 4, 20),
          km: 18000,
          valor: const Value(320.50),
          oficina: const Value('Auto Center'),
        ),
      );

      final m = await db.manutencoesDao.byId(id);
      expect(m, isNotNull);
      expect(m!.nomeLivre, 'Limpeza de bico');
      expect(m.valor, closeTo(320.50, 1e-6));
      expect(m.oficina, 'Auto Center');
      expect(m.tipo, TipoManutencao.outros);
    });

    test(
      'salva manutenção sem campos opcionais (valor e oficina nulos)',
      () async {
        final id = await db.manutencoesDao.insertManutencao(
          ManutencoesCompanion.insert(
            veiculoPlaca: 'TST0001',
            tipo: TipoManutencao.rodizioPneus,
            data: DateTime(2026, 5, 5),
            km: 22000,
          ),
        );

        final m = await db.manutencoesDao.byId(id);
        expect(m, isNotNull);
        expect(m!.valor, isNull);
        expect(m.oficina, isNull);
        expect(m.nomeLivre, isNull);
      },
    );
  });
}
