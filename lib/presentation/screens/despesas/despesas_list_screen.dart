import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/database/enums.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../veiculos/veiculos_providers.dart';
import 'despesas_providers.dart';
import 'enum_labels.dart';

/// Tela de lista de ocorrências de despesas (RF-13 / issue #22).
///
/// Funcionalidades:
/// - Agrupa ocorrências por mês (vencimento), ordenadas por data asc.
/// - Ocorrências vencidas (status=pendente e dataVencimento < hoje) em
///   vermelho (colorScheme.error).
/// - Ações via 3-dots menu por item:
///   - Pendente: "Marcar paga" (dialog com valor e data editáveis), "Pular".
///   - Paga: "Editar valor pago" (dialog).
/// - FAB → /despesas/novo.
class DespesasListScreen extends ConsumerWidget {
  const DespesasListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final veiculo = ref.watch(veiculoAtivoProvider);
    final ocorrenciasAsync = veiculo == null
        ? null
        : ref.watch(ocorrenciasProximasProvider(veiculo.placa));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.despesasListTitulo)),
      body: veiculo == null
          ? _SemVeiculo(l10n: l10n)
          : ocorrenciasAsync!.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text(l10n.erroGenerico(e.toString()))),
              data: (lista) => lista.isEmpty
                  ? _ListaVazia(l10n: l10n)
                  : _ListaAgrupada(itens: lista),
            ),
      floatingActionButton: veiculo == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/despesas/novo'),
              icon: const Icon(Icons.add),
              label: Text(l10n.despesasListFab),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lista agrupada por mês
// ---------------------------------------------------------------------------

class _ListaAgrupada extends StatelessWidget {
  const _ListaAgrupada({required this.itens});

  final List<OcorrenciaComDespesa> itens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Agrupa por "ano-mês" (chave) mantendo ordem asc de vencimento.
    final grupos = <_GrupoMes>[];
    _GrupoMes? atual;

    for (final item in itens) {
      final chave = _chaveAnoMes(item.ocorrencia.dataVencimento);
      if (atual == null || atual.chave != chave) {
        atual = _GrupoMes(
          chave: chave,
          cabecalho: _labelMes(item.ocorrencia.dataVencimento, l10n),
        );
        grupos.add(atual);
      }
      atual.itens.add(item);
    }

    final widgets = <Widget>[];
    for (final grupo in grupos) {
      widgets.add(_CabecalhoMes(label: grupo.cabecalho));
      for (var i = 0; i < grupo.itens.length; i++) {
        widgets.add(_OcorrenciaTile(item: grupo.itens[i]));
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
    return raw[0].toUpperCase() + raw.substring(1);
  }
}

class _GrupoMes {
  _GrupoMes({required this.chave, required this.cabecalho});

  final String chave;
  final String cabecalho;
  final List<OcorrenciaComDespesa> itens = [];
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

// ---------------------------------------------------------------------------
// Tile de ocorrência
// ---------------------------------------------------------------------------

class _OcorrenciaTile extends ConsumerWidget {
  const _OcorrenciaTile({required this.item});

  final OcorrenciaComDespesa item;

  bool _isVencida() {
    final hoje = DateTime.now();
    final hoje0 = DateTime(hoje.year, hoje.month, hoje.day);
    return item.ocorrencia.status == StatusOcorrencia.pendente &&
        item.ocorrencia.dataVencimento.isBefore(hoje0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final o = item.ocorrencia;
    final d = item.despesa;
    final vencida = _isVencida();
    final errorColor = Theme.of(context).colorScheme.error;

    return Semantics(
      label:
          '${d.nome}, vence em ${_fmtData(o.dataVencimento)}, '
          '${o.status.label(l10n)}, R\$ ${_fmtMoney(o.valorPago ?? d.valor)}',
      child: ListTile(
        minTileHeight: 48,
        leading: Icon(
          Icons.receipt_long_outlined,
          color: vencida ? errorColor : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                d.nome,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: vencida ? errorColor : null),
              ),
            ),
            Text(
              'R\$ ${_fmtMoney(o.valorPago ?? d.valor)}',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: vencida ? errorColor : null),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Text(
              _fmtData(o.dataVencimento),
              style: TextStyle(color: vencida ? errorColor : null),
            ),
            const SizedBox(width: 8),
            _StatusChip(status: o.status),
          ],
        ),
        trailing: _AcoesMenu(item: item),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final StatusOcorrencia status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: status.chipColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label(l10n),
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: status.chipTextColor(context)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Menu de ações (3-dots)
// ---------------------------------------------------------------------------

class _AcoesMenu extends ConsumerWidget {
  const _AcoesMenu({required this.item});

  final OcorrenciaComDespesa item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final o = item.ocorrencia;
    final d = item.despesa;

    if (o.status == StatusOcorrencia.pulada) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<_Acao>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Ações',
      onSelected: (acao) async {
        switch (acao) {
          case _Acao.marcarPaga:
            await _mostrarDialogMarcarPaga(
              context,
              ref,
              ocorrenciaId: o.id,
              valorDefault: d.valor,
            );
          case _Acao.pular:
            await ref.read(ocorrenciasDespesaDaoProvider).marcarPulada(o.id);
          case _Acao.editarValor:
            await _mostrarDialogEditarValor(
              context,
              ref,
              ocorrenciaId: o.id,
              valorAtual: o.valorPago ?? d.valor,
            );
        }
      },
      itemBuilder: (context) => [
        if (o.status == StatusOcorrencia.pendente) ...[
          PopupMenuItem(
            value: _Acao.marcarPaga,
            child: Text(l10n.ocorrenciaAcaoMarcarPaga),
          ),
          PopupMenuItem(
            value: _Acao.pular,
            child: Text(l10n.ocorrenciaAcaoPular),
          ),
        ] else if (o.status == StatusOcorrencia.paga) ...[
          PopupMenuItem(
            value: _Acao.editarValor,
            child: Text(l10n.ocorrenciaAcaoEditarValor),
          ),
        ],
      ],
    );
  }

  Future<void> _mostrarDialogMarcarPaga(
    BuildContext context,
    WidgetRef ref, {
    required int ocorrenciaId,
    required double valorDefault,
  }) async {
    final resultado = await showDialog<_ResultadoMarcarPaga>(
      context: context,
      builder: (_) => _MarcarPagaDialog(valorDefault: valorDefault),
    );

    if (resultado != null && context.mounted) {
      await ref
          .read(ocorrenciasDespesaDaoProvider)
          .marcarPaga(
            ocorrenciaId,
            valorPago: resultado.valor,
            dataPagamento: resultado.dataPagamento,
          );
    }
  }

  Future<void> _mostrarDialogEditarValor(
    BuildContext context,
    WidgetRef ref, {
    required int ocorrenciaId,
    required double valorAtual,
  }) async {
    final novoValor = await showDialog<double>(
      context: context,
      builder: (_) => _EditarValorDialog(valorInicial: valorAtual),
    );

    if (novoValor != null && context.mounted) {
      await ref
          .read(ocorrenciasDespesaDaoProvider)
          .atualizarValorPago(ocorrenciaId, novoValor);
    }
  }
}

enum _Acao { marcarPaga, pular, editarValor }

// ---------------------------------------------------------------------------
// Dialogs como StatefulWidgets (controller gerenciado pelo State)
// ---------------------------------------------------------------------------

class _ResultadoMarcarPaga {
  const _ResultadoMarcarPaga({
    required this.valor,
    required this.dataPagamento,
  });

  final double valor;
  final DateTime dataPagamento;
}

class _EditarValorDialog extends StatefulWidget {
  const _EditarValorDialog({required this.valorInicial});

  final double valorInicial;

  @override
  State<_EditarValorDialog> createState() => _EditarValorDialogState();
}

class _EditarValorDialogState extends State<_EditarValorDialog> {
  late final TextEditingController _valorCtrl;

  @override
  void initState() {
    super.initState();
    _valorCtrl = TextEditingController(
      text: widget.valorInicial.toStringAsFixed(2).replaceAll('.', ','),
    );
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.ocorrenciaDialogEditarValorTitulo),
      content: TextField(
        controller: _valorCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: l10n.ocorrenciaDialogCampoValor),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.ocorrenciaDialogCancelar),
        ),
        FilledButton(
          onPressed: () {
            final valorStr = _valorCtrl.text.replaceAll(',', '.');
            final valor = double.tryParse(valorStr) ?? widget.valorInicial;
            Navigator.of(context).pop(valor);
          },
          child: Text(l10n.ocorrenciaDialogConfirmar),
        ),
      ],
    );
  }
}

class _MarcarPagaDialog extends StatefulWidget {
  const _MarcarPagaDialog({required this.valorDefault});

  final double valorDefault;

  @override
  State<_MarcarPagaDialog> createState() => _MarcarPagaDialogState();
}

class _MarcarPagaDialogState extends State<_MarcarPagaDialog> {
  late final TextEditingController _valorCtrl;
  DateTime _dataPagamento = DateTime.now();

  @override
  void initState() {
    super.initState();
    _valorCtrl = TextEditingController(
      text: widget.valorDefault.toStringAsFixed(2).replaceAll('.', ','),
    );
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.ocorrenciaDialogMarcarPagaTitulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _valorCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.ocorrenciaDialogCampoValor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.ocorrenciaDialogCampoData}: ${_fmtData(_dataPagamento)}',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dataPagamento,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _dataPagamento = picked);
                  }
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.ocorrenciaDialogCancelar),
        ),
        FilledButton(
          onPressed: () {
            final valorStr = _valorCtrl.text.replaceAll(',', '.');
            final valor = double.tryParse(valorStr) ?? widget.valorDefault;
            Navigator.of(context).pop(
              _ResultadoMarcarPaga(valor: valor, dataPagamento: _dataPagamento),
            );
          },
          child: Text(l10n.ocorrenciaDialogConfirmar),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Estados especiais
// ---------------------------------------------------------------------------

class _SemVeiculo extends StatelessWidget {
  const _SemVeiculo({required this.l10n});

  final AppLocalizations l10n;

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
            Text(l10n.semVeiculoCadastrarDespesa, textAlign: TextAlign.center),
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
  const _ListaVazia({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 48),
            const SizedBox(height: 12),
            Text(l10n.despesasListVazia, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/despesas/novo'),
              icon: const Icon(Icons.add),
              label: Text(l10n.despesasListFab),
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

String _fmtData(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
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
