import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/enums.dart';
import '../veiculos/veiculos_providers.dart';
import 'dashboard_providers.dart';

class DashboardHomeScreen extends ConsumerWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ativos = ref.watch(veiculosAtivosProvider).value ?? const [];
    final veiculo = ref.watch(veiculoAtivoProvider);

    return Scaffold(
      appBar: AppBar(
        title: _HomeTitle(ativos: ativos, atual: veiculo),
        actions: [
          if (veiculo != null)
            IconButton(
              tooltip: 'Gráficos',
              icon: const Icon(Icons.bar_chart_outlined),
              onPressed: () => context.push(
                '/dashboard/graficos?placa=${Uri.encodeComponent(veiculo.placa)}',
              ),
            ),
          IconButton(
            tooltip: 'Configurações',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/config'),
          ),
        ],
      ),
      body: veiculo == null
          ? const _SemVeiculo()
          : _DashboardBody(veiculo: veiculo),
    );
  }
}

// ---------------------------------------------------------------------------
// Título com seletor de veículo (igual ao HomeScreen original)
// ---------------------------------------------------------------------------

class _HomeTitle extends ConsumerWidget {
  const _HomeTitle({required this.ativos, required this.atual});

  final List<Veiculo> ativos;
  final Veiculo? atual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ativos.length < 2 || atual == null) {
      return const Text('Carro na Mão');
    }

    return PopupMenuButton<String>(
      tooltip: 'Trocar veículo',
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

// ---------------------------------------------------------------------------
// Corpo do dashboard
// ---------------------------------------------------------------------------

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.veiculo});

  final Veiculo veiculo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Grid 2x2 em telas largas (>= 500dp), coluna única em telas estreitas
          final wide = constraints.maxWidth >= 500;
          if (wide) {
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _CustoMensalCard(placa: veiculo.placa)),
                    const SizedBox(width: 12),
                    Expanded(child: _CustoPorKmCard(placa: veiculo.placa)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _ConsumoMedioCard(placa: veiculo.placa)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ProximasManutencoeCard(placa: veiculo.placa),
                    ),
                  ],
                ),
              ],
            );
          }

          return Column(
            children: [
              _CustoMensalCard(placa: veiculo.placa),
              const SizedBox(height: 12),
              _CustoPorKmCard(placa: veiculo.placa),
              const SizedBox(height: 12),
              _ConsumoMedioCard(placa: veiculo.placa),
              const SizedBox(height: 12),
              _ProximasManutencoeCard(placa: veiculo.placa),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget base de card
// ---------------------------------------------------------------------------

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.titulo,
    required this.icone,
    required this.child,
  });

  final String titulo;
  final IconData icone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icone, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

Widget _cardLoading() => const SizedBox(
  height: 40,
  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
);

Widget _cardError(Object e, StackTrace _) => Text('Erro: $e', maxLines: 2);

Widget _cardPlaceholder(String mensagem) => Text(
  mensagem,
  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
);

// ---------------------------------------------------------------------------
// Card 1 — Custo total no mês
// ---------------------------------------------------------------------------

class _CustoMensalCard extends ConsumerWidget {
  const _CustoMensalCard({required this.placa});

  final String placa;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(custoMensalProvider);

    return _DashboardCard(
      titulo: 'Custo total no mês',
      icone: Icons.account_balance_wallet_outlined,
      child: async.when(
        loading: _cardLoading,
        error: _cardError,
        data: (result) {
          if (result == null) {
            return _cardPlaceholder('Dados insuficientes');
          }
          return Semantics(
            label: 'Custo total no mês: ${_fmtMoeda(result.total)}',
            child: Text(
              'R\$ ${_fmtMoeda(result.total)}',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card 2 — Custo por km
// ---------------------------------------------------------------------------

class _CustoPorKmCard extends ConsumerWidget {
  const _CustoPorKmCard({required this.placa});

  final String placa;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(custoPorKmProvider);

    return _DashboardCard(
      titulo: 'Custo por km',
      icone: Icons.route_outlined,
      child: async.when(
        loading: _cardLoading,
        error: _cardError,
        data: (result) {
          if (result == null) {
            return _cardPlaceholder('Dados insuficientes');
          }
          final valor = _fmtMoeda(result.custoPorKm);
          return Semantics(
            label: 'Custo por quilômetro: R\$ $valor/km',
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
                children: [
                  TextSpan(text: 'R\$ $valor'),
                  TextSpan(
                    text: '/km',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card 3 — Consumo médio km/l
// ---------------------------------------------------------------------------

class _ConsumoMedioCard extends ConsumerWidget {
  const _ConsumoMedioCard({required this.placa});

  final String placa;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(consumoMedioProvider);

    return _DashboardCard(
      titulo: 'Consumo médio',
      icone: Icons.local_gas_station_outlined,
      child: async.when(
        loading: _cardLoading,
        error: _cardError,
        data: (result) {
          if (result == null) {
            return _cardPlaceholder('Dados insuficientes');
          }
          final valor = result.kmPorLitro
              .toStringAsFixed(1)
              .replaceAll('.', ',');
          return Semantics(
            label: 'Consumo médio: $valor quilômetros por litro',
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
                children: [
                  TextSpan(text: valor),
                  TextSpan(
                    text: ' km/l',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card 4 — Próximas manutenções
// ---------------------------------------------------------------------------

class _ProximasManutencoeCard extends ConsumerWidget {
  const _ProximasManutencoeCard({required this.placa});

  final String placa;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(proximasManutencoeProvider);

    return _DashboardCard(
      titulo: 'Próximas manutenções',
      icone: Icons.build_outlined,
      child: async.when(
        loading: _cardLoading,
        error: _cardError,
        data: (lista) {
          if (lista == null || lista.isEmpty) {
            return _cardPlaceholder('Sem lembretes pendentes');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [for (final l in lista) _LembreteTile(lembrete: l)],
          );
        },
      ),
    );
  }
}

class _LembreteTile extends StatelessWidget {
  const _LembreteTile({required this.lembrete});

  final Lembrete lembrete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitulo = _subtituloLembrete(lembrete);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        label: '${lembrete.descricao}. $subtitulo',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.circle, size: 8),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lembrete.descricao,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitulo.isNotEmpty)
                    Text(
                      subtitulo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _subtituloLembrete(Lembrete l) {
  final partes = <String>[];
  if (l.dataAlvo != null) {
    partes.add(_fmtData(l.dataAlvo!));
  }
  if (l.kmAlvo != null) {
    partes.add('${_fmtKm(l.kmAlvo!)} km');
  }
  return partes.join(' · ');
}

// ---------------------------------------------------------------------------
// Estado: sem veículo cadastrado
// ---------------------------------------------------------------------------

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
            const Icon(Icons.directions_car_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'Nenhum veículo cadastrado.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Cadastre um veículo para ver seu painel de custos.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
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

// ---------------------------------------------------------------------------
// Formatadores
// ---------------------------------------------------------------------------

String _fmtMoeda(double v) {
  final s = v.toStringAsFixed(2).replaceAll('.', ',');
  final partes = s.split(',');
  final inteiro = partes[0];
  final buf = StringBuffer();
  for (var i = 0; i < inteiro.length; i++) {
    if (i > 0 && (inteiro.length - i) % 3 == 0) buf.write('.');
    buf.write(inteiro[i]);
  }
  return '$buf,${partes[1]}';
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

String _fmtData(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}
