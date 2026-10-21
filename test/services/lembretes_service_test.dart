import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/services/lembretes_service.dart';
import 'package:carro_na_mao/services/notifications_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

/// Fake simples para isolar testes do LembretesService.
class _FakePlugin implements NotificationsPluginInterface {
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
  }) async {}

  @override
  Future<void> cancel(int id) async {
    cancelledIds.add(id);
  }
}

void main() {
  late AppDatabase db;
  late LembretesService service;
  late _FakePlugin fake;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Insere veículo de teste
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
    service = LembretesService(
      dao: db.lembretesDao,
      notifications: notifService,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('insertLembrete persiste e agenda notificação', () async {
    final id = await service.insertLembrete(
      LembretesCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        tipo: 'avulso',
        descricao: 'Trocar palhetas',
        dataAlvo: Value(DateTime.now().add(const Duration(days: 30))),
        status: StatusLembrete.pendente,
      ),
    );

    expect(await db.lembretesDao.byId(id), isNotNull);
    // Notificação deve ter sido agendada
    expect(fake.scheduledIds, contains(id));
  });

  test('updateLembrete re-agenda notificação', () async {
    final id = await service.insertLembrete(
      LembretesCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        tipo: 'avulso',
        descricao: 'Revisão',
        dataAlvo: Value(DateTime.now().add(const Duration(days: 30))),
        status: StatusLembrete.pendente,
      ),
    );

    final lembrete = (await db.lembretesDao.byId(id))!;
    final atualizado = lembrete.copyWith(
      descricao: 'Revisão completa',
      dataAlvo: Value(DateTime.now().add(const Duration(days: 60))),
    );
    await service.updateLembrete(atualizado);

    // scheduledIds deve ter o id duas vezes (insert + update)
    expect(
      fake.scheduledIds.where((i) => i == id).length,
      greaterThanOrEqualTo(2),
    );
  });

  test('marcarConcluido cancela notificação', () async {
    final id = await service.insertLembrete(
      LembretesCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        tipo: 'avulso',
        descricao: 'IPVA',
        dataAlvo: Value(DateTime.now().add(const Duration(days: 30))),
        status: StatusLembrete.pendente,
      ),
    );

    await service.marcarConcluido(id);

    expect(fake.cancelledIds, contains(id));
    final l = await db.lembretesDao.byId(id);
    expect(l!.status, StatusLembrete.concluido);
  });

  test('deleteById cancela notificação e remove do banco', () async {
    final id = await service.insertLembrete(
      LembretesCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        tipo: 'avulso',
        descricao: 'Licenciamento',
        dataAlvo: Value(DateTime.now().add(const Duration(days: 30))),
        status: StatusLembrete.pendente,
      ),
    );

    await service.deleteById(id);

    expect(fake.cancelledIds, contains(id));
    expect(await db.lembretesDao.byId(id), isNull);
  });

  test('cancelarNotificacoesPorVeiculo cancela todos os pendentes', () async {
    final id1 = await service.insertLembrete(
      LembretesCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        tipo: 'avulso',
        descricao: 'Palhetas',
        dataAlvo: Value(DateTime.now().add(const Duration(days: 30))),
        status: StatusLembrete.pendente,
      ),
    );
    final id2 = await db.lembretesDao.insertLembrete(
      LembretesCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        tipo: 'km',
        descricao: 'Óleo',
        kmAlvo: const Value(50000),
        status: StatusLembrete.pendente,
      ),
    );

    await service.cancelarNotificacoesPorVeiculo('ABC1D23');

    expect(fake.cancelledIds, containsAll([id1, id2]));
  });

  test('adiar re-agenda notificação com nova data', () async {
    final id = await service.insertLembrete(
      LembretesCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        tipo: 'avulso',
        descricao: 'Licenciamento',
        dataAlvo: Value(DateTime.now().add(const Duration(days: 30))),
        status: StatusLembrete.pendente,
      ),
    );
    fake.scheduledIds.clear();

    final novaData = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day + 90,
    );
    await service.adiar(id, novaData: novaData);

    // Deve ter re-agendado com o mesmo id
    expect(fake.scheduledIds, contains(id));
    final l = await db.lembretesDao.byId(id);
    // Drift/SQLite trunca microssegundos; compara apenas data
    expect(l!.dataAlvo?.year, novaData.year);
    expect(l.dataAlvo?.month, novaData.month);
    expect(l.dataAlvo?.day, novaData.day);
    // RF-87: adiar() deve persistir StatusLembrete.adiado, não pendente.
    expect(l.status, StatusLembrete.adiado);
  });

  test('adiar com novoKm re-agenda pelo id após atualização', () async {
    final id = await service.insertLembrete(
      LembretesCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        tipo: 'avulso',
        descricao: 'Revisão',
        kmAlvo: const Value(50000),
        status: StatusLembrete.pendente,
      ),
    );

    await service.adiar(id, novoKm: 70000);

    final l = await db.lembretesDao.byId(id);
    expect(l!.kmAlvo, 70000);
    // RF-87: adiar() deve persistir StatusLembrete.adiado, não pendente.
    expect(l.status, StatusLembrete.adiado);
  });

  test('upsertByManutencao persiste lembrete e agenda notificação', () async {
    await db.manutencoesDao.insertManutencao(
      ManutencoesCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        tipo: TipoManutencao.oleoMotor,
        data: DateTime(2026, 1, 10),
        km: 10200,
      ),
    );
    final manut = (await db.manutencoesDao.listByVeiculo('ABC1D23')).first;

    await service.upsertByManutencao(
      placa: 'ABC1D23',
      manutencaoId: manut.id,
      tipo: 'oleoMotor',
      descricao: 'Trocar óleo',
      dataAlvo: DateTime.now().add(const Duration(days: 60)),
      kmAlvo: 20200,
    );

    final pendentes = await db.lembretesDao.listPendentesByVeiculo('ABC1D23');
    expect(pendentes, hasLength(1));
    expect(pendentes.single.tipo, 'oleoMotor');
    // Notificação deve ter sido agendada (dataAlvo no futuro)
    expect(fake.scheduledIds, contains(pendentes.single.id));
  });

  test('upsertByManutencao substitui lembrete anterior e re-agenda', () async {
    await db.manutencoesDao.insertManutencao(
      ManutencoesCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        tipo: TipoManutencao.oleoMotor,
        data: DateTime(2026, 1, 10),
        km: 10200,
      ),
    );
    final manut1 = (await db.manutencoesDao.listByVeiculo('ABC1D23')).first;

    await service.upsertByManutencao(
      placa: 'ABC1D23',
      manutencaoId: manut1.id,
      tipo: 'oleoMotor',
      descricao: 'Trocar óleo',
      dataAlvo: DateTime.now().add(const Duration(days: 60)),
      kmAlvo: 20200,
    );

    // Segunda chamada substitui o lembrete anterior
    await db.manutencoesDao.insertManutencao(
      ManutencoesCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        tipo: TipoManutencao.oleoMotor,
        data: DateTime(2026, 7, 10),
        km: 15500,
      ),
    );
    final manut2 = (await db.manutencoesDao.listByVeiculo('ABC1D23')).first;

    await service.upsertByManutencao(
      placa: 'ABC1D23',
      manutencaoId: manut2.id,
      tipo: 'oleoMotor',
      descricao: 'Trocar óleo atualizado',
      dataAlvo: DateTime.now().add(const Duration(days: 90)),
      kmAlvo: 25500,
    );

    final pendentes = await db.lembretesDao.listPendentesByVeiculo('ABC1D23');
    expect(pendentes, hasLength(1));
    expect(pendentes.single.kmAlvo, 25500);
  });

  // ── Delegação de leitura ──────────────────────────────────────────────────

  test('byId retorna o lembrete inserido pelo service', () async {
    final id = await service.insertLembrete(
      LembretesCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        tipo: 'avulso',
        descricao: 'Palhetas',
        dataAlvo: Value(DateTime.now().add(const Duration(days: 30))),
        status: StatusLembrete.pendente,
      ),
    );
    final found = await service.byId(id);
    expect(found, isNotNull);
    expect(found!.id, id);
  });

  test('byId retorna null para id inexistente', () async {
    final found = await service.byId(999999);
    expect(found, isNull);
  });

  test('listByVeiculo retorna todos os lembretes do veículo', () async {
    await service.insertLembrete(
      LembretesCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        tipo: 'avulso',
        descricao: 'A',
        dataAlvo: Value(DateTime.now().add(const Duration(days: 10))),
        status: StatusLembrete.pendente,
      ),
    );
    await service.insertLembrete(
      LembretesCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        tipo: 'avulso',
        descricao: 'B',
        dataAlvo: Value(DateTime.now().add(const Duration(days: 20))),
        status: StatusLembrete.pendente,
      ),
    );
    final list = await service.listByVeiculo('ABC1D23');
    expect(list, hasLength(2));
  });

  test('listByVeiculo retorna lista vazia quando sem lembretes', () async {
    final list = await service.listByVeiculo('ABC1D23');
    expect(list, isEmpty);
  });

  test('listPendentesByVeiculo filtra apenas pendentes', () async {
    final id = await service.insertLembrete(
      LembretesCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        tipo: 'avulso',
        descricao: 'Pendente',
        dataAlvo: Value(DateTime.now().add(const Duration(days: 10))),
        status: StatusLembrete.pendente,
      ),
    );
    // Marca como concluído
    await service.marcarConcluido(id);

    // Insere outro lembrete pendente
    await service.insertLembrete(
      LembretesCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        tipo: 'avulso',
        descricao: 'Outro pendente',
        dataAlvo: Value(DateTime.now().add(const Duration(days: 20))),
        status: StatusLembrete.pendente,
      ),
    );

    final pendentes = await service.listPendentesByVeiculo('ABC1D23');
    expect(pendentes, hasLength(1));
    expect(pendentes.first.descricao, 'Outro pendente');
  });

  test('watchPendentesByVeiculo emite apenas lembretes pendentes', () async {
    await service.insertLembrete(
      LembretesCompanion.insert(
        veiculoPlaca: 'ABC1D23',
        tipo: 'avulso',
        descricao: 'Pendente stream',
        dataAlvo: Value(DateTime.now().add(const Duration(days: 10))),
        status: StatusLembrete.pendente,
      ),
    );
    final list = await service.watchPendentesByVeiculo('ABC1D23').first;
    expect(list, hasLength(1));
    expect(list.first.descricao, 'Pendente stream');
  });

  test(
    'findVencidosPorKm retorna lembretes cujo kmAlvo foi atingido',
    () async {
      await service.insertLembrete(
        LembretesCompanion.insert(
          veiculoPlaca: 'ABC1D23',
          tipo: 'avulso',
          descricao: 'Óleo',
          kmAlvo: const Value(20000),
          status: StatusLembrete.pendente,
        ),
      );
      // Km alvo ainda não atingido
      await service.insertLembrete(
        LembretesCompanion.insert(
          veiculoPlaca: 'ABC1D23',
          tipo: 'avulso',
          descricao: 'Pneu',
          kmAlvo: const Value(50000),
          status: StatusLembrete.pendente,
        ),
      );
      final vencidos = await service.findVencidosPorKm('ABC1D23', 25000);
      expect(vencidos, hasLength(1));
      expect(vencidos.first.descricao, 'Óleo');
    },
  );
}
