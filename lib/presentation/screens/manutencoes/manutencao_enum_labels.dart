import '../../../data/database/enums.dart';
import '../../../l10n/app_localizations.dart';

extension TipoManutencaoLabel on TipoManutencao {
  String label(AppLocalizations l10n) => switch (this) {
    TipoManutencao.oleoMotor => l10n.tipoManutencaoOleoMotor,
    TipoManutencao.filtroOleo => l10n.tipoManutencaoFiltroOleo,
    TipoManutencao.filtroAr => l10n.tipoManutencaoFiltroAr,
    TipoManutencao.filtroCombustivel => l10n.tipoManutencaoFiltroCombustivel,
    TipoManutencao.filtroCabine => l10n.tipoManutencaoFiltroCabine,
    TipoManutencao.velas => l10n.tipoManutencaoVelas,
    TipoManutencao.correiaDentada => l10n.tipoManutencaoCorreiaDentada,
    TipoManutencao.correiaAcessorios => l10n.tipoManutencaoCorreiaAcessorios,
    TipoManutencao.pneus => l10n.tipoManutencaoPneus,
    TipoManutencao.alinhamentoBalanceamento =>
      l10n.tipoManutencaoAlinhamentoBalanceamento,
    TipoManutencao.pastilhasFreio => l10n.tipoManutencaoPastilhasFreio,
    TipoManutencao.discosFreio => l10n.tipoManutencaoDiscosFreio,
    TipoManutencao.oleoCambio => l10n.tipoManutencaoOleoCambio,
    TipoManutencao.fluidoFreio => l10n.tipoManutencaoFluidoFreio,
    TipoManutencao.revisaoGeral => l10n.tipoManutencaoRevisaoGeral,
    TipoManutencao.rodizioPneus => l10n.tipoManutencaoRodizioPneus,
    TipoManutencao.outros => l10n.tipoManutencaoOutros,
  };
}
