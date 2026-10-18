import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_localizations.dart';
import 'router.dart';

class CarroNaMaoApp extends StatelessWidget {
  const CarroNaMaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Carro na Mão',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR'), Locale('pt'), Locale('en')],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (deviceLocale?.languageCode == 'pt') return const Locale('pt', 'BR');
        return const Locale('en');
      },
      routerConfig: appRouter,
    );
  }
}
