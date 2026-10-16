import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/enums.dart';
import '../../../data/providers.dart';
import '../veiculos/veiculos_providers.dart';
import 'enum_labels.dart';

/// Form de abastecimento. Em modo novo, usa o veículo ativo da Home; em modo
/// edição, carrega o abastecimento pelo id e trava o veículo.
class AbastecimentoFormScreen extends ConsumerStatefulWidget {
  const AbastecimentoFormScreen({this.id, super.key});

  final int? id;

  @override
  ConsumerState<AbastecimentoFormScreen> createState() =>
      _AbastecimentoFormScreenState();
}

class _AbastecimentoFormScreenState
    extends ConsumerState<AbastecimentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kmCtrl = TextEditingController();
  final _precoCtrl = TextEditingController();
  final _litrosCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _postoCtrl = TextEditingController();

  DateTime _data = DateTime.now();
  TipoCombustivelAbastecimento? _combustivel;
  bool _tanqueCheio = true;
  bool _saving = false;

  /// Veículo em modo edição (carregado pelo id). Em modo novo, o veículo
  /// vem reativamente do [veiculoAtivoProvider] no build.
  Veiculo? _veiculoEdit;

  bool get _isEdit => widget.id != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) unawaited(_loadExisting());
  }

  @override
  void dispose() {
    _kmCtrl.dispose();
    _precoCtrl.dispose();
    _litrosCtrl.dispose();
    _valorCtrl.dispose();
    _postoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final dao = ref.read(abastecimentosDaoProvider);
    final a = await dao.byId(widget.id!);
    if (a == null || !mounted) return;
    final veiculo = await ref.read(veiculosDaoProvider).byPlaca(a.veiculoPlaca);
    if (!mounted) return;
    setState(() {
      _veiculoEdit = veiculo;
      _data = a.data;
      _combustivel = a.tipoCombustivel;
      _tanqueCheio = a.tanqueCheio;
      _kmCtrl.text = a.km.toString();
      _precoCtrl.text = _fmtNumber(a.precoLitro);
      _litrosCtrl.text = _fmtNumber(a.litros);
      _valorCtrl.text = _fmtNumber(a.valorTotal);
      _postoCtrl.text = a.posto ?? '';
    });
  }

  /// Preenchimento automático do terceiro campo quando os outros 2 têm valor
  /// numérico válido. Só preenche o que estiver vazio — se o usuário já
  /// escreveu nos 3, respeita.
  void _recalcular(_CampoCalculo editado) {
    final preco = _parseDecimal(_precoCtrl.text);
    final litros = _parseDecimal(_litrosCtrl.text);
    final valor = _parseDecimal(_valorCtrl.text);

    switch (editado) {
      case _CampoCalculo.preco:
        if (preco != null && litros != null && _valorCtrl.text.isEmpty) {
          _valorCtrl.text = _fmtNumber(preco * litros);
        } else if (preco != null && valor != null && _litrosCtrl.text.isEmpty) {
          _litrosCtrl.text = _fmtNumber(valor / preco);
        }
      case _CampoCalculo.litros:
        if (preco != null && litros != null && _valorCtrl.text.isEmpty) {
          _valorCtrl.text = _fmtNumber(preco * litros);
        } else if (litros != null && valor != null && _precoCtrl.text.isEmpty) {
          _precoCtrl.text = _fmtNumber(valor / litros);
        }
      case _CampoCalculo.valor:
        if (valor != null && preco != null && _litrosCtrl.text.isEmpty) {
          _litrosCtrl.text = _fmtNumber(valor / preco);
        } else if (valor != null && litros != null && _precoCtrl.text.isEmpty) {
          _precoCtrl.text = _fmtNumber(valor / litros);
        }
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
    try {
      final preco = _parseDecimal(_precoCtrl.text)!;
      final litros = _parseDecimal(_litrosCtrl.text)!;
      final valor = _parseDecimal(_valorCtrl.text)!;
      final postoTxt = _postoCtrl.text.trim();
      final dao = ref.read(abastecimentosDaoProvider);
      if (_isEdit) {
        final atual = await dao.byId(widget.id!);
        if (atual == null) return;
        await dao.updateAbastecimento(
          atual.copyWith(
            data: _data,
            km: int.parse(_kmCtrl.text),
            tipoCombustivel: _combustivel!,
            precoLitro: preco,
            litros: litros,
            valorTotal: valor,
            posto: Value(postoTxt.isEmpty ? null : postoTxt),
            tanqueCheio: _tanqueCheio,
          ),
        );
      } else {
        await dao.insertAbastecimento(
          AbastecimentosCompanion.insert(
            veiculoPlaca: veiculo.placa,
            data: _data,
            km: int.parse(_kmCtrl.text),
            tipoCombustivel: _combustivel!,
            precoLitro: preco,
            valorTotal: valor,
            litros: litros,
            posto: Value(postoTxt.isEmpty ? null : postoTxt),
            tanqueCheio: Value(_tanqueCheio),
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Não foi possível salvar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validateKm(String? v) {
    if (v == null || v.isEmpty) return 'Obrigatório';
    final km = int.tryParse(v);
    if (km == null || km < 0) return 'Km inválido';
    return null;
  }

  String? _validateDecimal(String? v) {
    if (v == null || v.isEmpty) return 'Preencha 2 dos 3 campos';
    final n = _parseDecimal(v);
    if (n == null || n <= 0) return 'Valor inválido';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar abastecimento' : 'Novo abastecimento'),
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
    // Aguarda o stream do Drift resolver para distinguir "ainda carregando"
    // de "não há veículo cadastrado".
    final ativos = ref.watch(veiculosAtivosProvider);
    return ativos.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (_) {
        final veiculo = ref.watch(veiculoAtivoProvider);
        if (veiculo == null) return const _AvisoSemVeiculo();
        _combustivel ??= combustiveisParaVeiculo(veiculo.combustivel).first;
        return _buildForm(veiculo);
      },
    );
  }

  Widget _buildForm(Veiculo veiculo) {
    final combustiveis = combustiveisParaVeiculo(veiculo.combustivel);
    final combustivelSelecionado =
        _combustivel != null && combustiveis.contains(_combustivel)
        ? _combustivel
        : combustiveis.first;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _VeiculoChip(veiculo: veiculo),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => unawaited(_escolherData()),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Data'),
                child: Text(_fmtData(_data)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('abast_km'),
              controller: _kmCtrl,
              decoration: const InputDecoration(labelText: 'Hodômetro (km)'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _validateKm,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TipoCombustivelAbastecimento>(
              initialValue: combustivelSelecionado,
              decoration: const InputDecoration(labelText: 'Combustível'),
              onChanged: (v) => setState(() => _combustivel = v),
              items: [
                for (final c in combustiveis)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('abast_preco'),
              controller: _precoCtrl,
              decoration: const InputDecoration(
                labelText: 'Preço por litro (R\$)',
                helperText: 'Preencha 2 dos 3 e o terceiro é calculado.',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [_DecimalFormatter()],
              validator: _validateDecimal,
              onChanged: (_) => _recalcular(_CampoCalculo.preco),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('abast_litros'),
              controller: _litrosCtrl,
              decoration: const InputDecoration(labelText: 'Litros'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [_DecimalFormatter()],
              validator: _validateDecimal,
              onChanged: (_) => _recalcular(_CampoCalculo.litros),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('abast_valor'),
              controller: _valorCtrl,
              decoration: const InputDecoration(labelText: 'Valor total (R\$)'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [_DecimalFormatter()],
              validator: _validateDecimal,
              onChanged: (_) => _recalcular(_CampoCalculo.valor),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('abast_posto'),
              controller: _postoCtrl,
              decoration: const InputDecoration(labelText: 'Posto (opcional)'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tanque cheio'),
              subtitle: const Text(
                'Importante para cálculo de consumo (km/L).',
              ),
              value: _tanqueCheio,
              onChanged: (v) => setState(() => _tanqueCheio = v),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : () => unawaited(_submit(veiculo)),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car_outlined, size: 48),
            SizedBox(height: 12),
            Text(
              'Cadastre um veículo antes de registrar abastecimentos.',
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
    return Row(
      children: [
        Icon(icone, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$titulo · ${veiculo.placa}',
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

enum _CampoCalculo { preco, litros, valor }

/// Aceita dígitos e um separador decimal (vírgula ou ponto). Normaliza para
/// vírgula ao digitar, mas o parse aceita ambos.
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
  // 3 casas decimais, removendo zeros à direita e separador quando sobrar
  // vazio (ex.: 2.000 → "2").
  final s = n.toStringAsFixed(3);
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
