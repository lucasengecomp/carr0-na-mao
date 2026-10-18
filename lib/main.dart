import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/providers.dart';
import 'presentation/app.dart';
import 'services/notifications_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();

  // Inicializa serviço de notificações locais antes do runApp.
  await container.read(notificationsServiceProvider).init();

  final json = await rootBundle.loadString('assets/data/marcas_modelos.json');
  await container.read(marcasModelosDaoProvider).seedFromJson(json);

  // Rotina de startup: materializa ocorrências até o fim do mês corrente
  // para todas as despesas ativas (idempotente — não duplica).
  await _materializarDespesasAtivas(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CarroNaMaoApp(),
    ),
  );
}

/// Itera todas as despesas recorrentes ativas e gera as ocorrências até o
/// fim do mês corrente. Chamado a cada abertura do app (idempotente).
Future<void> _materializarDespesasAtivas(ProviderContainer container) async {
  final despesasDao = container.read(despesasRecorrentesDaoProvider);
  final ocorrenciasDao = container.read(ocorrenciasDespesaDaoProvider);
  final ativas = await despesasDao.listAtivas();
  for (final despesa in ativas) {
    await ocorrenciasDao.materializar(despesa);
  }
}
