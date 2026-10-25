import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/enums.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/lembretes_service.dart';
import '../../../services/manutencoes_service.dart';
import '../veiculos/veiculos_providers.dart';
import 'manutencao_enum_labels.dart';

/// Form de manutenção. Em modo novo, usa o veículo ativo; em modo edição,
/// carrega o registro pelo id e trava o veículo.
///
/// Quando aberto a partir de um lembrete com `manutencao_id` (RF-17), aceita
/// parâmetros opcionais de pré-preenchimento:
/// - [tipoSugerido]: nome do enum [TipoManutencao] (ex: `"pastilhasFreio"`).
/// - [kmSugerido]: hodômetro alvo do lembrete.
/// - [placaSugerida]: placa do veículo do lembrete.
class ManutencaoFormScreen extends ConsumerStatefulWidget {
  const ManutencaoFormScreen({
    this.id,
    this.tipoSugerido,
    this.kmSugerido,
    this.placaSugerida,
    super.key,
  });

  final int? id;

  /// Nome do enum [TipoManutencao] a pré-selecionar em modo novo.
  final String? tipoSugerido;

  /// Valor de hodômetro a pré-preencher em modo novo.
  final int? kmSugerido;

  /// Placa do veículo a usar como ativo em modo novo (quando diferente do
  /// veículo selecionado pelo usuário).
  final String? placaSugerida;

  @override
  ConsumerState<ManutencaoFormScreen> createState() =>
      _ManutencaoFormScreenState();
}

class _ManutencaoFormScreenState extends ConsumerState<ManutencaoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kmCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _oficinaCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();
  final _nomeLivreCtrl = TextEditingController();
  final _proximoKmCtrl = TextEditingController();
  final _proximoMesesCtrl = TextEditingController();

  DateTime _data = DateTime.now();
  TipoManutencao _tipo = TipoManutencao.oleoMotor;
  bool _saving = false;
  bool _carregandoPadrao = false;

  /// Veículo em modo edição. Em modo novo, vem do [veiculoAtivoProvider].
  Veiculo? _veiculoEdit;

  /// Veículo pré-selecionado via [widget.placaSugerida] (modo novo).
  /// Quando não nulo, substitui o [veiculoAtivoProvider] no formulário.
  Veiculo? _veiculoPrefill;

  bool get _isEdit => widget.id != null;

  /// Quando `true`, o campo `nomeLivre` fica visível.
  bool get _isOutros => _tipo == TipoManutencao.outros;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      unawaited(_loadExisting());
    } else {
      // Aplica pré-preenchimento vindo do lembrete (RF-17).
      _aplicarPrefill();
      // Pré-preenche os campos de próximo intervalo com o padrão do tipo.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_carregarPadrao(_tipo));
      });
    }
  }

  /// Aplica os parâmetros de pré-preenchimento vindos de [widget.tipoSugerido],
  /// [widget.kmSugerido] e [widget.placaSugerida] em modo novo.
  void _aplicarPrefill() {
    // Tipo: tenta mapear o nome do enum; ignora se inválido.
    final tipoStr = widget.tipoSugerido;
    if (tipoStr != null && tipoStr.isNotEmpty) {
      final tipoEncontrado = TipoManutencao.values
          .where((t) => t.name == tipoStr)
          .firstOrNull;
      if (tipoEncontrado != null) {
        _tipo = tipoEncontrado;
      }
    }

    // KM: preenche se positivo.
    final km = widget.kmSugerido;
    if (km != null && km > 0) {
      _kmCtrl.text = km.toString();
    }

    // Placa: carrega o veículo correspondente assíncronamente.
    final placa = widget.placaSugerida;
    if (placa != null && placa.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_carregarVeiculoPrefill(placa));
      });
    }
  }

  /// Carrega o veículo pela placa sugerida e o armazena em [_veiculoPrefill].
  Future<void> _carregarVeiculoPrefill(String placa) async {
    final veiculo = await ref.read(veiculosDaoProvider).byPlaca(placa);
    if (!mounted) return;
    setState(() => _veiculoPrefill = veiculo);
  }

  @override
  void dispose() {
    _kmCtrl.dispose();
    _valorCtrl.dispose();
    _oficinaCtrl.dispose();
    _observacoesCtrl.dispose();
    _nomeLivreCtrl.dispose();
    _proximoKmCtrl.dispose();
    _proximoMesesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final dao = ref.read(manutencoesDaoProvider);
    final m = await dao.byId(widget.id!);
    if (m == null || !mounted) return;
    final veiculo = await ref.read(veiculosDaoProvider).byPlaca(m.veiculoPlaca);
    if (!mounted) return;
    setState(() {
      _veiculoEdit = veiculo;
      _tipo = m.tipo;
      _data = m.data;
      _kmCtrl.text = m.km.toString();
      _valorCtrl.text = m.valor != null ? _fmtDecimal(m.valor!) : '';
      _oficinaCtrl.text = m.oficina ?? '';
      _observacoesCtrl.text = m.observacoes ?? '';
      _nomeLivreCtrl.text = m.nomeLivre ?? '';
    });
  }

  /// Carrega o padrão do tipo selecionado e pré-preenche os campos de
  /// próximo intervalo. Chamado após mudança no dropdown de tipo.
  Future<void> _carregarPadrao(TipoManutencao tipo) async {
    if (tipo == TipoManutencao.outros) {
      setState(() {
        _proximoKmCtrl.text = '';
        _proximoMesesCtrl.text = '';
      });
      return;
    }
    setState(() => _carregandoPadrao = true);
    try {
      final padrao = await ref
          .read(tiposManutencaoPadraoDaoProvider)
          .byTipo(tipo);
      if (!mounted) return;
      setState(() {
        _proximoKmCtrl.text = padrao?.intervaloKm != null
            ? padrao!.intervaloKm.toString()
            : '';
        _proximoMesesCtrl.text = padrao?.intervaloMeses != null
            ? padrao!.intervaloMeses.toString()
            : '';
      });
    } finally {
      if (mounted) setState(() => _carregandoPadrao = false);
    }
  }

  Future<void> _escolherData() async {
    final hoje = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(hoje.year - 10),
      lastDate: hoje,
    );
    if (escolhida != null) {
      setState(() => _data = escolhida);
    }
  }

  Future<void> _submit(Veiculo veiculo) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final kmTxt = _kmCtrl.text.trim();
      final km = int.parse(kmTxt);
      final valorTxt = _valorCtrl.text.trim();
      final valor = valorTxt.isNotEmpty ? _parseDecimal(valorTxt) : null;
      final oficinaTxt = _oficinaCtrl.text.trim();
      final observacoesTxt = _observacoesCtrl.text.trim();
      final nomeLivreTxt = _nomeLivreCtrl.text.trim();
      final dao = ref.read(manutencoesDaoProvider);
      int manutencaoId;
      if (_isEdit) {
        final atual = await dao.byId(widget.id!);
        if (atual == null) return;
        await dao.updateManutencao(
          atual.copyWith(
            tipo: _tipo,
            nomeLivre: Value(
              _isOutros && nomeLivreTxt.isNotEmpty ? nomeLivreTxt : null,
            ),
            data: _data,
            km: km,
            valor: Value(valor),
            oficina: Value(oficinaTxt.isNotEmpty ? oficinaTxt : null),
            observacoes: Value(
              observacoesTxt.isNotEmpty ? observacoesTxt : null,
            ),
          ),
        );
        manutencaoId = widget.id!;
      } else {
        manutencaoId = await dao.insertManutencao(
          ManutencoesCompanion.insert(
            veiculoPlaca: veiculo.placa,
            tipo: _tipo,
            nomeLivre: Value(
              _isOutros && nomeLivreTxt.isNotEmpty ? nomeLivreTxt : null,
            ),
            data: _data,
            km: km,
            valor: Value(valor),
            oficina: Value(oficinaTxt.isNotEmpty ? oficinaTxt : null),
            observacoes: Value(
              observacoesTxt.isNotEmpty ? observacoesTxt : null,
            ),
          ),
        );
      }

      // RF-14: criar/atualizar lembrete da próxima ocorrência (apenas para
      // tipos diferentes de "outros", que têm campos de próximo intervalo).
      if (!_isOutros) {
        final proximoKmTxt = _proximoKmCtrl.text.trim();
        final proximoMesesTxt = _proximoMesesCtrl.text.trim();
        final proximoKm = proximoKmTxt.isNotEmpty
            ? int.tryParse(proximoKmTxt)
            : null;
        final proximoMeses = proximoMesesTxt.isNotEmpty
            ? int.tryParse(proximoMesesTxt)
            : null;

        final kmAlvo = (proximoKm != null && proximoKm > 0)
            ? km + proximoKm
            : null;
        final dataAlvo = (proximoMeses != null && proximoMeses > 0)
            ? DateTime(_data.year, _data.month + proximoMeses, _data.day)
            : null;

        if (kmAlvo != null || dataAlvo != null) {
          await ref
              .read(lembretesServiceProvider)
              .upsertByManutencao(
                placa: veiculo.placa,
                manutencaoId: manutencaoId,
                tipo: _tipo.name,
                descricao: _tipo.label(l10n),
                dataAlvo: dataAlvo,
                kmAlvo: kmAlvo,
              );
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.manutencaoNaoPossivel(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validateKm(String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.isEmpty) return l10n.validacaoObrigatorio;
    final km = int.tryParse(v);
    if (km == null || km <= 0) return l10n.validacaoKmInvalido;
    return null;
  }

  String? _validateValorOpcional(String? v) {
    if (v == null || v.isEmpty) return null;
    final n = _parseDecimal(v);
    if (n == null || n < 0) {
      return AppLocalizations.of(context)!.validacaoValorInvalido;
    }
    return null;
  }

  String? _validateNomeLivre(String? v) {
    if (!_isOutros) return null;
    if (v == null || v.trim().isEmpty) {
      return AppLocalizations.of(context)!.validacaoObrigatorio;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? l10n.manutencaoEditarTitulo : l10n.manutencaoNovoTitulo,
        ),
        actions: [
          if (_isEdit)
            Semantics(
              label: l10n.manutencaoAcaoExcluir,
              button: true,
              child: IconButton(
                key: const Key('btn_excluir_manutencao_appbar'),
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.manutencaoAcaoExcluir,
                onPressed: () => unawaited(_excluir(context)),
              ),
            ),
        ],
      ),
      body: _isEdit ? _buildEditBody() : _buildNewBody(),
    );
  }

  Future<void> _excluir(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const _ExcluirManutencaoDialog(),
    );
    if (confirm != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final service = ref.read(manutencoesServiceProvider);
      await service.deleteManutencao(widget.id!);
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.manutencaoExcluida)));
      Navigator.of(context).pop();
    } on Object catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.manutencaoNaoPossivel(e.toString()))),
      );
    }
  }

  Widget _buildEditBody() {
    final veiculo = _veiculoEdit;
    if (veiculo == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return _buildForm(veiculo);
  }

  Widget _buildNewBody() {
    final l10n = AppLocalizations.of(context)!;

    // Quando há uma placa sugerida mas o veículo ainda não carregou, mostra
    // loading. Quando o veículo sugerido carregou, usa-o diretamente.
    if (widget.placaSugerida != null && widget.placaSugerida!.isNotEmpty) {
      final prefill = _veiculoPrefill;
      if (prefill == null) {
        // Ainda aguardando a carga do veículo sugerido.
        return const Center(child: CircularProgressIndicator());
      }
      return _buildForm(prefill);
    }

    final ativos = ref.watch(veiculosAtivosProvider);
    return ativos.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.erroGenerico(e.toString()))),
      data: (_) {
        final veiculo = ref.watch(veiculoAtivoProvider);
        if (veiculo == null) return const _AvisoSemVeiculo();
        return _buildForm(veiculo);
      },
    );
  }

  Widget _buildForm(Veiculo veiculo) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _VeiculoChip(veiculo: veiculo),
            const SizedBox(height: 16),
            // Tipo
            DropdownButtonFormField<TipoManutencao>(
              initialValue: _tipo,
              decoration: InputDecoration(labelText: l10n.manutencaoCampoTipo),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _tipo = v);
                unawaited(_carregarPadrao(v));
              },
              items: [
                for (final t in TipoManutencao.values)
                  DropdownMenuItem(value: t, child: Text(t.label(l10n))),
              ],
            ),
            // Nome livre — visível só quando tipo = outros
            if (_isOutros) ...[
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('manut_nome_livre'),
                controller: _nomeLivreCtrl,
                decoration: InputDecoration(
                  labelText: l10n.manutencaoCampoNomeLivre,
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: _validateNomeLivre,
              ),
            ],
            const SizedBox(height: 12),
            // Data
            Semantics(
              label: '${l10n.manutencaoCampoData}: ${_fmtData(_data)}',
              hint: l10n.a11yToquePAraAbrir,
              button: true,
              child: InkWell(
                onTap: () => unawaited(_escolherData()),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.manutencaoCampoData,
                  ),
                  child: Text(_fmtData(_data)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Km
            TextFormField(
              key: const Key('manut_km'),
              controller: _kmCtrl,
              decoration: InputDecoration(labelText: l10n.manutencaoCampoKm),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _validateKm,
            ),
            const SizedBox(height: 12),
            // Valor (opcional)
            TextFormField(
              key: const Key('manut_valor'),
              controller: _valorCtrl,
              decoration: InputDecoration(labelText: l10n.manutencaoCampoValor),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [_DecimalFormatter()],
              validator: _validateValorOpcional,
            ),
            const SizedBox(height: 12),
            // Oficina (opcional)
            TextFormField(
              key: const Key('manut_oficina'),
              controller: _oficinaCtrl,
              decoration: InputDecoration(
                labelText: l10n.manutencaoCampoOficina,
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            // Observações (opcional)
            TextFormField(
              key: const Key('manut_observacoes'),
              controller: _observacoesCtrl,
              decoration: InputDecoration(
                labelText: l10n.manutencaoCampoObservacoes,
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            // Seção de próximo intervalo (sugestão)
            if (!_isOutros) ...[
              _SectionHeader(title: l10n.manutencaoProximoIntervalo),
              const SizedBox(height: 8),
              if (_carregandoPadrao)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                )
              else ...[
                TextFormField(
                  key: const Key('manut_proximo_km'),
                  controller: _proximoKmCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.manutencaoCampoProximoKm,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('manut_proximo_meses'),
                  controller: _proximoMesesCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.manutencaoCampoProximoMeses,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            Semantics(
              label: _saving ? l10n.a11ySalvando : l10n.botaoSalvar,
              button: true,
              child: FilledButton(
                onPressed: _saving ? null : () => unawaited(_submit(veiculo)),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.botaoSalvar),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog de confirmação de exclusão (StatelessWidget local — padrão do app)
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
            const Icon(Icons.build_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              l10n.semVeiculoCadastrarManutencaoForm,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _VeiculoChip extends StatelessWidget {
  const _VeiculoChip({required this.veiculo});

  final Veiculo veiculo;

  @override
  Widget build(BuildContext context) {
    final apelido = veiculo.apelido;
    final titulo = (apelido != null && apelido.isNotEmpty)
        ? apelido
        : '${veiculo.marca} ${veiculo.modelo}';
    final icone = veiculo.tipo == TipoVeiculo.carro
        ? Icons.directions_car
        : Icons.two_wheeler;
    return Semantics(
      label: '$titulo · ${veiculo.placa}',
      child: Row(
        children: [
          ExcludeSemantics(child: Icon(icone, size: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: ExcludeSemantics(
              child: Text(
                '$titulo · ${veiculo.placa}',
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    );
  }
}

/// Aceita dígitos e um separador decimal (vírgula ou ponto).
class _DecimalFormatter extends TextInputFormatter {
  static final _permitido = RegExp(r'[0-9.,]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final buffer = StringBuffer();
    var jaTemSeparador = false;
    for (final c in newValue.text.characters) {
      if (!_permitido.hasMatch(c)) continue;
      if (c == ',' || c == '.') {
        if (jaTemSeparador) continue;
        jaTemSeparador = true;
        buffer.write(',');
      } else {
        buffer.write(c);
      }
    }
    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

double? _parseDecimal(String s) {
  if (s.isEmpty) return null;
  return double.tryParse(s.replaceAll(',', '.'));
}

String _fmtDecimal(double n) {
  final s = n.toStringAsFixed(2);
  return s.replaceAll('.', ',');
}

String _fmtData(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}
