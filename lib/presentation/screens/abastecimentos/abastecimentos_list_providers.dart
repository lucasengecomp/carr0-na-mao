import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/enums.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';

/// Períodos de filtro disponíveis na tela de lista de abastecimentos.
enum FiltroPeriodo {
  ultimos30dias,
  ultimos90dias,
  ultimos12meses,
  tudo;

  String label(AppLocalizations l10n) => switch (this) {
    FiltroPeriodo.ultimos30dias => l10n.filtroPeriodoUltimos30d,
    FiltroPeriodo.ultimos90dias => l10n.filtroPeriodoUltimos90d,
    FiltroPeriodo.ultimos12meses => l10n.filtroPeriodoUltimos12m,
    FiltroPeriodo.tudo => l10n.filtroPeriodoTudo,
  };

  /// Retorna a data de corte (inclusive) ou null quando o filtro é "tudo".
  DateTime? get desde {
    final agora = DateTime.now();
    return switch (this) {
      FiltroPeriodo.ultimos30dias => agora.subtract(const Duration(days: 30)),
      FiltroPeriodo.ultimos90dias => agora.subtract(const Duration(days: 90)),
      FiltroPeriodo.ultimos12meses => DateTime(
        agora.year - 1,
        agora.month,
        agora.day,
      ),
      FiltroPeriodo.tudo => null,
    };
  }
}

/// Estado dos filtros da tela de lista de abastecimentos.
class FiltrosAbastecimento {
  const FiltrosAbastecimento({
    this.periodo = FiltroPeriodo.tudo,
    this.tipoCombustivel,
  });

  final FiltroPeriodo periodo;
  final TipoCombustivelAbastecimento? tipoCombustivel;

  FiltrosAbastecimento copyWith({
    FiltroPeriodo? periodo,
    Object? tipoCombustivel = _sentinel,
  }) {
    return FiltrosAbastecimento(
      periodo: periodo ?? this.periodo,
      tipoCombustivel: tipoCombustivel == _sentinel
          ? this.tipoCombustivel
          : tipoCombustivel as TipoCombustivelAbastecimento?,
    );
  }
}

// Sentinel para diferenciar null intencional de "não fornecido" no copyWith.
const Object _sentinel = Object();

/// Notifier que guarda e expõe os filtros ativos da tela de lista.
class FiltrosAbastecimentoNotifier extends Notifier<FiltrosAbastecimento> {
  @override
  FiltrosAbastecimento build() => const FiltrosAbastecimento();

  void setPeriodo(FiltroPeriodo periodo) {
    state = state.copyWith(periodo: periodo);
  }

  void setTipoCombustivel(TipoCombustivelAbastecimento? tipo) {
    state = state.copyWith(tipoCombustivel: tipo);
  }

  void limpar() {
    state = const FiltrosAbastecimento();
  }
}

final filtrosAbastecimentoProvider =
    NotifierProvider<FiltrosAbastecimentoNotifier, FiltrosAbastecimento>(
      FiltrosAbastecimentoNotifier.new,
    );

/// Lista reativa de abastecimentos com filtros aplicados.
/// Vazia quando a placa for null.
final abastecimentosFiltradosProvider =
    StreamProvider.family<List<Abastecimento>, String?>((ref, placa) {
      if (placa == null) return Stream.value(const <Abastecimento>[]);
      final filtros = ref.watch(filtrosAbastecimentoProvider);
      return ref
          .watch(abastecimentosDaoProvider)
          .watchFiltered(
            placa: placa,
            desde: filtros.periodo.desde,
            tipoCombustivel: filtros.tipoCombustivel,
          );
    });
