import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/veiculos_service.dart';
import 'veiculos_providers.dart';

class VeiculosListScreen extends ConsumerStatefulWidget {
  const VeiculosListScreen({super.key});

  @override
  ConsumerState<VeiculosListScreen> createState() => _VeiculosListScreenState();
}

class _VeiculosListScreenState extends ConsumerState<VeiculosListScreen> {
  bool _arquivados = false;

  Future<void> _toggleArquivado(Veiculo v) async {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.read(veiculosServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (v.arquivado) {
      await service.restaurar(v.placa);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.veiculoRestauradoSnack(v.placa))),
      );
    } else {
      await service.arquivar(v.placa);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.veiculoArquivadoSnack(v.placa))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asyncList = ref.watch(
      _arquivados ? veiculosArquivadosProvider : veiculosAtivosProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.veiculosTitulo),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l10n.veiculoAtivos)),
                ButtonSegment(value: true, label: Text(l10n.veiculoArquivados)),
              ],
              selected: {_arquivados},
              onSelectionChanged: (s) => setState(() => _arquivados = s.first),
            ),
          ),
        ),
      ),
      body: asyncList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(l10n.veiculoErroCarregar(e.toString()))),
        data: (list) => list.isEmpty
            ? _EmptyState(arquivados: _arquivados)
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) => _VeiculoTile(
                  veiculo: list[i],
                  onToggleArquivado: () => unawaited(_toggleArquivado(list[i])),
                ),
              ),
      ),
      floatingActionButton: _arquivados
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/veiculos/novo'),
              icon: const Icon(Icons.add),
              label: Text(l10n.veiculoFab),
            ),
    );
  }
}

class _VeiculoTile extends StatelessWidget {
  const _VeiculoTile({required this.veiculo, required this.onToggleArquivado});

  final Veiculo veiculo;
  final VoidCallback onToggleArquivado;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titulo = veiculo.apelido?.isNotEmpty ?? false
        ? veiculo.apelido!
        : '${veiculo.marca} ${veiculo.modelo}';
    final icone = veiculo.tipo == TipoVeiculo.carro
        ? Icons.directions_car
        : Icons.two_wheeler;
    return ListTile(
      leading: CircleAvatar(child: Icon(icone)),
      title: Text(titulo),
      subtitle: Text('${veiculo.placa} · ${veiculo.ano}'),
      onTap: veiculo.arquivado
          ? null
          : () => context.push('/veiculos/${veiculo.placa}/editar'),
      trailing: PopupMenuButton<_TileAction>(
        itemBuilder: (context) => [
          if (!veiculo.arquivado)
            PopupMenuItem(
              value: _TileAction.editar,
              child: ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.veiculoMenuEditar),
              ),
            ),
          PopupMenuItem(
            value: _TileAction.toggleArquivar,
            child: ListTile(
              leading: Icon(
                veiculo.arquivado
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
              ),
              title: Text(
                veiculo.arquivado
                    ? l10n.veiculoMenuRestaurar
                    : l10n.veiculoMenuArquivar,
              ),
            ),
          ),
        ],
        onSelected: (action) {
          switch (action) {
            case _TileAction.editar:
              unawaited(context.push('/veiculos/${veiculo.placa}/editar'));
            case _TileAction.toggleArquivar:
              onToggleArquivado();
          }
        },
      ),
    );
  }
}

enum _TileAction { editar, toggleArquivar }

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.arquivados});

  final bool arquivados;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final msg = arquivados
        ? l10n.veiculoNenhumArquivado
        : l10n.veiculoNenhumAtivo;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              arquivados
                  ? Icons.archive_outlined
                  : Icons.directions_car_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(msg, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
