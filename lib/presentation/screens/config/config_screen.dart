import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/export_service.dart';
import '../veiculos/veiculos_providers.dart';

class ConfigScreen extends ConsumerStatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConsumerState<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends ConsumerState<ConfigScreen> {
  bool _exportando = false;
  String? _placaSelecionada;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ativos = ref.watch(veiculosAtivosProvider).value ?? const [];
    final veiculoAtivo = ref.watch(veiculoAtivoProvider);

    // Veículo selecionado para export: inicia no ativo; permite trocar.
    final placaEfetiva = _placaSelecionada ?? veiculoAtivo?.placa;

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
          if (ativos.isEmpty)
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
                    value: placaEfetiva,
                    items: ativos
                        .map(
                          (v) => DropdownMenuItem(
                            value: v.placa,
                            child: Text(
                              v.apelido != null
                                  ? '${v.apelido} (${v.placa})'
                                  : '${v.marca} ${v.modelo} — ${v.placa}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _placaSelecionada = v),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
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
                    onPressed: (_exportando || placaEfetiva == null)
                        ? null
                        : () => _exportar(context, l10n, placaEfetiva),
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
      final xFiles = await service.exportarVeiculo(placa);
      if (!context.mounted) return;
      // Mostra o snackbar de sucesso antes de abrir o share sheet.
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.exportarSucesso)));
      if (xFiles.isNotEmpty) {
        await SharePlus.instance.share(
          ShareParams(files: xFiles, subject: l10n.exportarShareSubject(placa)),
        );
      }
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
