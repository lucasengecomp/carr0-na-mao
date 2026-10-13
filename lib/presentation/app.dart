import 'package:flutter/material.dart';

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
      routerConfig: appRouter,
    );
  }
}
