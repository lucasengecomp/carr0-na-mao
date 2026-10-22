import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/manutencoes_service.dart';
import '../veiculos/veiculos_providers.dart';
import 'manutencao_enum_labels.dart';
import 'manutencoes_providers.dart';

/// Tela de lista de manutenções (issue #18).
///
/// Funcionalidades:
/// - Lista reativa ordenada por data desc.
/// - Cada linha: tipo (traduzido; se "outros", exibe nomeLivre), data, km,
///   valor (se não-nulo), oficina (se não-nula).
/// - Toque em item abre o form em modo edição.
/// - Toggle "Agrupar por tipo" no AppBar. Default: OFF (lista pura por data).
/// - Quando ON, agrupa com cabeçalhos de tipo alfabético.
/// - Estados: sem veículo, lista vazia (com CTA), loading, erro.
/// - FAB para `/manutencoes/novo`.
class ManutencoesListScreen extends ConsumerStatefulWidget {
  const ManutencoesListScreen({super.key});

  @override
  ConsumerState<ManutencoesListScreen> createState() =>
      _ManutencoesListScreenState();
}

class _ManutencoesListScreenState extends ConsumerState<ManutencoesListScreen> {
  bool _agruparPorTipo = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final veiculo = ref.watch(veiculoAtivoProvider);
    final manutencoes = ref.watch(manutencoesDoVeiculoProvider(veiculo?.placa));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manutencoesTitulo),
        actions: [
          Semantics(
            label: l10n.manutencoesAgruparPorTipo,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    l10n.manutencoesAgruparPorTipo,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Switch(
                  value: _agruparPorTipo,
                  onChanged: (v) => setState(() => _agruparPorTipo = v),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
      body: veiculo == null
          ? const _SemVeiculo()
          : manutencoes.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text(l10n.erroGenerico(e.toString()))),
              data: (lista) => lista.isEmpty
                  ? const _ListaVazia()
                  : _agruparPorTipo
                  ? _ListaAgrupadaPorTipo(itens: lista)
                  : _ListaPorData(itens: lista),
            ),
      floatingActionButton: veiculo == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/manutencoes/novo'),
              icon: const Icon(Icons.add),
              label: Text(l10n.manutencaoFab),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lista plana por data (default)
// ---------------------------------------------------------------------------

class _ListaPorData extends StatelessWidget {
  const _ListaPorData({required this.itens});

  final List<Manutencao> itens;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: itens.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, i) => _ManutencaoTile(item: itens[i]),
    );
  }
}

// ---------------------------------------------------------------------------
// Lista agrupada por tipo
// ---------------------------------------------------------------------------

class _ListaAgrupadaPorTipo extends StatelessWidget {
  const _ListaAgrupadaPorTipo({required this.itens});

  final List<Manutencao> itens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Agrupa mantendo os itens já ordenados por data desc dentro de cada tipo.
    final mapa = <TipoManutencao, List<Manutencao>>{};
    for (final m in itens) {
      (mapa[m.tipo] ??= []).add(m);
    }

    // Ordena os tipos pelo rótulo traduzido (alfabético pt-BR, sem diacríticos).
    final tipos = mapa.keys.toList()
      ..sort((a, b) => _compareLocalePtBr(a.label(l10n), b.label(l10n)));

    final widgets = <Widget>[];
    for (final tipo in tipos) {
      widgets.add(_CabecalhoTipo(label: tipo.label(l10n)));
      final grupo = mapa[tipo]!;
      for (var i = 0; i < grupo.length; i++) {
        widgets.add(_ManutencaoTile(item: grupo[i]));
        if (i < grupo.length - 1) {
          widgets.add(const Divider(height: 1, indent: 16, endIndent: 16));
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: widgets,
    );
  }
}

class _CabecalhoTipo extends StatelessWidget {
  const _CabecalhoTipo({required this.label});

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

// ---------------------------------------------------------------------------
// Tile de manutenção
// ---------------------------------------------------------------------------

class _ManutencaoTile extends ConsumerWidget {
  const _ManutencaoTile({required this.item});

  final Manutencao item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final m = item;

    final tituloTipo =
        m.tipo == TipoManutencao.outros &&
            m.nomeLivre != null &&
            m.nomeLivre!.isNotEmpty
        ? m.nomeLivre!
        : m.tipo.label(l10n);

    final subtituloPartes = <String>[
      '${_fmtKm(m.km)} km',
      if (m.valor != null) 'R\$ ${_fmtMoney(m.valor!)}',
      if (m.oficina != null && m.oficina!.isNotEmpty) m.oficina!,
    ];

    final semanticsLabel =
        '$tituloTipo, ${_fmtData(m.data)}, '
        '${_fmtKm(m.km)} quilômetros'
        '${m.valor != null ? ', R\$ ${_fmtMoney(m.valor!)}' : ''}'
        '${m.oficina != null && m.oficina!.isNotEmpty ? ', ${m.oficina}' : ''}';

    return Semantics(
      label: semanticsLabel,
      child: ListTile(
        minTileHeight: 48,
        leading: const Icon(Icons.build_outlined),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${_fmtData(m.data)} · $tituloTipo',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (m.valor != null)
              Text(
                'R\$ ${_fmtMoney(m.valor!)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
          ],
        ),
        subtitle: Text(subtituloPartes.join(' · ')),
        onTap: () => context.push('/manutencoes/${m.id}/editar'),
        trailing: _ManutencaoMenu(item: m),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Menu de ações (3-dots)
// ---------------------------------------------------------------------------

class _ManutencaoMenu extends ConsumerWidget {
  const _ManutencaoMenu({required this.item});

  final Manutencao item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return PopupMenuButton<_AcaoManutencao>(
      key: Key('menu_manutencao_${item.id}'),
      icon: const Icon(Icons.more_vert),
      tooltip: l10n.manutencaoAcaoExcluir,
      onSelected: (acao) async {
        switch (acao) {
          case _AcaoManutencao.excluir:
            await _confirmarExclusao(context, ref);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _AcaoManutencao.excluir,
          child: Text(l10n.manutencaoAcaoExcluir),
        ),
      ],
    );
  }

  Future<void> _confirmarExclusao(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const _ExcluirManutencaoDialog(),
    );
    if (confirm != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(manutencoesServiceProvider).deleteManutencao(item.id);
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.manutencaoExcluida)));
    } on Object catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.manutencaoNaoPossivel(e.toString()))),
      );
    }
  }
}

enum _AcaoManutencao { excluir }

// ---------------------------------------------------------------------------
// Dialog de confirmação de exclusão
// ---------------------------------------------------------------------------

class _ExcluirManutencaoDialog extends StatelessWidget {
  const _ExcluirManutencaoDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.manutencaoExcluirTitulo),
      content: Text(l10n.manutencaoExcluirMensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.botaoCancelar),
        ),
        FilledButton(
          key: const Key('btn_excluir_manutencao_confirmar'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.manutencaoAcaoExcluir),
        ),
      ],
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
              l10n.semVeiculoCadastrarManutencao,
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
        child: Text(l10n.manutencoesListaVazia, textAlign: TextAlign.center),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ordenação locale-aware (pt-BR) — normaliza diacríticos antes de comparar
// ---------------------------------------------------------------------------

String _normalizePtBr(String s) {
  const map = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'ê': 'e',
    'í': 'i',
    'ï': 'i',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ü': 'u',
    'ç': 'c',
    'Á': 'A',
    'À': 'A',
    'Â': 'A',
    'Ã': 'A',
    'Ä': 'A',
    'É': 'E',
    'Ê': 'E',
    'Í': 'I',
    'Ï': 'I',
    'Ó': 'O',
    'Ô': 'O',
    'Õ': 'O',
    'Ö': 'O',
    'Ú': 'U',
    'Ü': 'U',
    'Ç': 'C',
  };
  return s.split('').map((c) => map[c] ?? c).join().toLowerCase();
}

int _compareLocalePtBr(String a, String b) =>
    _normalizePtBr(a).compareTo(_normalizePtBr(b));

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
