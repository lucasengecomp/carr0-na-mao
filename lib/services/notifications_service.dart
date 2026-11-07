import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/database/app_database.dart';

/// Canal Android para lembretes de manutenção/data.
const _kChannelId = 'lembretes_veiculo';
const _kChannelName = 'Lembretes de veículo';
const _kChannelDesc = 'Notificações de lembretes de manutenção e datas.';

/// Dias de antecedência para notificação de data_alvo.
const _kDiasAntecedencia = 7;

/// Offset do id de notificação imediata de km para não colidir com agendados.
const _kKmNotifOffset = 100000;

/// Interface que abstrai as operações de notificação usadas pelo
/// [NotificationsService]. Permite substituição por fake em testes.
abstract class NotificationsPluginInterface {
  Future<void> initialize(InitializationSettings settings);

  Future<void> createAndroidChannel(AndroidNotificationChannel channel);

  Future<bool?> requestAndroidPermission();

  Future<bool?> requestIosPermission({
    bool alert = true,
    bool badge = true,
    bool sound = true,
  });

  Future<void> zonedSchedule({
    required int id,
    required String? title,
    required String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required AndroidScheduleMode androidScheduleMode,
  });

  Future<void> show({
    required int id,
    required String? title,
    required String? body,
    required NotificationDetails details,
  });

  Future<void> cancel(int id);
}

/// Implementação real que delega ao [FlutterLocalNotificationsPlugin].
class _RealNotificationsPlugin implements NotificationsPluginInterface {
  final _plugin = FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize(InitializationSettings settings) async {
    await _plugin.initialize(settings: settings);
  }

  @override
  Future<void> createAndroidChannel(AndroidNotificationChannel channel) async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(channel);
  }

  @override
  Future<bool?> requestAndroidPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return androidPlugin?.requestNotificationsPermission();
  }

  @override
  Future<bool?> requestIosPermission({
    bool alert = true,
    bool badge = true,
    bool sound = true,
  }) async {
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return iosPlugin?.requestPermissions(
      alert: alert,
      badge: badge,
      sound: sound,
    );
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
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: androidScheduleMode,
    );
  }

  @override
  Future<void> show({
    required int id,
    required String? title,
    required String? body,
    required NotificationDetails details,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
  }
}

/// Serviço de notificações locais para o app Carro na Mão.
///
/// Aceita um [NotificationsPluginInterface] injetável para facilitar
/// testes unitários via fake.
///
/// Ciclo de vida:
/// 1. [init] — chamado uma vez no `main()` antes do `runApp`.
/// 2. [scheduleLembrete] / [cancelLembrete] — chamados pelos services.
/// 3. [cancelByVeiculoLembretes] — chamado ao arquivar um veículo.
/// 4. [notifyKmReached] — chamado ao salvar abastecimento com km atingido.
class NotificationsService {
  NotificationsService({NotificationsPluginInterface? plugin})
    : _plugin = plugin ?? _RealNotificationsPlugin();

  final NotificationsPluginInterface _plugin;

  bool _initialized = false;

  /// Garante que a permissão de notificação foi solicitada ao SO uma única vez
  /// por sessão do app. Idempotente: chamadas subsequentes retornam imediato.
  bool _permissionsRequested = false;

  /// Inicializa timezone e configura canais/permissões.
  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);
    await _plugin.createAndroidChannel(
      const AndroidNotificationChannel(
        _kChannelId,
        _kChannelName,
        description: _kChannelDesc,
        importance: Importance.defaultImportance,
      ),
    );

    _initialized = true;
  }

  /// Pede permissão ao SO para exibir notificações.
  /// No Android 13+ é obrigatório; no iOS é o primeiro prompt ao usuário.
  Future<bool> requestPermissions() async {
    final androidGranted = await _plugin.requestAndroidPermission();
    if (androidGranted != null) return androidGranted;

    final iosGranted = await _plugin.requestIosPermission();
    if (iosGranted != null) return iosGranted;

    return true;
  }

  /// Solicita permissão de notificação ao SO na primeira vez que um
  /// agendamento é solicitado nesta sessão.
  ///
  /// - No iOS: exibe o diálogo "Carro na Mão Would Like to Send You
  ///   Notifications" somente na primeira chamada durante a sessão; o
  ///   sistema ignora chamadas subsequentes se a permissão já foi
  ///   concedida/negada anteriormente.
  /// - No Android 13+: delega ao sistema conforme [requestPermissions].
  /// - Idempotente por sessão: a flag [_permissionsRequested] evita múltiplos
  ///   prompts dentro da mesma execução do app.
  Future<void> _ensurePermissions() async {
    if (_permissionsRequested) return;
    _permissionsRequested = true;
    await requestPermissions();
  }

  /// Agenda (ou re-agenda) a notificação de [_kDiasAntecedencia] dias antes de
  /// [lembrete.dataAlvo].
  ///
  /// Solicita permissão de notificação ao SO na primeira chamada da sessão
  /// (ver [_ensurePermissions]).
  ///
  /// Idempotente: cancela a notificação anterior (mesmo id) antes de agendar.
  /// Não agenda quando [dataAlvo] é nulo ou já passou (incluindo a janela de
  /// antecedência).
  Future<void> scheduleLembrete(Lembrete lembrete) async {
    await _ensurePermissions();

    final dataAlvo = lembrete.dataAlvo;
    if (dataAlvo == null) return;

    // Cancela agendamento anterior (idempotência).
    await cancelLembrete(lembrete.id);

    final dataNotificacao = dataAlvo.subtract(
      const Duration(days: _kDiasAntecedencia),
    );
    final agora = DateTime.now();
    if (dataNotificacao.isBefore(agora)) return;

    final tzDataNot = tz.TZDateTime.from(dataNotificacao, tz.local);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _kChannelId,
        _kChannelName,
        channelDescription: _kChannelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id: lembrete.id,
      title: lembrete.descricao,
      body: _formatarDataAlvo(dataAlvo),
      scheduledDate: tzDataNot,
      details: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Cancela a notificação agendada para [lembreteId].
  Future<void> cancelLembrete(int lembreteId) async {
    await _plugin.cancel(lembreteId);
  }

  /// Cancela todas as notificações de lembretes de um veículo.
  Future<void> cancelByVeiculoLembretes(List<Lembrete> lembretes) async {
    for (final l in lembretes) {
      await cancelLembrete(l.id);
    }
  }

  /// Dispara uma notificação **imediata** indicando que o km alvo foi atingido.
  ///
  /// Solicita permissão de notificação ao SO na primeira chamada da sessão
  /// (ver [_ensurePermissions]).
  ///
  /// Usa um id derivado do lembrete (offset [_kKmNotifOffset]) para não
  /// colidir com as notificações agendadas por [scheduleLembrete].
  ///
  /// Retorna imediatamente sem agendar se [lembrete.kmAlvo] for nulo.
  Future<void> notifyKmReached(Lembrete lembrete) async {
    await _ensurePermissions();

    final kmAlvo = lembrete.kmAlvo;
    if (kmAlvo == null) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _kChannelId,
        _kChannelName,
        channelDescription: _kChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      id: lembrete.id + _kKmNotifOffset,
      title: lembrete.descricao,
      body: _formatarKmAlvo(kmAlvo),
      details: details,
    );
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  String _formatarDataAlvo(DateTime data) {
    final dd = data.day.toString().padLeft(2, '0');
    final mm = data.month.toString().padLeft(2, '0');
    return 'Vence em $dd/$mm/${data.year}';
  }

  String _formatarKmAlvo(int km) => 'Km alvo de $km atingido!';
}

// ── Provider Riverpod ──────────────────────────────────────────────────────

/// Provider singleton do [NotificationsService].
///
/// Em testes, sobrescreva com:
/// ```dart
/// notificationsServiceProvider.overrideWithValue(
///   NotificationsService(plugin: FakeNotificationsPlugin()),
/// )
/// ```
final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  return NotificationsService();
});
