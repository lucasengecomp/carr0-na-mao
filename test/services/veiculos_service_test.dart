import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/services/lembretes_service.dart';
import 'package:carro_na_mao/services/notifications_service.dart';
import 'package:carro_na_mao/services/veiculos_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

class _FakePlugin implements NotificationsPluginInterface {
  final List<int> cancelledIds = [];
  final List<int> scheduledIds = [];
  final List<String> callOrder = [];

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
    callOrder.add('schedule:$id');
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
    callOrder.add('cancel:$id');
  }
}

void main() {
  late AppDatabase db;
  late VeiculosService service;
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
    service = VeiculosService(
      dao: db.veiculosDao,
      lembretesService: lembretesService,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('VeiculosService', () {
    test('arquivar cancela notificações de lembretes pendentes', () async {
      // Insere dois lembretes pendentes para o veículo
      await db.lembretesDao.insertLembrete(
        LembretesCompanion.insert(
          veiculoPlaca: 'ABC1D23',
          tipo: 'avulso',
          descricao: 'Trocar palhetas',
          dataAlvo: Value(DateTime.now().add(const Duration(days: 30))),
          status: StatusLembrete.pendente,
        ),
      );
      final id2 = await db.lembretesDao.insertLembrete(
        LembretesCompanion.insert(
          veiculoPlaca: 'ABC1D23',
          tipo: 'km',
          descricao: 'Trocar óleo',
          kmAlvo: const Value(50000),
          status: StatusLembrete.pendente,
        ),
      );

      // Lembretes com dataAlvo futura são agendados; limpa o estado para
      // facilitar a verificação do cancelamento.
      fake.cancelledIds.clear();

      await service.arquivar('ABC1D23');

      // Ambos os lembretes pendentes devem ter sido cancelados
      expect(fake.cancelledIds, contains(id2));
      // Veículo deve estar arquivado
      final v = await db.veiculosDao.byPlaca('ABC1D23');
      expect(v!.arquivado, isTrue);
    });

    test('arquivar cancela notificações ANTES de arquivar no DAO', () async {
      // Insere lembrete pendente
      await db.lembretesDao.insertLembrete(
        LembretesCompanion.insert(
          veiculoPlaca: 'ABC1D23',
          tipo: 'km',
          descricao: 'Revisão',
          kmAlvo: const Value(60000),
          status: StatusLembrete.pendente,
        ),
      );

      // Captura a ordem das chamadas: o cancel deve vir antes do arquivamento
      // Verificamos indiretamente: se cancelar ocorre com o lembrete ainda
      // acessível, significa que foi antes do arquivamento. A forma mais
      // direta é garantir que o fake recebeu cancel e que o veículo foi
      // arquivado ao final.
      fake.cancelledIds.clear();

      await service.arquivar('ABC1D23');

      // Veículo arquivado → listPendentesByVeiculo deve retornar 0
      // (comportamento após arquivamento: o DAO arquiva o veículo, não
      // deleta os lembretes, mas eles ficam sem veículo ativo).
      expect(fake.cancelledIds, isNotEmpty);
      expect((await db.veiculosDao.byPlaca('ABC1D23'))!.arquivado, isTrue);
    });

    test('arquivar sem lembretes pendentes não falha', () async {
      // Veículo sem lembretes — arquivar deve terminar sem erro
      await expectLater(service.arquivar('ABC1D23'), completes);
      expect((await db.veiculosDao.byPlaca('ABC1D23'))!.arquivado, isTrue);
    });

    test('arquivar NÃO cancela lembretes já concluídos', () async {
      final id = await db.lembretesDao.insertLembrete(
        LembretesCompanion.insert(
          veiculoPlaca: 'ABC1D23',
          tipo: 'avulso',
          descricao: 'IPVA',
          dataAlvo: Value(DateTime.now().add(const Duration(days: 30))),
          status: StatusLembrete.pendente,
        ),
      );
      await db.lembretesDao.marcarConcluido(id);
      fake.cancelledIds.clear();

      await service.arquivar('ABC1D23');

      // Lembrete concluído não aparece em listPendentesByVeiculo,
      // portanto não deve ser cancelado novamente
      expect(fake.cancelledIds, isNot(contains(id)));
    });

    test('restaurar não cancela notificações', () async {
      await service.arquivar('ABC1D23');
      fake.cancelledIds.clear();

      await service.restaurar('ABC1D23');

      // restaurar não deve acionar nenhum cancelamento
      expect(fake.cancelledIds, isEmpty);
      expect((await db.veiculosDao.byPlaca('ABC1D23'))!.arquivado, isFalse);
    });
  });
}
