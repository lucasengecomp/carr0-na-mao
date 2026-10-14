import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/providers.dart';
import 'presentation/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  final json = await rootBundle.loadString('assets/data/marcas_modelos.json');
  await container.read(marcasModelosDaoProvider).seedFromJson(json);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CarroNaMaoApp(),
    ),
  );
}
