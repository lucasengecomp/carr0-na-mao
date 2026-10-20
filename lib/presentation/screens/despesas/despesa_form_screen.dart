import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/enums.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../veiculos/veiculos_providers.dart';
import 'enum_labels.dart';

/// Formulário de criação/edição de [DespesaRecorrente].
///
/// Em modo novo usa o veículo ativo; em modo edição carrega pelo [id].
/// No submit salva a despesa e materializa as ocorrências até o fim do
/// mês corrente.
class DespesaFormScreen extends ConsumerStatefulWidget {
  const DespesaFormScreen({this.id, super.key});

  final int? id;

  @override
  ConsumerState<DespesaFormScreen> createState() => _DespesaFormScreenState();
}

class _DespesaFormScreenState extends ConsumerState<DespesaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _diaCtrl = TextEditingController();

  CategoriaDespesa _categoria = CategoriaDespesa.outra;
  FrequenciaDespesa _frequencia = FrequenciaDespesa.mensal;
  DateTime _dataInicio = DateTime.now();
  DateTime? _dataFim;
  bool _ativa = true;
  bool _saving = false;

  /// Veículo em modo edição (carregado assincronamente).
  Veiculo? _veiculoEdit;

  bool get _isEdit => widget.id != null;

  /// Frequências que exigem exibição do campo "Dia do mês".
  bool get _mostrarDiaMes =>
      _frequencia == FrequenciaDespesa.mensal ||
      _frequencia == FrequenciaDespesa.anual;

  @override
  void initState() {
    super.initState();
    if (_isEdit) unawaited(_loadExisting());
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _valorCtrl.dispose();
    _diaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final dao = ref.read(despesasRecorrentesDaoProvider);
    final d = await dao.byId(widget.id!);
    if (d == null || !mounted) return;
    final veiculo = await ref.read(veiculosDaoProvider).byPlaca(d.veiculoPlaca);
    if (!mounted) return;
    setState(() {
      _veiculoEdit = veiculo;
      _nomeCtrl.text = d.nome;
      _valorCtrl.text = _fmtNumber(d.valor);
      _categoria = d.categoria;
      _frequencia = d.frequencia;
      _diaCtrl.text = d.diaDoMes?.toString() ?? '';
      _dataInicio = d.dataInicio;
      _dataFim = d.dataFim;
      _ativa = d.ativa;
    });
  }

  Future<void> _escolherDataInicio() async {
    final hoje = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _dataInicio,
      firstDate: DateTime(hoje.year - 10),
      lastDate: DateTime(hoje.year + 10),
    );
    if (escolhida != null) {
      setState(() {
        _dataInicio = escolhida;
        // Reseta dataFim se ficou antes de dataInicio.
        if (_dataFim != null && _dataFim!.isBefore(_dataInicio)) {
          _dataFim = null;
        }
      });
    }
  }

  Future<void> _escolherDataFim() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _dataFim ?? _dataInicio,
      firstDate: _dataInicio,
      lastDate: DateTime(_dataInicio.year + 20),
    );
    if (escolhida != null) {
      setState(() => _dataFim = escolhida);
    }
  }

  Future<void> _submit(Veiculo veiculo) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final valor = _parseDecimal(_valorCtrl.text) ?? 0;
      final diaRaw = int.tryParse(_diaCtrl.text.trim());
      final dia = _mostrarDiaMes ? diaRaw : null;

      final despesasDao = ref.read(despesasRecorrentesDaoProvider);
      final ocorrenciasDao = ref.read(ocorrenciasDespesaDaoProvider);

      late DespesaRecorrente despesaSalva;

      if (_isEdit) {
        final atual = await despesasDao.byId(widget.id!);
        if (atual == null) return;
        final atualizado = atual.copyWith(
          nome: _nomeCtrl.text.trim(),
          categoria: _categoria,
          valor: valor,
          frequencia: _frequencia,
          diaDoMes: Value(dia),
          dataInicio: _dataInicio,
          dataFim: Value(_dataFim),
          ativa: _ativa,
        );
        await despesasDao.updateDespesa(atualizado);
        despesaSalva = atualizado;
      } else {
        final id = await despesasDao.insertDespesa(
          DespesasRecorrentesCompanion.insert(
            veiculoPlaca: veiculo.placa,
            nome: _nomeCtrl.text.trim(),
            categoria: _categoria,
            valor: valor,
            frequencia: _frequencia,
            diaDoMes: Value(dia),
            dataInicio: _dataInicio,
            dataFim: Value(_dataFim),
            ativa: Value(_ativa),
          ),
        );
        final nova = await despesasDao.byId(id);
        if (nova == null) return;
        despesaSalva = nova;
      }

      // Materializa ocorrências até o fim do mês corrente (idempotente).
      if (despesaSalva.ativa) {
        await ocorrenciasDao.materializar(despesaSalva);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.despesaNaoPossivel(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validateNome(String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.trim().isEmpty) return l10n.validacaoObrigatorio;
    return null;
  }

  String? _validateValor(String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.isEmpty) return l10n.validacaoObrigatorio;
    final n = _parseDecimal(v);
    if (n == null || n < 0) return l10n.validacaoValorInvalido;
    return null;
  }

  String? _validateDia(String? v) {
    if (!_mostrarDiaMes) return null;
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.isEmpty) return l10n.validacaoObrigatorio;
    final n = int.tryParse(v);
    if (n == null || n < 1 || n > 28) return l10n.validacaoDiaDoMesInvalido;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? l10n.despesaEditarTitulo : l10n.despesaNovoTitulo,
        ),
      ),
      body: _isEdit ? _buildEditBody() : _buildNewBody(),
    );
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

            // Nome
            TextFormField(
              key: const Key('despesa_nome'),
              controller: _nomeCtrl,
              decoration: InputDecoration(labelText: l10n.despesaCampoNome),
              textCapitalization: TextCapitalization.sentences,
              validator: _validateNome,
            ),
            const SizedBox(height: 12),

            // Categoria
            DropdownButtonFormField<CategoriaDespesa>(
              initialValue: _categoria,
              decoration: InputDecoration(
                labelText: l10n.despesaCampoCategoria,
              ),
              onChanged: (v) => setState(() => _categoria = v!),
              items: [
                for (final c in CategoriaDespesa.values)
                  DropdownMenuItem(value: c, child: Text(c.label(l10n))),
              ],
            ),
            const SizedBox(height: 12),

            // Valor
            TextFormField(
              key: const Key('despesa_valor'),
              controller: _valorCtrl,
              decoration: InputDecoration(
                labelText: l10n.despesaCampoValor,
                prefixText: r'R$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [_DecimalFormatter()],
              validator: _validateValor,
            ),
            const SizedBox(height: 12),

            // Frequência
            DropdownButtonFormField<FrequenciaDespesa>(
              initialValue: _frequencia,
              decoration: InputDecoration(
                labelText: l10n.despesaCampoFrequencia,
              ),
              onChanged: (v) => setState(() {
                _frequencia = v!;
                if (!_mostrarDiaMes) _diaCtrl.clear();
              }),
              items: [
                for (final f in FrequenciaDespesa.values)
                  DropdownMenuItem(value: f, child: Text(f.label(l10n))),
              ],
            ),
            const SizedBox(height: 12),

            // Dia do mês (apenas mensal/anual)
            if (_mostrarDiaMes) ...[
              TextFormField(
                key: const Key('despesa_dia'),
                controller: _diaCtrl,
                decoration: InputDecoration(
                  labelText: l10n.despesaCampoDiaDoMes,
                  helperText: l10n.despesaCampoDiaDoMesHelper,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _validateDia,
              ),
              const SizedBox(height: 12),
            ],

            // Data de início
            Semantics(
              label: '${l10n.despesaCampoDataInicio}: ${_fmtData(_dataInicio)}',
              hint: l10n.a11yToquePAraAbrir,
              button: true,
              child: InkWell(
                onTap: () => unawaited(_escolherDataInicio()),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.despesaCampoDataInicio,
                  ),
                  child: Text(_fmtData(_dataInicio)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Data de fim (opcional)
            Semantics(
              label:
                  '${l10n.despesaCampoDataFim}: ${_dataFim != null ? _fmtData(_dataFim!) : l10n.despesaDataFimVazia}',
              hint: l10n.a11yToquePAraAbrir,
              button: true,
              child: InkWell(
                onTap: () => unawaited(_escolherDataFim()),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.despesaCampoDataFim,
                    suffixIcon: _dataFim != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: l10n.despesaLimparDataFim,
                            onPressed: () => setState(() => _dataFim = null),
                          )
                        : null,
                  ),
                  child: Text(
                    _dataFim != null
                        ? _fmtData(_dataFim!)
                        : l10n.despesaDataFimVazia,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Ativa
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.despesaCampoAtiva),
              subtitle: Text(l10n.despesaCampoAtivaSubtitulo),
              value: _ativa,
              onChanged: (v) => setState(() => _ativa = v),
            ),
            const SizedBox(height: 24),

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
            const Icon(Icons.directions_car_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              l10n.semVeiculoCadastrarDespesaForm,
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

String _fmtNumber(double n) {
  final s = n.toStringAsFixed(2);
  var trimmed = s;
  if (trimmed.contains('.')) {
    trimmed = trimmed.replaceFirst(RegExp(r'0+$'), '');
    trimmed = trimmed.replaceFirst(RegExp(r'\.$'), '');
  }
  return trimmed.replaceAll('.', ',');
}

String _fmtData(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}
