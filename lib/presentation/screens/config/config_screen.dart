import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/export_service.dart';
import '../veiculos/veiculos_providers.dart';

/// Chave para persistir o último formato de exportação escolhido.
const _kPrefExportFormat = 'export_format';

class ConfigScreen extends ConsumerStatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConsumerState<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends ConsumerState<ConfigScreen> {
  bool _exportando = false;
  String? _placaSelecionada;
  ExportFormat _formato = ExportFormat.xlsx;

  @override
  void initState() {
    super.initState();
    unawaited(_carregarFormatoSalvo());
  }

  Future<void> _carregarFormatoSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kPrefExportFormat);
    if (saved != null && mounted) {
      setState(() {
        _formato = saved == 'zip' ? ExportFormat.zip : ExportFormat.xlsx;
      });
    }
  }

  Future<void> _salvarFormato(ExportFormat fmt) async {
    setState(() => _formato = fmt);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kPrefExportFormat,
      fmt == ExportFormat.zip ? 'zip' : 'xlsx',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final todos = ref.watch(veiculosTodosProvider).value ?? const [];
    final ativos = ref.watch(veiculosAtivosProvider).value ?? const [];
    final veiculoAtivo = ref.watch(veiculoAtivoProvider);

    // Veículo selecionado para export: inicia no ativo; permite trocar.
    final placaEfetiva = _placaSelecionada ?? veiculoAtivo?.placa;

    // Se a placa selecionada não existe em todos os veículos, reseta.
    final placaValida = todos.any((v) => v.placa == placaEfetiva)
        ? placaEfetiva
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.configuracoesTitulo)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.directions_car_outlined),
            title: Text(l10n.configuracoesVeiculosTitulo),
            subtitle: Text(l10n.configuracoesVeiculosSubtitulo),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/veiculos'),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.exportarDadosTitulo,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          if (todos.isEmpty && ativos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                l10n.exportarSemVeiculo,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Colors.grey),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.comparadorCampoVeiculo,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    isDense: true,
                    value: placaValida,
                    items: todos
                        .map(
                          (v) => DropdownMenuItem(
                            value: v.placa,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    v.apelido != null
                                        ? '${v.apelido} (${v.placa})'
                                        : '${v.marca} ${v.modelo} — ${v.placa}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (v.arquivado) ...[
                                  const SizedBox(width: 6),
                                  _ArquivadoBadge(
                                    label: l10n.veiculoArquivadoBadge,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _placaSelecionada = v),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ── Seletor de formato ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.exportarFormatoTitulo,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<ExportFormat>(
                    segments: [
                      ButtonSegment(
                        value: ExportFormat.xlsx,
                        label: Text(l10n.exportarFormatoXlsx),
                      ),
                      ButtonSegment(
                        value: ExportFormat.zip,
                        label: Text(l10n.exportarFormatoZip),
                      ),
                    ],
                    selected: {_formato},
                    onSelectionChanged: (s) => _salvarFormato(s.first),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                l10n.exportarDadosSubtitulo,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Semantics(
                button: true,
                label: l10n.exportarBotao,
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: (_exportando || placaValida == null)
                        ? null
                        : () => _exportar(context, l10n, placaValida),
                    icon: _exportando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share_outlined),
                    label: Text(l10n.exportarBotao),
                  ),
                ),
              ),
            ),
          ],
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.configuracoesPrivacidadeTitulo),
            subtitle: Text(l10n.configuracoesPrivacidadeSubtitulo),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/config/privacidade'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportar(
    BuildContext context,
    AppLocalizations l10n,
    String placa,
  ) async {
    setState(() => _exportando = true);
    try {
      final service = ref.read(exportServiceProvider);
      final xFile = await service.exportarVeiculo(placa, format: _formato);
      if (!context.mounted) return;
      // Mostra o snackbar de sucesso antes de abrir o share sheet.
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.exportarSucesso)));
      await SharePlus.instance.share(
        ShareParams(files: [xFile], subject: l10n.exportarShareSubject(placa)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.exportarErro(e.toString()))));
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }
}

/// Badge compacto exibido ao lado de veículos arquivados no dropdown.
class _ArquivadoBadge extends StatelessWidget {
  const _ArquivadoBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}
