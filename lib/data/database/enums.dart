enum TipoVeiculo { carro, moto }

enum TipoCombustivelVeiculo { gasolina, alcool, flex, diesel, gnv, eletrico }

enum TipoCombustivelAbastecimento { gasolina, alcool, diesel, gnv, eletrico }

enum TipoManutencao {
  oleoMotor,
  filtroOleo,
  filtroAr,
  filtroCombustivel,
  filtroCabine,
  velas,
  correiaDentada,
  correiaAcessorios,
  pneus,
  alinhamentoBalanceamento,
  pastilhasFreio,
  discosFreio,
  oleoCambio,
  fluidoFreio,
  revisaoGeral,
  rodizioPneus,
  outros,
}

enum CategoriaDespesa { lavagem, estacionamento, pedagio, financiamento, outra }

enum FrequenciaDespesa { unica, semanal, mensal, anual }

enum StatusOcorrencia { pendente, paga, pulada }

enum StatusLembrete { pendente, concluido, adiado }
