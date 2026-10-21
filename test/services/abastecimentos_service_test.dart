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
}
