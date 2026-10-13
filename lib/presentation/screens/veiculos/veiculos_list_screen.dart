import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/enums.dart';
import '../../../data/providers.dart';
import 'veiculos_providers.dart';

class VeiculosListScreen extends ConsumerStatefulWidget {
  const VeiculosListScreen({super.key});

  @override
  ConsumerState<VeiculosListScreen> createState() => _VeiculosListScreenState();
}

class _VeiculosListScreenState extends ConsumerState<VeiculosListScreen> {
  bool _arquivados = false;

  Future<void> _toggleArquivado(Veiculo v) async {
    final dao = ref.read(veiculosDaoProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (v.arquivado) {
      await dao.restaurar(v.placa);
      messenger.showSnackBar(SnackBar(content: Text('${v.placa} restaurado')));
    } else {
      await dao.arquivar(v.placa);
      messenger.showSnackBar(SnackBar(content: Text('${v.placa} arquivado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(
      _arquivados ? veiculosArquivadosProvider : veiculosAtivosProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Veículos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Ativos')),
                ButtonSegment(value: true, label: Text('Arquivados')),
              ],
              selected: {_arquivados},
              onSelectionChanged: (s) => setState(() => _arquivados = s.first),
            ),
          ),
        ),
      ),
      body: asyncList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
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
              label: const Text('Novo veículo'),
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
            const PopupMenuItem(
              value: _TileAction.editar,
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Editar'),
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
              title: Text(veiculo.arquivado ? 'Restaurar' : 'Arquivar'),
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
    final msg = arquivados
        ? 'Nenhum veículo arquivado.'
        : 'Nenhum veículo cadastrado. Toque em "Novo veículo" para começar.';
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
