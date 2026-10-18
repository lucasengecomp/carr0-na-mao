import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/domain/comparador_service.dart';
import 'package:flutter_test/flutter_test.dart';

Abastecimento _abast({
  required int id,
  required DateTime data,
  required int km,
  required double litros,
  TipoCombustivelAbastecimento combustivel =
      TipoCombustivelAbastecimento.gasolina,
  bool tanqueCheio = true,
}) => Abastecimento(
  id: id,
  veiculoPlaca: 'ABC1D23',
  data: data,
  km: km,
  tipoCombustivel: combustivel,
  precoLitro: 6,
  valorTotal: litros * 6,
  litros: litros,
  tanqueCheio: tanqueCheio,
);

void main() {
  final hoje = DateTime(2026, 10, 1);
  const service = ComparadorService();

  group('caminho histórico (seção 9.3)', () {
    // Veículo faz 12 km/l na gasolina (100 km / ~8.33 L) e 8 km/l no álcool
    // (100 km / 12.5 L). Com gasolina a 6,00 e álcool a 4,00:
    //   custo/km gasolina = 6/12  = 0,500
    //   custo/km álcool   = 4/8   = 0,500 -> empate
    // Com álcool a 3,80 o álcool passa a ser mais barato.
    List<Abastecimento> historicoFlex() => [
      _abast(id: 1, data: DateTime(2026, 6, 1), km: 10000, litros: 40),
      _abast(id: 2, data: DateTime(2026, 7, 1), km: 10600, litros: 50),
      _abast(
        id: 3,
        data: DateTime(2026, 6, 15),
        km: 10200,
        litros: 25,
        combustivel: TipoCombustivelAbastecimento.alcool,
      ),
      _abast(
        id: 4,
        data: DateTime(2026, 7, 15),
        km: 10400,
        litros: 25,
        combustivel: TipoCombustivelAbastecimento.alcool,
      ),
    ];

    // Dataset com 3 abastecimentos tanque cheio por combustível (RF-20/RF-21).
    // Gasolina: pares (10000→10500)/50L = 10 km/L, (10500→11000)/50L = 10 km/L,
    //           média 10 km/L.
    // Álcool:   pares (10100→10450)/50L = 7 km/L, (10450→10800)/50L = 7 km/L,
    //           média 7 km/L.
    List<Abastecimento> historico3Pontos() => [
      _abast(id: 10, data: DateTime(2026, 4, 1), km: 10000, litros: 50),
      _abast(id: 11, data: DateTime(2026, 6, 1), km: 10500, litros: 50),
      _abast(id: 12, data: DateTime(2026, 8, 1), km: 11000, litros: 50),
      _abast(
        id: 13,
        data: DateTime(2026, 4, 15),
        km: 10100,
        litros: 50,
        combustivel: TipoCombustivelAbastecimento.alcool,
      ),
      _abast(
        id: 14,
        data: DateTime(2026, 6, 15),
        km: 10450,
        litros: 50,
        combustivel: TipoCombustivelAbastecimento.alcool,
      ),
      _abast(
        id: 15,
        data: DateTime(2026, 8, 15),
        km: 10800,
        litros: 50,
        combustivel: TipoCombustivelAbastecimento.alcool,
      ),
    ];

    test('3 pontos por combustível: km/L calculado pelos 2 pares consecutivos', () {
      final r = service.comparar(
        precoAlcool: 4.00,
        precoGasolina: 6.00,
        historico: historico3Pontos(),
        agora: hoje,
      );

      expect(r.metodo, MetodoComparador.historico);
      // Gasolina: (10500-10000)/50 = 10, (11000-10500)/50 = 10 → média 10 km/L
      // Álcool:   (10450-10100)/50 = 7,  (10800-10450)/50 = 7  → média 7 km/L
      expect(r.kmPorLitroGasolina, closeTo(10.0, 0.001));
      expect(r.kmPorLitroAlcool, closeTo(7.0, 0.001));
      expect(r.custoPorKmGasolina, closeTo(6.0 / 10.0, 0.001));
      expect(r.custoPorKmAlcool, closeTo(4.0 / 7.0, 0.001));
      // custo gasolina 0,60 > custo alcool ~0,571 → álcool compensa
      expect(r.vencedor, CombustivelMaisVantajoso.alcool);
    });

    test('álcool compensa quando custo/km do álcool é menor', () {
      final r = service.comparar(
        precoAlcool: 3.80,
        precoGasolina: 6.00,
        historico: historicoFlex(),
        agora: hoje,
      );

      expect(r.metodo, MetodoComparador.historico);
      expect(r.vencedor, CombustivelMaisVantajoso.alcool);
      expect(r.kmPorLitroGasolina, closeTo(12.0, 0.001));
      expect(r.kmPorLitroAlcool, closeTo(8.0, 0.001));
      expect(r.custoPorKmGasolina, closeTo(0.5, 0.001));
      expect(r.custoPorKmAlcool, closeTo(3.80 / 8.0, 0.001));
    });

    test('gasolina compensa quando custo/km da gasolina é menor', () {
      final r = service.comparar(
        precoAlcool: 4.50,
        precoGasolina: 6.00,
        historico: historicoFlex(),
        agora: hoje,
      );

      expect(r.metodo, MetodoComparador.historico);
      expect(r.vencedor, CombustivelMaisVantajoso.gasolina);
    });

    test('empate quando custos por km são iguais', () {
      final r = service.comparar(
        precoAlcool: 4.00,
        precoGasolina: 6.00,
        historico: historicoFlex(),
        agora: hoje,
      );

      expect(r.metodo, MetodoComparador.historico);
      expect(r.vencedor, CombustivelMaisVantajoso.empate);
    });

    test('ignora abastecimentos de tanque não-cheio', () {
      final historico = [
        ...historicoFlex(),
        // Abastec extra, mesmo combustível, sem tanque cheio — deve ser
        // ignorado. Se entrasse, mudaria a média.
        _abast(
          id: 99,
          data: DateTime(2026, 8, 1),
          km: 10700,
          litros: 5,
          tanqueCheio: false,
        ),
      ];
      final r = service.comparar(
        precoAlcool: 3.80,
        precoGasolina: 6.00,
        historico: historico,
        agora: hoje,
      );

      expect(r.kmPorLitroGasolina, closeTo(12.0, 0.001));
    });

    test('ignora abastecimentos fora da janela de 12 meses', () {
      final historico = [
        // 18 meses atrás: fora da janela.
        _abast(id: 1, data: DateTime(2025, 4, 1), km: 8000, litros: 40),
        _abast(id: 2, data: DateTime(2025, 5, 1), km: 8400, litros: 40),
        // Dentro da janela.
        _abast(id: 3, data: DateTime(2026, 6, 1), km: 10000, litros: 40),
        _abast(id: 4, data: DateTime(2026, 7, 1), km: 10600, litros: 50),
        _abast(
          id: 5,
          data: DateTime(2026, 6, 15),
          km: 10200,
          litros: 25,
          combustivel: TipoCombustivelAbastecimento.alcool,
        ),
        _abast(
          id: 6,
          data: DateTime(2026, 7, 15),
          km: 10400,
          litros: 25,
          combustivel: TipoCombustivelAbastecimento.alcool,
        ),
      ];
      final r = service.comparar(
        precoAlcool: 3.80,
        precoGasolina: 6.00,
        historico: historico,
        agora: hoje,
      );

      // Só os de dentro da janela entram na média.
      expect(r.metodo, MetodoComparador.historico);
      expect(r.kmPorLitroGasolina, closeTo(12.0, 0.001));
      expect(r.kmPorLitroAlcool, closeTo(8.0, 0.001));
    });
  });

  group('caminho regra 70% (fallback)', () {
    test('fallback: 3 tanque cheio gasolina mas só 1 álcool → regraSetenta', () {
      // Caso explícito do RF-21: gasolina com histórico suficiente (3 pontos),
      // álcool insuficiente (1 ponto) → deve cair na regra 70%.
      final historico = [
        _abast(id: 1, data: DateTime(2026, 4, 1), km: 10000, litros: 50),
        _abast(id: 2, data: DateTime(2026, 6, 1), km: 10500, litros: 50),
        _abast(id: 3, data: DateTime(2026, 8, 1), km: 11000, litros: 50),
        _abast(
          id: 4,
          data: DateTime(2026, 6, 15),
          km: 10200,
          litros: 50,
          combustivel: TipoCombustivelAbastecimento.alcool,
        ),
      ];
      final r = service.comparar(
        precoAlcool: 3.80,
        precoGasolina: 6.00,
        historico: historico,
        agora: hoje,
      );

      expect(r.metodo, MetodoComparador.regraSetenta);
      expect(r.kmPorLitroAlcool, closeTo(7.0, 0.001));
      expect(r.kmPorLitroGasolina, closeTo(10.0, 0.001));
    });

    test('cai na regra 70% sem histórico suficiente de álcool', () {
      // 2 pontos de gasolina (OK) mas só 1 de álcool: fallback.
      final historico = [
        _abast(id: 1, data: DateTime(2026, 6, 1), km: 10000, litros: 40),
        _abast(id: 2, data: DateTime(2026, 7, 1), km: 10600, litros: 50),
        _abast(
          id: 3,
          data: DateTime(2026, 6, 15),
          km: 10200,
          litros: 25,
          combustivel: TipoCombustivelAbastecimento.alcool,
        ),
      ];
      final r = service.comparar(
        precoAlcool: 3.80,
        precoGasolina: 6.00,
        historico: historico,
        agora: hoje,
      );

      expect(r.metodo, MetodoComparador.regraSetenta);
      expect(r.vencedor, CombustivelMaisVantajoso.alcool);
      // Sem histórico: usa rendimentos padrão (7 km/L álcool, 10 km/L gasolina).
      expect(r.kmPorLitroAlcool, closeTo(7.0, 0.001));
      expect(r.kmPorLitroGasolina, closeTo(10.0, 0.001));
      expect(r.custoPorKmAlcool, closeTo(3.80 / 7.0, 0.001));
      expect(r.custoPorKmGasolina, closeTo(6.00 / 10.0, 0.001));
    });

    test('cai na regra 70% sem nenhum histórico', () {
      final r = service.comparar(
        precoAlcool: 4.50,
        precoGasolina: 6.00,
        historico: const [],
        agora: hoje,
      );

      // 4.50 / 6.00 = 0.75 > 0.70 -> gasolina.
      expect(r.metodo, MetodoComparador.regraSetenta);
      expect(r.vencedor, CombustivelMaisVantajoso.gasolina);
    });

    test('álcool vence pela regra 70% quando preço é < 70% da gasolina', () {
      final r = service.comparar(
        precoAlcool: 3.90,
        precoGasolina: 6.00,
        historico: const [],
        agora: hoje,
      );

      expect(r.metodo, MetodoComparador.regraSetenta);
      expect(r.vencedor, CombustivelMaisVantajoso.alcool);
    });

    test('empate na regra 70% quando a razão é exatamente 0,7', () {
      // 7.0 / 10.0 = 0.7 exato em ponto flutuante.
      final r = service.comparar(
        precoAlcool: 7.00,
        precoGasolina: 10.00,
        historico: const [],
        agora: hoje,
      );
      expect(r.vencedor, CombustivelMaisVantajoso.empate);
    });

    test('cai na regra 70% quando todo histórico é de tanque não-cheio', () {
      final historico = [
        _abast(
          id: 1,
          data: DateTime(2026, 6, 1),
          km: 10000,
          litros: 40,
          tanqueCheio: false,
        ),
        _abast(
          id: 2,
          data: DateTime(2026, 7, 1),
          km: 10600,
          litros: 50,
          tanqueCheio: false,
        ),
      ];
      final r = service.comparar(
        precoAlcool: 3.80,
        precoGasolina: 6.00,
        historico: historico,
        agora: hoje,
      );
      expect(r.metodo, MetodoComparador.regraSetenta);
    });
  });

  test('razaoPrecos sempre disponível', () {
    final r = service.comparar(
      precoAlcool: 4.20,
      precoGasolina: 6.00,
      historico: const [],
      agora: hoje,
    );
    expect(r.razaoPrecos, closeTo(0.7, 0.001));
  });

  group('custo/km com defaults 10/7 (regra 70%)', () {
    // RF-20/RF-21: com gasolina=5,00 e defaults 10 km/L → custo 0,50/km;
    //              com álcool=3,50 e defaults 7 km/L  → custo 0,50/km; empate.
    test('gasolina a R\$5,00 → custo/km = 0,50 com default 10 km/L', () {
      final r = service.comparar(
        precoAlcool: 3.50,
        precoGasolina: 5.00,
        historico: const [],
        agora: hoje,
      );
      expect(r.metodo, MetodoComparador.regraSetenta);
      expect(r.kmPorLitroGasolina, closeTo(10.0, 0.001));
      expect(r.custoPorKmGasolina, closeTo(0.50, 0.001));
    });

    test('álcool a R\$3,50 → custo/km = 0,50 com default 7 km/L', () {
      final r = service.comparar(
        precoAlcool: 3.50,
        precoGasolina: 5.00,
        historico: const [],
        agora: hoje,
      );
      expect(r.kmPorLitroAlcool, closeTo(7.0, 0.001));
      expect(r.custoPorKmAlcool, closeTo(0.50, 0.001));
    });

    test('R\$3,50 álcool + R\$5,00 gasolina → custo/km iguais → empate', () {
      // 3,50 / 5,00 = 0,70 exato → empate pela regra 70%.
      final r = service.comparar(
        precoAlcool: 3.50,
        precoGasolina: 5.00,
        historico: const [],
        agora: hoje,
      );
      expect(r.vencedor, CombustivelMaisVantajoso.empate);
    });
  });
}
