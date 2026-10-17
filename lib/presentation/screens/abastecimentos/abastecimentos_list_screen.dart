import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../veiculos/veiculos_providers.dart';
import 'abastecimentos_list_providers.dart';
import 'enum_labels.dart';

/// Tela de lista de abastecimentos com filtros (RF-08 / issue #14).
///
/// Funcionalidades:
/// - Lista ordenada por data desc, agrupada por mês.
/// - Filtro de período: 30d / 90d / 12m / tudo.
/// - Filtro de tipo de combustível (chips horizontais).
/// - Toque em item abre o form em modo edição.
class AbastecimentosListScreen extends ConsumerWidget {
  const AbastecimentosListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final veiculo = ref.watch(veiculoAtivoProvider);
    final abastecimentos = ref.watch(
      abastecimentosFiltradosProvider(veiculo?.placa),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.abastecimentosTitulo),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(108),
          child: _FiltrosBar(),
        ),
      ),
      body: veiculo == null
          ? const _SemVeiculo()
          : abastecimentos.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text(l10n.erroGenerico(e.toString()))),
              data: (lista) => lista.isEmpty
                  ? const _ListaVazia()
                  : _ListaAgrupada(itens: lista),
            ),
      floatingActionButton: veiculo == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/abastecimentos/novo'),
              icon: const Icon(Icons.add),
              label: Text(l10n.abastecimentoFab),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Barra de filtros
// ---------------------------------------------------------------------------

class _FiltrosBar extends ConsumerWidget {
  const _FiltrosBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filtros = ref.watch(filtrosAbastecimentoProvider);
    final notifier = ref.read(filtrosAbastecimentoProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filtro de período (segmented-like usando FilterChip)
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final p in FiltroPeriodo.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(p.label(l10n)),
                    selected: filtros.periodo == p,
                    onSelected: (_) => notifier.setPeriodo(p),
                  ),
                ),
            ],
          ),
        ),
        // Filtro de combustível
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(l10n.filtroTodos),
                  selected: filtros.tipoCombustivel == null,
                  onSelected: (_) => notifier.setTipoCombustivel(null),
                ),
              ),
              for (final t in TipoCombustivelAbastecimento.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(t.label(l10n)),
                    selected: filtros.tipoCombustivel == t,
                    onSelected: (_) => notifier.setTipoCombustivel(
                      filtros.tipoCombustivel == t ? null : t,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Lista agrupada por mês
// ---------------------------------------------------------------------------

class _ListaAgrupada extends StatelessWidget {
  const _ListaAgrupada({required this.itens});

  final List<Abastecimento> itens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Agrupa por "ano-mes" mantendo a ordem desc (itens já chegam ordenados).
    final grupos = <_GrupoMes>[];
    _GrupoMes? atual;

    for (final a in itens) {
      final chave = _chaveAnoMes(a.data);
      if (atual == null || atual.chave != chave) {
        atual = _GrupoMes(chave: chave, cabecalho: _labelMes(a.data, l10n));
        grupos.add(atual);
      }
      atual.itens.add(a);
    }

    // Constrói lista com cabeçalhos de mês intercalados.
    final widgets = <Widget>[];
    for (final grupo in grupos) {
      widgets.add(_CabecalhoMes(label: grupo.cabecalho));
      for (var i = 0; i < grupo.itens.length; i++) {
        widgets.add(_AbastecimentoTile(item: grupo.itens[i]));
        if (i < grupo.itens.length - 1) {
          widgets.add(const Divider(height: 1, indent: 16, endIndent: 16));
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: widgets,
    );
  }

  String _chaveAnoMes(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  String _labelMes(DateTime d, AppLocalizations l10n) {
    final raw = DateFormat('MMMM yyyy', l10n.localeName).format(d);
    // Garante capitalização mesmo quando o locale retorna em minúsculo (ex: pt)
    return raw[0].toUpperCase() + raw.substring(1);
  }
}

class _GrupoMes {
  _GrupoMes({required this.chave, required this.cabecalho});

  final String chave;
  final String cabecalho;
  final List<Abastecimento> itens = [];
}

class _CabecalhoMes extends StatelessWidget {
  const _CabecalhoMes({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _AbastecimentoTile extends StatelessWidget {
  const _AbastecimentoTile({required this.item});

  final Abastecimento item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final a = item;
    return Semantics(
      label:
          '${a.tipoCombustivel.label(l10n)}, ${_fmtData(a.data)}, ${_fmtKm(a.km)} quilômetros, '
          '${_fmtLitros(a.litros)} litros, R\$ ${_fmtMoney(a.valorTotal)}'
          '${a.posto != null && a.posto!.isNotEmpty ? ", ${a.posto}" : ""}',
      child: ListTile(
        minTileHeight: 48,
        leading: const Icon(Icons.local_gas_station_outlined),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${_fmtData(a.data)} · ${a.tipoCombustivel.label(l10n)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              'R\$ ${_fmtMoney(a.valorTotal)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        subtitle: Text(
          '${_fmtKm(a.km)} km · ${_fmtLitros(a.litros)} L'
          '${a.posto != null && a.posto!.isNotEmpty ? ' · ${a.posto}' : ''}',
        ),
        onTap: () => context.push('/abastecimentos/${a.id}/editar'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estados especiais
// ---------------------------------------------------------------------------

class _SemVeiculo extends StatelessWidget {
  const _SemVeiculo();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              l10n.semVeiculoCadastrarAbastecimento,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/veiculos/novo'),
              icon: const Icon(Icons.add),
              label: Text(l10n.botaoCadastrarVeiculo),
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
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.abastecimentoListaVaziaFiltro,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Formatadores
// ---------------------------------------------------------------------------

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

String _fmtLitros(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

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
