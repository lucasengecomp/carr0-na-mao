import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.directions_car_outlined),
            title: const Text('Veículos'),
            subtitle: const Text('Cadastrar, editar e arquivar'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/veiculos'),
          ),
        ],
      ),
    );
  }
}
