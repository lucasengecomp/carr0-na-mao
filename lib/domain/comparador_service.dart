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
    required this.custoPorKmAlcool,
    required this.custoPorKmGasolina,
    required this.kmPorLitroAlcool,
    required this.kmPorLitroGasolina,
  });

  final CombustivelMaisVantajoso vencedor;
  final MetodoComparador metodo;
  final double precoAlcool;
  final double precoGasolina;

  /// Custo por km para cada combustível.
  /// Quando [metodo] == [MetodoComparador.regraSetenta] usa valores padrão de
  /// rendimento (ver [ComparadorService.kmPorLitroAlcoolPadrao] e
  /// [ComparadorService.kmPorLitroGasolinaPadrao]).
  final double custoPorKmAlcool;
  final double custoPorKmGasolina;
  final double kmPorLitroAlcool;
  final double kmPorLitroGasolina;

  double get razaoPrecos => precoAlcool / precoGasolina;
}

/// Decide se vale mais a pena abastecer com álcool ou com gasolina.
///
/// Usa o rendimento (km/l) histórico do próprio veículo quando houver dados
/// suficientes (seção 9.3). Caso contrário cai na regra heurística de 70%
/// (álcool compensa se o preço do álcool for ≤ 70% do preço da gasolina).
///
/// No caminho da regra 70%, o custo por km é estimado com os valores padrão
/// [kmPorLitroGasolinaPadrao] e [kmPorLitroAlcoolPadrao] (valores típicos
/// brasileiros para carros flex médios). A lógica de histórico real ficará em
/// #31.
class ComparadorService {
  const ComparadorService({
    this.limiarRegra70 = 0.7,
    this.janelaMeses = 12,
    this.minimoPontosPorCombustivel = 2,
    // Padrões típicos para carro flex médio (usados quando não há histórico).
    // Gasolina: ~10 km/L; Álcool: ~7 km/L.
    this.kmPorLitroGasolinaPadrao = 10.0,
    this.kmPorLitroAlcoolPadrao = 7.0,
  });

  final double limiarRegra70;
  final int janelaMeses;
  final int minimoPontosPorCombustivel;

  /// Rendimento padrão de gasolina quando não há histórico suficiente (km/L).
  final double kmPorLitroGasolinaPadrao;

  /// Rendimento padrão de álcool quando não há histórico suficiente (km/L).
  final double kmPorLitroAlcoolPadrao;

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

    // Sem histórico suficiente: usa regra 70% para a decisão e estimativas
    // baseadas nos rendimentos padrão para exibir o custo por km.
    final custoAlcEstimado = precoAlcool / kmPorLitroAlcoolPadrao;
    final custoGasEstimado = precoGasolina / kmPorLitroGasolinaPadrao;
    return ResultadoComparador(
      vencedor: _regra70(precoAlcool, precoGasolina),
      metodo: MetodoComparador.regraSetenta,
      precoAlcool: precoAlcool,
      precoGasolina: precoGasolina,
      custoPorKmAlcool: custoAlcEstimado,
      custoPorKmGasolina: custoGasEstimado,
      kmPorLitroAlcool: kmPorLitroAlcoolPadrao,
      kmPorLitroGasolina: kmPorLitroGasolinaPadrao,
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
