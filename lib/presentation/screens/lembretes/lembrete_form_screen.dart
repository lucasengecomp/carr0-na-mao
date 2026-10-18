import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/lembretes_service.dart';
import '../veiculos/veiculos_providers.dart';

/// Tipo usado em lembretes avulsos (sem vínculo a uma manutenção).
const _kTipoAvulso = 'avulso';

/// Formulário de criação (e futuramente edição) de lembrete avulso.
///
/// - Modo novo: [id] == null, veículo padrão vem de [veiculoAtivoProvider].
/// - Modo edição: [id] != null — reservado para uso futuro, não exposto
///   pela issue #27.
///
/// Critérios de aceite (RF-16 / issue #27):
///  - descricao obrigatória, mín. 2 chars.
///  - Ao menos um entre [dataAlvo] e [kmAlvo] preenchido.
///  - Dropdown de veículo com default = ativo.
///  - Chama [LembretesService.insertLembrete] com tipo='avulso',
///    manutencaoId=null, status=pendente.
class LembreteFormScreen extends ConsumerStatefulWidget {
  const LembreteFormScreen({this.id, super.key});

  final int? id;

  @override
  ConsumerState<LembreteFormScreen> createState() => _LembreteFormScreenState();
}

class _LembreteFormScreenState extends ConsumerState<LembreteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoCtrl = TextEditingController();
  final _kmAlvoCtrl = TextEditingController();

  DateTime? _dataAlvo;
  Veiculo? _veiculoSelecionado;
  bool _saving = false;

  // Erro de validação cruzada (data e km ambos vazios).
  bool _erroCamposAlvo = false;

  bool get _isEdit => widget.id != null;

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    _kmAlvoCtrl.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final hoje = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _dataAlvo ?? hoje,
      firstDate: hoje,
      lastDate: DateTime(hoje.year + 10),
    );
    if (escolhida != null) {
      setState(() {
        _dataAlvo = escolhida;
        _erroCamposAlvo = false;
      });
    }
  }

  bool _validarCamposAlvo() {
    final kmTxt = _kmAlvoCtrl.text.trim();
    final temData = _dataAlvo != null;
    final temKm = kmTxt.isNotEmpty && int.tryParse(kmTxt) != null;
    return temData || temKm;
  }

  Future<void> _submit(Veiculo veiculo) async {
    // Valida o form (campos individuais).
    final formValido = _formKey.currentState!.validate();
    // Valida a regra "ao menos data ou km".
    final alvoValido = _validarCamposAlvo();

    setState(() => _erroCamposAlvo = !alvoValido);

    if (!formValido || !alvoValido) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    try {
      final kmTxt = _kmAlvoCtrl.text.trim();
      final kmAlvo = kmTxt.isNotEmpty ? int.tryParse(kmTxt) : null;

      await ref
          .read(lembretesServiceProvider)
          .insertLembrete(
            LembretesCompanion.insert(
              veiculoPlaca: veiculo.placa,
              tipo: _kTipoAvulso,
              descricao: _descricaoCtrl.text.trim(),
              dataAlvo: Value(_dataAlvo),
              kmAlvo: Value(kmAlvo),
              status: StatusLembrete.pendente,
            ),
          );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.lembreteFormNaoPossivel(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validateDescricao(String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.trim().isEmpty) return l10n.validacaoObrigatorio;
    if (v.trim().length < 2) return l10n.lembreteFormValidacaoDescricaoMin;
    return null;
  }

  String? _validateKmAlvo(String? v) {
    if (v == null || v.isEmpty) return null;
    final km = int.tryParse(v);
    if (km == null || km <= 0) {
      return AppLocalizations.of(context)!.validacaoKmInvalido;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? l10n.lembreteFormEditarTitulo : l10n.lembreteFormNovoTitulo,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
    final ativos = ref.watch(veiculosAtivosProvider);

    return ativos.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.erroGenerico(e.toString()))),
      data: (List<Veiculo> lista) {
        if (lista.isEmpty) return const _AvisoSemVeiculo();

        // Inicializa o veículo selecionado com o ativo se ainda não definido.
        final veiculoAtivo = ref.watch(veiculoAtivoProvider);
        _veiculoSelecionado ??= veiculoAtivo;

        return _buildForm(lista);
      },
    );
  }

  Widget _buildForm(List<Veiculo> veiculos) {
    final l10n = AppLocalizations.of(context)!;
    final veiculo = _veiculoSelecionado;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dropdown de veículo
            DropdownButtonFormField<Veiculo>(
              key: const Key('lembrete_veiculo'),
              initialValue: veiculo,
              decoration: InputDecoration(
                labelText: l10n.lembreteFormCampoVeiculo,
              ),
              onChanged: (v) {
                if (v != null) setState(() => _veiculoSelecionado = v);
              },
              items: [
                for (final v in veiculos)
                  DropdownMenuItem(
                    value: v,
                    child: Text(
                      _veiculoLabel(v),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Descrição
            TextFormField(
              key: const Key('lembrete_descricao'),
              controller: _descricaoCtrl,
              decoration: InputDecoration(
                labelText: l10n.lembreteFormCampoDescricao,
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: _validateDescricao,
            ),
            const SizedBox(height: 12),

            // Data alvo (opcional)
            InkWell(
              onTap: () => unawaited(_escolherData()),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.lembreteFormCampoDataAlvo,
                  suffixIcon: _dataAlvo != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: l10n.lembreteFormLimparDataAlvo,
                          onPressed: () => setState(() {
                            _dataAlvo = null;
                          }),
                        )
                      : null,
                ),
                child: Text(
                  _dataAlvo != null
                      ? _fmtData(_dataAlvo!)
                      : l10n.lembreteFormSemDataAlvo,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Km alvo (opcional)
            TextFormField(
              key: const Key('lembrete_km_alvo'),
              controller: _kmAlvoCtrl,
              decoration: InputDecoration(
                labelText: l10n.lembreteFormCampoKmAlvo,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _validateKmAlvo,
              onChanged: (_) {
                if (_erroCamposAlvo) {
                  setState(() => _erroCamposAlvo = false);
                }
              },
            ),

            // Erro cruzado: nenhum alvo definido
            if (_erroCamposAlvo) ...[
              const SizedBox(height: 8),
              Text(
                l10n.lembreteFormValidacaoDataOuKm,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ],

            const SizedBox(height: 24),

            FilledButton(
              onPressed: (_saving || veiculo == null)
                  ? null
                  : () => unawaited(_submit(veiculo)),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.botaoSalvar),
            ),
          ],
        ),
      ),
    );
  }

  String _veiculoLabel(Veiculo v) {
    final apelido = v.apelido;
    if (apelido != null && apelido.isNotEmpty) {
      return '$apelido · ${v.placa}';
    }
    return '${v.marca} ${v.modelo} · ${v.placa}';
  }
}

// ---------------------------------------------------------------------------
// Aviso sem veículo
// ---------------------------------------------------------------------------

class _AvisoSemVeiculo extends StatelessWidget {
  const _AvisoSemVeiculo();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.semVeiculoCadastrarLembreteForm,
              textAlign: TextAlign.center,
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
