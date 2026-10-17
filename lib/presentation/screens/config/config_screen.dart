import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.configuracoesTitulo)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.directions_car_outlined),
            title: Text(l10n.configuracoesVeiculosTitulo),
            subtitle: Text(l10n.configuracoesVeiculosSubtitulo),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/veiculos'),
          ),
        ],
      ),
    );
  }
}
