import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/database/app_database.dart';
import '../veiculos/veiculos_providers.dart';
import 'abastecimentos_providers.dart';
import 'enum_labels.dart';

/// Tela da aba "Abastecer". Mostra o histórico do veículo ativo e dá acesso
/// ao form de novo abastecimento via FAB. Filtros avançados vêm na #14.
class AbastecimentosScreen extends ConsumerWidget {
  const AbastecimentosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final veiculo = ref.watch(veiculoAtivoProvider);
    final abastecimentos = ref.watch(
      abastecimentosDoVeiculoProvider(veiculo?.placa),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Abastecimentos')),
      body: veiculo == null
          ? const _SemVeiculo()
          : abastecimentos.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (lista) =>
                  lista.isEmpty ? const _ListaVazia() : _Lista(itens: lista),
            ),
      floatingActionButton: veiculo == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/abastecimentos/novo'),
              icon: const Icon(Icons.add),
              label: const Text('Abastecer'),
            ),
    );
  }
}

class _SemVeiculo extends StatelessWidget {
  const _SemVeiculo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car_outlined, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Cadastre um veículo para começar a registrar abastecimentos.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/veiculos/novo'),
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar veículo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaVazia extends StatelessWidget {
  const _ListaVazia();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Nenhum abastecimento registrado ainda.\nToque em "Abastecer" para começar.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.itens});

  final List<Abastecimento> itens;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: itens.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final a = itens[i];
        return ListTile(
          leading: const Icon(Icons.local_gas_station_outlined),
          title: Text('${a.tipoCombustivel.label} · ${_fmtKm(a.km)} km'),
          subtitle: Text(
            '${_fmtData(a.data)}'
            '${a.posto != null && a.posto!.isNotEmpty ? ' · ${a.posto}' : ''}',
          ),
          trailing: Text(
            'R\$ ${_fmtMoney(a.valorTotal)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          onTap: () => context.push('/abastecimentos/${a.id}/editar'),
        );
      },
    );
  }
}

String _fmtData(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}

String _fmtKm(int km) {
  final s = km.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

String _fmtMoney(double v) {
  final s = v.toStringAsFixed(2).replaceAll('.', ',');
  final parts = s.split(',');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write('.');
    buf.write(intPart[i]);
  }
  return '$buf,${parts[1]}';
}
