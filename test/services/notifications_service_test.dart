import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/services/notifications_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

/// Fake do plugin de notificações para testes. Registra chamadas sem efeito
/// real no sistema operacional.
class FakeNotificationsPlugin implements NotificationsPluginInterface {
  final List<String> calls = [];
  final List<int> cancelledIds = [];
  final List<int> shownIds = [];
  final List<int> scheduledIds = [];

  @override
  Future<void> initialize(InitializationSettings settings) async {
    calls.add('initialize');
  }

  @override
  Future<void> createAndroidChannel(AndroidNotificationChannel channel) async {
    calls.add('createAndroidChannel:${channel.id}');
  }

  @override
  Future<bool?> requestAndroidPermission() async {
    calls.add('requestAndroidPermission');
    return true;
  }

  @override
  Future<bool?> requestIosPermission({
    bool alert = true,
    bool badge = true,
    bool sound = true,
  }) async {
    calls.add('requestIosPermission');
    return null;
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    required String? title,
    required String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required AndroidScheduleMode androidScheduleMode,
  }) async {
    calls.add('zonedSchedule:$id');
    scheduledIds.add(id);
  }

  @override
  Future<void> show({
    required int id,
    required String? title,
    required String? body,
    required NotificationDetails details,
  }) async {
    calls.add('show:$id');
    shownIds.add(id);
  }

  @override
  Future<void> cancel(int id) async {
    calls.add('cancel:$id');
    cancelledIds.add(id);
  }
}

Lembrete _novoLembrete({
  required int id,
  required String placa,
  DateTime? dataAlvo,
  int? kmAlvo,
}) => Lembrete(
  id: id,
  veiculoPlaca: placa,
  manutencaoId: null,
  tipo: 'avulso',
  descricao: 'Trocar palhetas',
  dataAlvo: dataAlvo,
  kmAlvo: kmAlvo,
  status: StatusLembrete.pendente,
);

void main() {
  group('NotificationsService', () {
    late FakeNotificationsPlugin fake;
    late NotificationsService service;

    setUp(() async {
      fake = FakeNotificationsPlugin();
      service = NotificationsService(plugin: fake);
      await service.init();
    });

    test('init inicializa o plugin e cria canal Android', () {
      expect(fake.calls, contains('initialize'));
      expect(fake.calls, contains('createAndroidChannel:lembretes_veiculo'));
    });

    test('init é idempotente — segunda chamada não reinicializa', () async {
      final callsAntes = fake.calls.length;
      await service.init();
      expect(fake.calls.length, callsAntes);
    });

    test('scheduleLembrete agenda quando data é no futuro', () async {
      final lembrete = _novoLembrete(
        id: 1,
        placa: 'ABC1D23',
        dataAlvo: DateTime.now().add(const Duration(days: 30)),
      );
      await service.scheduleLembrete(lembrete);
      expect(fake.scheduledIds, contains(1));
    });

    test(
      'scheduleLembrete NÃO agenda quando data já passou a janela de 7 dias',
      () async {
        final lembrete = _novoLembrete(
          id: 2,
          placa: 'ABC1D23',
          dataAlvo: DateTime.now().add(const Duration(days: 3)),
        );
        await service.scheduleLembrete(lembrete);
        // Data - 7 dias = 4 dias atrás → não deve agendar
        expect(fake.scheduledIds, isNot(contains(2)));
      },
    );

    test('scheduleLembrete NÃO agenda quando dataAlvo é nulo', () async {
      final lembrete = _novoLembrete(id: 3, placa: 'ABC1D23', kmAlvo: 50000);
      await service.scheduleLembrete(lembrete);
      expect(fake.scheduledIds, isEmpty);
    });

    test(
      'scheduleLembrete é idempotente — cancela antes de reagendar',
      () async {
        final lembrete = _novoLembrete(
          id: 4,
          placa: 'ABC1D23',
          dataAlvo: DateTime.now().add(const Duration(days: 30)),
        );
        await service.scheduleLembrete(lembrete);
        await service.scheduleLembrete(lembrete); // segunda vez

        // Deve ter cancelado antes de reagendar
        expect(fake.cancelledIds, contains(4));
        // E deve ter agendado duas vezes
        expect(fake.calls.where((c) => c == 'zonedSchedule:4').length, 2);
      },
    );

    test('cancelLembrete cancela pelo id', () async {
      await service.cancelLembrete(5);
      expect(fake.cancelledIds, contains(5));
    });

    test('cancelByVeiculoLembretes cancela todos', () async {
      final lembretes = [
        _novoLembrete(
          id: 10,
          placa: 'XYZ1234',
          dataAlvo: DateTime.now().add(const Duration(days: 30)),
        ),
        _novoLembrete(id: 11, placa: 'XYZ1234', kmAlvo: 80000),
      ];
      await service.cancelByVeiculoLembretes(lembretes);
      expect(fake.cancelledIds, containsAll([10, 11]));
    });

    test('notifyKmReached dispara show com id offset', () async {
      final lembrete = _novoLembrete(id: 7, placa: 'ABC1D23', kmAlvo: 50000);
      await service.notifyKmReached(lembrete);
      // Id = lembrete.id + 100000
      expect(fake.shownIds, contains(100007));
    });

    test('requestPermissions delega ao plugin Android', () async {
      final ok = await service.requestPermissions();
      expect(ok, isTrue);
      expect(fake.calls, contains('requestAndroidPermission'));
    });

    // Corrigido em #60: notifyKmReached deve ser no-op quando kmAlvo é nulo.
    test(
      'notifyKmReached com kmAlvo nulo — retorna silenciosamente, sem show',
      () async {
        final lembrete = _novoLembrete(
          id: 99,
          placa: 'ABC1D23',
          dataAlvo: DateTime(2027, 6, 1),
          // kmAlvo deliberadamente omitido (null)
        );
        // Não deve lançar exceção.
        await expectLater(service.notifyKmReached(lembrete), completes);
        // Nenhuma notificação deve ter sido exibida.
        expect(fake.shownIds, isNot(contains(99 + 100000)));
      },
    );
  });

  group('NotificationsService — _ensurePermissions (#114)', () {
    late FakeNotificationsPlugin fake;
    late NotificationsService service;

    setUp(() async {
      fake = FakeNotificationsPlugin();
      service = NotificationsService(plugin: fake);
      await service.init();
    });

    test(
      'scheduleLembrete solicita permissão na primeira chamada da sessão',
      () async {
        final lembrete = _novoLembrete(
          id: 20,
          placa: 'TST1A11',
          dataAlvo: DateTime.now().add(const Duration(days: 30)),
        );
        await service.scheduleLembrete(lembrete);
        expect(fake.calls, contains('requestAndroidPermission'));
      },
    );

    test('scheduleLembrete solicita permissão apenas uma vez por sessão (idempotente)', () async {
      final lembrete = _novoLembrete(
        id: 21,
        placa: 'TST1A11',
        dataAlvo: DateTime.now().add(const Duration(days: 30)),
      );
      await service.scheduleLembrete(lembrete);
      await service.scheduleLembrete(lembrete);
      await service.scheduleLembrete(lembrete);

      final permissionCalls = fake.calls
          .where((c) => c == 'requestAndroidPermission')
          .length;
      expect(permissionCalls, 1);
    });

    test(
      'notifyKmReached solicita permissão na primeira chamada da sessão',
      () async {
        final lembrete = _novoLembrete(id: 22, placa: 'TST1A11', kmAlvo: 60000);
        await service.notifyKmReached(lembrete);
        expect(fake.calls, contains('requestAndroidPermission'));
      },
    );

    test('scheduleLembrete e notifyKmReached compartilham flag — só uma requisição', () async {
      final lembreteData = _novoLembrete(
        id: 23,
        placa: 'TST1A11',
        dataAlvo: DateTime.now().add(const Duration(days: 30)),
      );
      final lembreteKm = _novoLembrete(id: 24, placa: 'TST1A11', kmAlvo: 80000);
      await service.scheduleLembrete(lembreteData);
      await service.notifyKmReached(lembreteKm);

      final permissionCalls = fake.calls
          .where((c) => c == 'requestAndroidPermission')
          .length;
      expect(permissionCalls, 1);
    });
  });

  group('NotificationsService — _ensurePermissions em iOS (#114)', () {
    test('quando Android retorna null, solicita permissão iOS', () async {
      final iosFake = _IosFakeNotificationsPlugin();
      final svc = NotificationsService(plugin: iosFake);
      await svc.init();

      final lembrete = _novoLembrete(
        id: 30,
        placa: 'TST1B11',
        dataAlvo: DateTime.now().add(const Duration(days: 30)),
      );
      await svc.scheduleLembrete(lembrete);

      expect(iosFake.calls, contains('requestIosPermission'));
    });

    test('permissão iOS solicitada apenas uma vez por sessão', () async {
      final iosFake = _IosFakeNotificationsPlugin();
      final svc = NotificationsService(plugin: iosFake);
      await svc.init();

      final lembrete = _novoLembrete(
        id: 31,
        placa: 'TST1B11',
        dataAlvo: DateTime.now().add(const Duration(days: 30)),
      );
      await svc.scheduleLembrete(lembrete);
      await svc.scheduleLembrete(lembrete);

      final iosCalls = iosFake.calls
          .where((c) => c == 'requestIosPermission')
          .length;
      expect(iosCalls, 1);
    });
  });

  group('NotificationsService — data de agendamento', () {
    late FakeNotificationsPlugin fake;
    late NotificationsService service;

    setUp(() async {
      fake = FakeNotificationsPlugin();
      service = NotificationsService(plugin: fake);
      await service.init();
    });

    test('data agendada é exatamente 7 dias antes de dataAlvo', () async {
      // Sobrescreve zonedSchedule para capturar a data agendada
      final scheduled = <tz.TZDateTime>[];
      final capturingFake = _CapturingPlugin(fake, scheduled);
      final svc = NotificationsService(plugin: capturingFake);
      await svc.init();

      final dataAlvo = DateTime(2027, 6, 15, 10, 0);
      final lembrete = _novoLembrete(
        id: 1,
        placa: 'ABC1D23',
        dataAlvo: dataAlvo,
      );
      await svc.scheduleLembrete(lembrete);

      expect(scheduled, hasLength(1));
      final esperada = dataAlvo.subtract(const Duration(days: 7));
      expect(scheduled.first.year, esperada.year);
      expect(scheduled.first.month, esperada.month);
      expect(scheduled.first.day, esperada.day);
    });
  });
}

/// Fake que simula comportamento iOS: requestAndroidPermission retorna null
/// (plugin Android ausente), requestIosPermission retorna true.
class _IosFakeNotificationsPlugin implements NotificationsPluginInterface {
  final List<String> calls = [];

  @override
  Future<void> initialize(InitializationSettings settings) async {
    calls.add('initialize');
  }

  @override
  Future<void> createAndroidChannel(AndroidNotificationChannel channel) async {
    calls.add('createAndroidChannel:${channel.id}');
  }

  @override
  Future<bool?> requestAndroidPermission() async {
    // No iOS não há plugin Android; retorna null para cair no iOS path.
    return null;
  }

  @override
  Future<bool?> requestIosPermission({
    bool alert = true,
    bool badge = true,
    bool sound = true,
  }) async {
    calls.add('requestIosPermission');
    return true;
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    required String? title,
    required String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required AndroidScheduleMode androidScheduleMode,
  }) async {
    calls.add('zonedSchedule:$id');
  }

  @override
  Future<void> show({
    required int id,
    required String? title,
    required String? body,
    required NotificationDetails details,
  }) async {
    calls.add('show:$id');
  }

  @override
  Future<void> cancel(int id) async {
    calls.add('cancel:$id');
  }
}

/// Plugin auxiliar que captura a data agendada.
class _CapturingPlugin implements NotificationsPluginInterface {
  _CapturingPlugin(this._delegate, this._captured);

  final NotificationsPluginInterface _delegate;
  final List<tz.TZDateTime> _captured;

  @override
  Future<void> initialize(InitializationSettings settings) =>
      _delegate.initialize(settings);

  @override
  Future<void> createAndroidChannel(AndroidNotificationChannel channel) =>
      _delegate.createAndroidChannel(channel);

  @override
  Future<bool?> requestAndroidPermission() =>
      _delegate.requestAndroidPermission();

  @override
  Future<bool?> requestIosPermission({
    bool alert = true,
    bool badge = true,
    bool sound = true,
  }) =>
      _delegate.requestIosPermission(alert: alert, badge: badge, sound: sound);

  @override
  Future<void> zonedSchedule({
    required int id,
    required String? title,
    required String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required AndroidScheduleMode androidScheduleMode,
  }) {
    _captured.add(scheduledDate);
    return _delegate.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      details: details,
      androidScheduleMode: androidScheduleMode,
    );
  }

  @override
  Future<void> show({
    required int id,
    required String? title,
    required String? body,
    required NotificationDetails details,
  }) => _delegate.show(id: id, title: title, body: body, details: details);

  @override
  Future<void> cancel(int id) => _delegate.cancel(id);
}
