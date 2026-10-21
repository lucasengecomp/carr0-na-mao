import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/services/abastecimentos_service.dart';
import 'package:carro_na_mao/services/lembretes_service.dart';
import 'package:carro_na_mao/services/notifications_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

class _FakePlugin implements NotificationsPluginInterface {
  final List<int> shownIds = [];
  final List<int> scheduledIds = [];
  final List<int> cancelledIds = [];

  @override
  Future<void> initialize(InitializationSettings settings) async {}

  @override
  Future<void> createAndroidChannel(AndroidNotificationChannel channel) async {}

  @override
  Future<bool?> requestAndroidPermission() async => true;

  @override
  Future<bool?> requestIosPermission({
    bool alert = true,
    bool badge = true,
    bool sound = true,
  }) async => null;

  @override
  Future<void> zonedSchedule({
    required int id,
    required String? title,
    required String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required AndroidScheduleMode androidScheduleMode,
  }) async {
    scheduledIds.add(id);
  }

  @override
  Future<void> show({
    required int id,
    required String? title,
    required String? body,
    required NotificationDetails details,
  }) async {
    shownIds.add(id);
  }

  @override
  Future<void> cancel(int id) async {
    cancelledIds.add(id);
  }
}

AbastecimentosCompanion _novoAbast({
  required String placa,
  required int km,
  DateTime? data,
}) => AbastecimentosCompanion.insert(
  veiculoPlaca: placa,
  data: data ?? DateTime.now(),
  km: km,
  tipoCombustivel: TipoCombustivelAbastecimento.gasolina,
  precoLitro: 6.0,
  valorTotal: 240.0,
  litros: 40.0,
);

void main() {
  late AppDatabase db;
  late AbastecimentosService service;
  late _FakePlugin fake;

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

    fake = _FakePlugin();
    final notifService = NotificationsService(plugin: fake);
    await notifService.init();
    final lembretesService = LembretesService(
      dao: db.lembretesDao,
      notifications: notifService,
    );
    service = AbastecimentosService(
      dao: db.abastecimentosDao,
      lembretesService: lembretesService,
      notifications: notifService,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'insertAbastecimento sem lembrete pendente de km — sem notificação',
    () async {
      await service.insertAbastecimento(
        _novoAbast(placa: 'ABC1D23', km: 20000),
      );
      expect(fake.shownIds, isEmpty);
    },
  );

  test(
    'insertAbastecimento com km atingindo alvo — dispara notificação imediata',
    () async {
      // Insere lembrete com kmAlvo = 20000
      final lembreteId = await db.lembretesDao.insertLembrete(
        LembretesCompanion.insert(
          veiculoPlaca: 'ABC1D23',
          tipo: 'avulso',
          descricao: 'Trocar óleo',
          kmAlvo: const Value(20000),
          status: StatusLembrete.pendente,
        ),
      );

      await service.insertAbastecimento(
        _novoAbast(placa: 'ABC1D23', km: 20000),
      );

      // Notificação imediata — id = lembreteId + 100000
      expect(fake.shownIds, contains(lembreteId + 100000));
    },
  );

  test(
    'insertAbastecimento com km abaixo do alvo — sem notificação de km',
    () async {
      await db.lembretesDao.insertLembrete(
        LembretesCompanion.insert(
          veiculoPlaca: 'ABC1D23',
          tipo: 'avulso',
          descricao: 'Trocar óleo',
          kmAlvo: const Value(30000),
          status: StatusLembrete.pendente,
        ),
      );

      await service.insertAbastecimento(
        _novoAbast(placa: 'ABC1D23', km: 20000),
      );
      expect(fake.shownIds, isEmpty);
    },
  );

  test(
    'insertAbastecimento com lembrete já concluído — sem notificação',
    () async {
      final lembreteId = await db.lembretesDao.insertLembrete(
        LembretesCompanion.insert(
          veiculoPlaca: 'ABC1D23',
          tipo: 'avulso',
          descricao: 'Trocar óleo',
          kmAlvo: const Value(20000),
          status: StatusLembrete.pendente,
        ),
      );
      await db.lembretesDao.marcarConcluido(lembreteId);

      await service.insertAbastecimento(
        _novoAbast(placa: 'ABC1D23', km: 20000),
      );
      expect(fake.shownIds, isEmpty);
    },
  );

  test(
    'deleteAbastecimento delega ao DAO e remove apenas o registro solicitado',
    () async {
      final id1 = await service.insertAbastecimento(
        _novoAbast(placa: 'ABC1D23', km: 10000),
      );
      final id2 = await service.insertAbastecimento(
        _novoAbast(placa: 'ABC1D23', km: 20000),
      );

      await service.deleteAbastecimento(id1);

      expect(await db.abastecimentosDao.byId(id1), isNull);
      expect(await db.abastecimentosDao.byId(id2), isNotNull);
    },
  );

  test('insertAbastecimento dispara notificação para múltiplos lembretes atingidos', () async {
    final id1 = await db.lembretesDao.insertLembrete(
      LembretesCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        tipo: 'avulso',
        descricao: 'Óleo',
        kmAlvo: const Value(15000),
        status: StatusLembrete.pendente,
      ),
    );
    final id2 = await db.lembretesDao.insertLembrete(
      LembretesCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        tipo: 'avulso',
        descricao: 'Filtro',
        kmAlvo: const Value(18000),
        status: StatusLembrete.pendente,
      ),
    );

    await service.insertAbastecimento(_novoAbast(placa: 'ABC1D23', km: 20000));
    expect(fake.shownIds, containsAll([id1 + 100000, id2 + 100000]));
  });

  // ── Delegação de leitura (RF-06, RF-08) ──────────────────────────────────

  test('byId retorna o abastecimento inserido', () async {
    final id = await service.insertAbastecimento(
      _novoAbast(placa: 'ABC1D23', km: 12000),
    );
    final found = await service.byId(id);
    expect(found, isNotNull);
    expect(found!.id, id);
    expect(found.km, 12000);
  });

  test('byId retorna null para id inexistente', () async {
    final found = await service.byId(999999);
    expect(found, isNull);
  });

  test('listByVeiculo retorna todos os abastecimentos do veículo', () async {
    await service.insertAbastecimento(_novoAbast(placa: 'ABC1D23', km: 10000));
    await service.insertAbastecimento(_novoAbast(placa: 'ABC1D23', km: 11000));
    final list = await service.listByVeiculo('ABC1D23');
    expect(list, hasLength(2));
  });

  test(
    'listByVeiculo retorna lista vazia quando veículo sem abastecimentos',
    () async {
      final list = await service.listByVeiculo('ABC1D23');
      expect(list, isEmpty);
    },
  );

  test('lastByVeiculo retorna o abastecimento com maior km', () async {
    await service.insertAbastecimento(_novoAbast(placa: 'ABC1D23', km: 10000));
    await service.insertAbastecimento(_novoAbast(placa: 'ABC1D23', km: 15000));
    await service.insertAbastecimento(_novoAbast(placa: 'ABC1D23', km: 12000));
    final last = await service.lastByVeiculo('ABC1D23');
    expect(last, isNotNull);
    expect(last!.km, 15000);
  });

  test('lastByVeiculo retorna null quando sem abastecimentos', () async {
    final last = await service.lastByVeiculo('ABC1D23');
    expect(last, isNull);
  });

  test('watchByVeiculo emite lista com os abastecimentos inseridos', () async {
    await service.insertAbastecimento(_novoAbast(placa: 'ABC1D23', km: 10000));
    await service.insertAbastecimento(_novoAbast(placa: 'ABC1D23', km: 11000));
    final list = await service.watchByVeiculo('ABC1D23').first;
    expect(list, hasLength(2));
  });

  test(
    'watchFiltered retorna stream vazio quando set de tipos é vazio',
    () async {
      await service.insertAbastecimento(
        _novoAbast(placa: 'ABC1D23', km: 10000),
      );
      final list = await service
          .watchFiltered(
            placa: 'ABC1D23',
            tiposCombustivel: const <TipoCombustivelAbastecimento>{},
          )
          .first;
      expect(list, isEmpty);
    },
  );

  test('watchFiltered filtra por tipo de combustível', () async {
    await service.insertAbastecimento(_novoAbast(placa: 'ABC1D23', km: 10000));
    final list = await service
        .watchFiltered(
          placa: 'ABC1D23',
          tiposCombustivel: {TipoCombustivelAbastecimento.gasolina},
        )
        .first;
    expect(list, hasLength(1));
    expect(list.first.tipoCombustivel, TipoCombustivelAbastecimento.gasolina);
  });

  test('watchFiltered sem filtros retorna todos', () async {
    await service.insertAbastecimento(_novoAbast(placa: 'ABC1D23', km: 10000));
    await service.insertAbastecimento(_novoAbast(placa: 'ABC1D23', km: 11000));
    final list = await service.watchFiltered(placa: 'ABC1D23').first;
    expect(list, hasLength(2));
  });

  test('updateAbastecimento persiste alteração no banco', () async {
    final id = await service.insertAbastecimento(
      _novoAbast(placa: 'ABC1D23', km: 10000),
    );
    final original = (await db.abastecimentosDao.byId(id))!;
    final atualizado = original.copyWith(km: 11111);
    final ok = await service.updateAbastecimento(atualizado);
    expect(ok, isTrue);
    final after = await db.abastecimentosDao.byId(id);
    expect(after!.km, 11111);
  });

  test('deleteById remove apenas o abastecimento solicitado', () async {
    final id1 = await service.insertAbastecimento(
      _novoAbast(placa: 'ABC1D23', km: 10000),
    );
    final id2 = await service.insertAbastecimento(
      _novoAbast(placa: 'ABC1D23', km: 11000),
    );
    await service.deleteById(id1);
    expect(await db.abastecimentosDao.byId(id1), isNull);
    expect(await db.abastecimentosDao.byId(id2), isNotNull);
  });
}
