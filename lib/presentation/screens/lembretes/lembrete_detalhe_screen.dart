import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/enums.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/lembretes_service.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Carrega um lembrete por id. Retorna null quando não existe.
final _lembreteByIdProvider = FutureProvider.autoDispose.family<Lembrete?, int>(
  (ref, id) {
    return ref.watch(lembretesDaoProvider).byId(id);
  },
);

// ---------------------------------------------------------------------------
// Tela principal
// ---------------------------------------------------------------------------

/// Tela de detalhe de lembrete (issue #26).
///
/// Exibe todos os campos do lembrete e oferece três ações:
///   - Concluir: marca como concluído; opcionalmente navega para criar
///     manutenção.
///   - Adiar: edita data_alvo e/ou km_alvo.
///   - Excluir: confirma e exclui; volta para /lembretes.
class LembreteDetalheScreen extends ConsumerWidget {
  const LembreteDetalheScreen({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(_lembreteByIdProvider(id));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.lembreteDetalheTitulo)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) =>
            Center(child: Text(l10n.erroGenerico(e.toString()))),
        data: (Lembrete? lembrete) {
          if (lembrete == null) {
            return Center(child: Text(l10n.lembreteDetalheNaoEncontrado));
          }
          return _LembreteDetalheBody(lembrete: lembrete);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Corpo com detalhes + ações
// ---------------------------------------------------------------------------

class _LembreteDetalheBody extends ConsumerWidget {
  const _LembreteDetalheBody({required this.lembrete});

  final Lembrete lembrete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final l = lembrete;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoCard(lembrete: l),
          const SizedBox(height: 24),
          // Ação: Concluir (só disponível quando pendente ou adiado)
          if (l.status != StatusLembrete.concluido) ...[
            FilledButton.icon(
              key: const Key('btn_concluir'),
              onPressed: () => _concluir(context, ref, l10n),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(l10n.lembreteDetalheAcaoConcluir),
            ),
            const SizedBox(height: 12),
          ],
          // Ação: Adiar (só disponível quando pendente ou adiado)
          if (l.status != StatusLembrete.concluido) ...[
            OutlinedButton.icon(
              key: const Key('btn_adiar'),
              onPressed: () => _adiar(context, ref, l10n),
              icon: const Icon(Icons.schedule),
              label: Text(l10n.lembreteDetalheAcaoAdiar),
            ),
            const SizedBox(height: 12),
          ],
          // Ação: Excluir (sempre disponível)
          OutlinedButton.icon(
            key: const Key('btn_excluir'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(
                color: Theme.of(context).colorScheme.error
                    .withValues(alpha: 0.5),
              ),
            ),
            onPressed: () => _excluir(context, ref, l10n),
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.lembreteDetalheAcaoExcluir),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Concluir
  // --------------------------------------------------------------------------

  Future<void> _concluir(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final result = await showDialog<_ConcluirResult>(
      context: context,
      builder: (_) => _ConcluirDialog(lembrete: lembrete),
    );
    if (result == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(lembretesServiceProvider).marcarConcluido(lembrete.id);
      // Invalida o provider para que o estado reflita a conclusão
      ref.invalidate(_lembreteByIdProvider(lembrete.id));

      if (!context.mounted) return;

      if (result == _ConcluirResult.registrarManutencao) {
        // Navega para o form de manutenção.
        // Decisão de implementação: o ManutencaoFormScreen atual não aceita
        // query params de pré-preenchimento. Navegar para /manutencoes/novo
        // abre o form vazio para o usuário preencher. O fluxo completo de
        // pré-preenchimento requer alteração do ManutencaoFormScreen (RF-17
        // completo) e está fora do escopo desta issue.
        unawaited(context.push('/manutencoes/novo'));
      } else {
        // Apenas confirma e volta para a lista
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.lembreteDetalheConcluido)),
        );
        context.pop();
      }
    } on Object catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.lembreteDetalheErroAcao(e.toString()))),
      );
    }
  }

  // --------------------------------------------------------------------------
  // Adiar
  // --------------------------------------------------------------------------

  Future<void> _adiar(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final result = await showDialog<_AdiarResult>(
      context: context,
      builder: (_) => _AdiarDialog(lembrete: lembrete),
    );
    if (result == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(lembretesServiceProvider)
          .adiar(lembrete.id, novaData: result.novaData, novoKm: result.novoKm);
      ref.invalidate(_lembreteByIdProvider(lembrete.id));

      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.lembreteDetalheAdiado)),
      );
      context.pop();
    } on Object catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.lembreteDetalheErroAcao(e.toString()))),
      );
    }
  }

  // --------------------------------------------------------------------------
  // Excluir
  // --------------------------------------------------------------------------

  Future<void> _excluir(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const _ExcluirDialog(),
    );
    if (confirm != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(lembretesServiceProvider).deleteById(lembrete.id);
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.lembreteDetalheExcluido)),
      );
      context.pop();
    } on Object catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.lembreteDetalheErroAcao(e.toString()))),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Card de informações
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.lembrete});

  final Lembrete lembrete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final l = lembrete;

    final badgeColor = _badgeColor(context, l.status);
    final badgeLabel = _badgeLabel(l10n, l.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge de status no topo
            Align(
              alignment: Alignment.centerRight,
              child: _StatusBadge(label: badgeLabel, color: badgeColor),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: l10n.lembreteDetalheCampoDescricao,
              value: l.descricao,
            ),
            _InfoRow(
              label: l10n.lembreteDetalheCampoVeiculo,
              value: l.veiculoPlaca,
            ),
            _InfoRow(label: l10n.lembreteDetalheCampoTipo, value: l.tipo),
            _InfoRow(
              label: l10n.lembreteDetalheCampoDataAlvo,
              value: l.dataAlvo != null
                  ? _fmtData(l.dataAlvo!)
                  : l10n.lembreteDetalheSemData,
            ),
            _InfoRow(
              label: l10n.lembreteDetalheCampoKmAlvo,
              value: l.kmAlvo != null
                  ? '${_fmtKm(l.kmAlvo!)} km'
                  : l10n.lembreteDetalheSemKm,
            ),
            _InfoRow(
              label: l10n.lembreteDetalheCampoManutencao,
              value: l.manutencaoId != null
                  ? l10n.lembreteDetalheManutencaoId(l.manutencaoId!)
                  : l10n.lembreteDetalheSemManutencao,
            ),
          ],
        ),
      ),
    );
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

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
// Dialog: Concluir
// ---------------------------------------------------------------------------

enum _ConcluirResult { concluir, registrarManutencao }

class _ConcluirDialog extends StatelessWidget {
  const _ConcluirDialog({required this.lembrete});

  final Lembrete lembrete;

  /// Oferece a opção de registrar manutenção quando o lembrete tem
  /// manutencaoId preenchido (RF-17).
  bool get _temTipoManutencao => lembrete.manutencaoId != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.lembreteDetalheConcluirTitulo),
      content: Text(l10n.lembreteDetalheConcluirMensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.botaoCancelar),
        ),
        if (_temTipoManutencao)
          TextButton(
            key: const Key('btn_concluir_registrar_manutencao'),
            onPressed: () =>
                Navigator.of(context).pop(_ConcluirResult.registrarManutencao),
            child: Text(l10n.lembreteDetalheConcluirRegistrarManutencao),
          ),
        FilledButton(
          key: const Key('btn_concluir_confirmar'),
          onPressed: () => Navigator.of(context).pop(_ConcluirResult.concluir),
          child: Text(l10n.botaoConfirmar),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog: Adiar
// ---------------------------------------------------------------------------

class _AdiarResult {
  const _AdiarResult({this.novaData, this.novoKm});

  final DateTime? novaData;
  final int? novoKm;
}

/// Dialog de adiamento. É um StatefulWidget local para isolar os controllers
/// e evitar o bug de dispose prematuro (#62).
class _AdiarDialog extends StatefulWidget {
  const _AdiarDialog({required this.lembrete});

  final Lembrete lembrete;

  @override
  State<_AdiarDialog> createState() => _AdiarDialogState();
}

class _AdiarDialogState extends State<_AdiarDialog> {
  final _kmCtrl = TextEditingController();
  DateTime? _novaData;
  String? _erroValidacao;

  @override
  void initState() {
    super.initState();
    // Pré-preenche com os valores atuais do lembrete
    _novaData = widget.lembrete.dataAlvo;
    if (widget.lembrete.kmAlvo != null) {
      _kmCtrl.text = widget.lembrete.kmAlvo.toString();
    }
  }

  @override
  void dispose() {
    _kmCtrl.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final hoje = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _novaData ?? hoje,
      firstDate: hoje,
      lastDate: DateTime(hoje.year + 10),
    );
    if (escolhida != null) {
      setState(() => _novaData = escolhida);
    }
  }

  void _confirmar() {
    final l10n = AppLocalizations.of(context)!;
    final kmTxt = _kmCtrl.text.trim();
    final novoKm = kmTxt.isNotEmpty ? int.tryParse(kmTxt) : null;

    if (_novaData == null && novoKm == null) {
      setState(() => _erroValidacao = l10n.lembreteDetalheAdiarSemCampos);
      return;
    }

    Navigator.of(context)
        .pop(_AdiarResult(novaData: _novaData, novoKm: novoKm));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.lembreteDetalheAdiarTitulo),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Data alvo
            InkWell(
              key: const Key('adiar_data_picker'),
              onTap: () => unawaited(_escolherData()),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.lembreteDetalheAdiarDataAlvo,
                  suffixIcon: const Icon(Icons.calendar_today, size: 18),
                ),
                child: Text(
                  _novaData != null
                      ? _fmtData(_novaData!)
                      : l10n.lembreteDetalheSemData,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Km alvo
            TextFormField(
              key: const Key('adiar_km_field'),
              controller: _kmCtrl,
              decoration: InputDecoration(
                labelText: l10n.lembreteDetalheAdiarKmAlvo,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            if (_erroValidacao != null) ...[
              const SizedBox(height: 8),
              Text(
                _erroValidacao!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.botaoCancelar),
        ),
        FilledButton(
          key: const Key('btn_adiar_confirmar'),
          onPressed: _confirmar,
          child: Text(l10n.botaoConfirmar),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog: Excluir
// ---------------------------------------------------------------------------

class _ExcluirDialog extends StatelessWidget {
  const _ExcluirDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.lembreteDetalheExcluirTitulo),
      content: Text(l10n.lembreteDetalheExcluirMensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.botaoCancelar),
        ),
        FilledButton(
          key: const Key('btn_excluir_confirmar'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.lembreteDetalheAcaoExcluir),
        ),
      ],
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
