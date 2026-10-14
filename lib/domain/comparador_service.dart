import '../data/database/app_database.dart';
import '../data/database/enums.dart';

enum MetodoComparador { historico, regraSetenta }

enum CombustivelMaisVantajoso { alcool, gasolina, empate }

class ResultadoComparador {
  const ResultadoComparador({
    required this.vencedor,
    required this.metodo,
    required this.precoAlcool,
    required this.precoGasolina,
    this.custoPorKmAlcool,
    this.custoPorKmGasolina,
    this.kmPorLitroAlcool,
    this.kmPorLitroGasolina,
  });

  final CombustivelMaisVantajoso vencedor;
  final MetodoComparador metodo;
  final double precoAlcool;
  final double precoGasolina;

  /// Preenchido apenas quando [metodo] == [MetodoComparador.historico].
  final double? custoPorKmAlcool;
  final double? custoPorKmGasolina;
  final double? kmPorLitroAlcool;
  final double? kmPorLitroGasolina;

  double get razaoPrecos => precoAlcool / precoGasolina;
}

/// Decide se vale mais a pena abastecer com álcool ou com gasolina.
///
/// Usa o rendimento (km/l) histórico do próprio veículo quando houver dados
/// suficientes (seção 9.3). Caso contrário cai na regra heurística de 70%
/// (álcool compensa se o preço do álcool for ≤ 70% do preço da gasolina).
class ComparadorService {
  const ComparadorService({
    this.limiarRegra70 = 0.7,
    this.janelaMeses = 12,
    this.minimoPontosPorCombustivel = 2,
  });

  final double limiarRegra70;
  final int janelaMeses;
  final int minimoPontosPorCombustivel;

  ResultadoComparador comparar({
    required double precoAlcool,
    required double precoGasolina,
    required List<Abastecimento> historico,
    DateTime? agora,
  }) {
    assert(precoAlcool > 0, 'precoAlcool deve ser > 0');
    assert(precoGasolina > 0, 'precoGasolina deve ser > 0');

    final now = agora ?? DateTime.now();
    final inicioJanela = DateTime(now.year, now.month - janelaMeses, now.day);
    final elegiveis = historico
        .where((a) => a.tanqueCheio && !a.data.isBefore(inicioJanela))
        .toList();

    final kmlAlcool = _kmPorLitro(
      elegiveis,
      TipoCombustivelAbastecimento.alcool,
    );
    final kmlGas = _kmPorLitro(
      elegiveis,
      TipoCombustivelAbastecimento.gasolina,
    );

    if (kmlAlcool != null && kmlGas != null) {
      final custoAlc = precoAlcool / kmlAlcool;
      final custoGas = precoGasolina / kmlGas;
      return ResultadoComparador(
        vencedor: _menorCusto(custoAlc, custoGas),
        metodo: MetodoComparador.historico,
        precoAlcool: precoAlcool,
        precoGasolina: precoGasolina,
        custoPorKmAlcool: custoAlc,
        custoPorKmGasolina: custoGas,
        kmPorLitroAlcool: kmlAlcool,
        kmPorLitroGasolina: kmlGas,
      );
    }

    return ResultadoComparador(
      vencedor: _regra70(precoAlcool, precoGasolina),
      metodo: MetodoComparador.regraSetenta,
      precoAlcool: precoAlcool,
      precoGasolina: precoGasolina,
    );
  }

  /// Consumo médio (km/l) por combustível a partir de abastecimentos com
  /// tanque cheio ordenados por km. Cada abastecimento depois do primeiro
  /// contribui com (km atual - km anterior) / litros atuais.
  double? _kmPorLitro(
    List<Abastecimento> dados,
    TipoCombustivelAbastecimento tipo,
  ) {
    final porTipo = dados.where((a) => a.tipoCombustivel == tipo).toList()
      ..sort((a, b) => a.km.compareTo(b.km));
    if (porTipo.length < minimoPontosPorCombustivel) return null;

    var kmTotal = 0;
    var litrosTotal = 0.0;
    for (var i = 1; i < porTipo.length; i++) {
      kmTotal += porTipo[i].km - porTipo[i - 1].km;
      litrosTotal += porTipo[i].litros;
    }
    if (kmTotal <= 0 || litrosTotal <= 0) return null;
    return kmTotal / litrosTotal;
  }

  CombustivelMaisVantajoso _menorCusto(double custoAlc, double custoGas) {
    const eps = 1e-6;
    if ((custoAlc - custoGas).abs() < eps) {
      return CombustivelMaisVantajoso.empate;
    }
    return custoAlc < custoGas
        ? CombustivelMaisVantajoso.alcool
        : CombustivelMaisVantajoso.gasolina;
  }

  CombustivelMaisVantajoso _regra70(double precoAlc, double precoGas) {
    const eps = 1e-6;
    final razao = precoAlc / precoGas;
    if ((razao - limiarRegra70).abs() < eps) {
      return CombustivelMaisVantajoso.empate;
    }
    return razao < limiarRegra70
        ? CombustivelMaisVantajoso.alcool
        : CombustivelMaisVantajoso.gasolina;
  }
}
