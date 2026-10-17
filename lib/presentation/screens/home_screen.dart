import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/database/app_database.dart';
import '../../data/database/enums.dart';
import '../../l10n/app_localizations.dart';
import 'veiculos/veiculos_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ativos = ref.watch(veiculosAtivosProvider).value ?? const [];
    final atual = ref.watch(veiculoAtivoProvider);

    return Scaffold(
      appBar: AppBar(
        title: _HomeTitle(ativos: ativos, atual: atual),
        actions: [
          IconButton(
            tooltip: l10n.tooltipComparador,
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => context.push('/comparador'),
          ),
          IconButton(
            tooltip: l10n.tooltipConfiguracoes,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/config'),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.appSubtitulo,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _HomeTitle extends ConsumerWidget {
  const _HomeTitle({required this.ativos, required this.atual});

  final List<Veiculo> ativos;
  final Veiculo? atual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (ativos.length < 2 || atual == null) {
      return Text(l10n.appTitle);
    }

    return PopupMenuButton<String>(
      tooltip: l10n.tooltipTrocarVeiculo,
      position: PopupMenuPosition.under,
      initialValue: atual!.placa,
      onSelected: (placa) => unawaited(
        ref.read(veiculoSelecionadoProvider.notifier).selecionar(placa),
      ),
      itemBuilder: (context) => [
        for (final v in ativos)
          PopupMenuItem<String>(
            value: v.placa,
            child: _VeiculoMenuTile(
              veiculo: v,
              selecionada: v.placa == atual!.placa,
            ),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              _tituloVeiculo(atual!),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}

class _VeiculoMenuTile extends StatelessWidget {
  const _VeiculoMenuTile({required this.veiculo, required this.selecionada});

  final Veiculo veiculo;
  final bool selecionada;

  @override
  Widget build(BuildContext context) {
    final icone = veiculo.tipo == TipoVeiculo.carro
        ? Icons.directions_car
        : Icons.two_wheeler;
    return Row(
      children: [
        Icon(icone, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_tituloVeiculo(veiculo)),
              Text(veiculo.placa, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        if (selecionada) const Icon(Icons.check, size: 20),
      ],
    );
  }
}

String _tituloVeiculo(Veiculo v) {
  final apelido = v.apelido;
  if (apelido != null && apelido.isNotEmpty) return apelido;
  return '${v.marca} ${v.modelo}';
}
