import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/enums.dart';
import '../../../l10n/app_localizations.dart';
import 'lembretes_providers.dart';

/// Tela de lembretes agrupados por status (issue #25).
///
/// Três abas:
///  - Pendentes: status=pendente, dataAlvo futura ou nula, ordenados por
///    proximidade.
///  - Atrasados: status=pendente, dataAlvo < hoje.
///  - Concluídos: status in {concluido, adiado}, histórico por dataAlvo desc.
///
/// Escopo: lista global (todos os veículos). A placa é exibida em cada linha.
///
/// FAB: stub — exibe SnackBar "em breve" até a issue #27 ser implementada.
/// Toque na linha: stub — exibe SnackBar "em breve" até a issue #26.
class LembretesListScreen extends ConsumerStatefulWidget {
  const LembretesListScreen({super.key});

  @override
  ConsumerState<LembretesListScreen> createState() =>
      _LembretesListScreenState();
}

class _LembretesListScreenState extends ConsumerState<LembretesListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.lembretesTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.lembretesTabPendentes),
            Tab(text: l10n.lembretesTabAtrasados),
            Tab(text: l10n.lembretesTabConcluidos),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LembretesTab(
            provider: lembretesPendentesProvider,
            emptyMessage: l10n.lembretesVazioPendentes,
          ),
          _LembretesTab(
            provider: lembretesAtrasadosProvider,
            emptyMessage: l10n.lembretesVazioAtrasados,
          ),
          _LembretesTab(
            provider: lembretesConcluidosProvider,
            emptyMessage: l10n.lembretesVazioConcluidos,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onFabTap(context, l10n),
        icon: const Icon(Icons.add),
        label: Text(l10n.lembretesFab),
      ),
    );
  }

  // Issue #27: navega para o formulário de criação de lembrete avulso.
  void _onFabTap(BuildContext context, AppLocalizations l10n) {
    unawaited(context.push('/lembretes/novo'));
  }
}

// ---------------------------------------------------------------------------
// Tab genérica
// ---------------------------------------------------------------------------

class _LembretesTab extends ConsumerWidget {
  const _LembretesTab({required this.provider, required this.emptyMessage});

  final StreamProvider<List<Lembrete>> provider;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(provider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object e, StackTrace _) =>
          Center(child: Text(l10n.erroGenerico(e.toString()))),
      data: (List<Lembrete> lista) => lista.isEmpty
          ? _EmptyState(message: emptyMessage)
          : _LembretesList(itens: lista),
    );
  }
}

// ---------------------------------------------------------------------------
// Lista de lembretes
// ---------------------------------------------------------------------------

class _LembretesList extends StatelessWidget {
  const _LembretesList({required this.itens});

  final List<Lembrete> itens;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: itens.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, i) => _LembreteTile(item: itens[i]),
    );
  }
}

// ---------------------------------------------------------------------------
// Tile de lembrete
// ---------------------------------------------------------------------------

class _LembreteTile extends StatelessWidget {
  const _LembreteTile({required this.item});

  final Lembrete item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final l = item;

    final partes = <String>[];
    if (l.dataAlvo != null) partes.add(_fmtData(l.dataAlvo!));
    if (l.kmAlvo != null) partes.add('${_fmtKm(l.kmAlvo!)} km');

    final subtitulo = [l.veiculoPlaca, ...partes].join(' · ');

    final badgeColor = _badgeColor(context, l.status);
    final badgeLabel = _badgeLabel(l10n, l.status);

    final semanticsLabel =
        '${l.descricao}, veículo ${l.veiculoPlaca}'
        '${l.dataAlvo != null ? ', ${_fmtData(l.dataAlvo!)}' : ''}'
        '${l.kmAlvo != null ? ', ${_fmtKm(l.kmAlvo!)} km' : ''}'
        ', $badgeLabel';

    return Semantics(
      label: semanticsLabel,
      child: ListTile(
        minTileHeight: 48,
        leading: const Icon(Icons.notifications_outlined),
        title: Row(
          children: [
            Expanded(
              child: Text(
                l.descricao,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _StatusBadge(label: badgeLabel, color: badgeColor),
          ],
        ),
        subtitle: Text(subtitulo),
        onTap: () => _onTap(context, l10n),
      ),
    );
  }

  void _onTap(BuildContext context, AppLocalizations l10n) {
    unawaited(context.push('/lembretes/${item.id}'));
  }

  Color _badgeColor(BuildContext context, StatusLembrete status) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case StatusLembrete.pendente:
        return cs.primary;
      case StatusLembrete.concluido:
        return cs.outline;
      case StatusLembrete.adiado:
        return cs.tertiary;
    }
  }

  String _badgeLabel(AppLocalizations l10n, StatusLembrete status) {
    switch (status) {
      case StatusLembrete.pendente:
        return l10n.lembretesStatusPendente;
      case StatusLembrete.concluido:
        return l10n.lembretesStatusConcluido;
      case StatusLembrete.adiado:
        return l10n.lembretesStatusAdiado;
    }
  }
}

// ---------------------------------------------------------------------------
// Badge de status
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estado vazio
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
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
