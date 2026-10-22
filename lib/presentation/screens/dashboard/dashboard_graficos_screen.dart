import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_graficos_providers.dart';

// Cores dos segmentos das barras empilhadas e do pie.
// Mantidas como literais fixos pois são cores de dado (identidade de série),
// não UI chrome. Em dark mode o contraste das séries principais foi verificado:
//   _corAbastec (#2196F3, azul)   ≈ 4,0:1 vs #121212 — aceitável para série.
//   _corManut   (#FF9800, laranja) ≈ 8,4:1 — OK.
//   _corDespesas (#9C27B0, roxo)  — cor de preenchimento de barra, não texto.
// Para o texto branco sobre as fatias do pie, o contraste depende de cada
// segmento; o design mantém Colors.white pois as cores das fatias são
// suficientemente saturadas. Detalhes na seção "Decisão sobre paleta" do PR.
const _corAbastec = Color(0xFF2196F3); // azul
const _corManut = Color(0xFFFF9800); // laranja
const _corDespesas = Color(0xFF9C27B0); // roxo

// Paleta extra para fatias adicionais do pie chart.
const _coresPie = <Color>[
  _corAbastec,
  _corManut,
  _corDespesas,
  Color(0xFF4CAF50),
  Color(0xFFF44336),
  Color(0xFF00BCD4),
  Color(0xFFFFEB3B),
  Color(0xFF795548),
];

class DashboardGraficosScreen extends ConsumerWidget {
  const DashboardGraficosScreen({required this.placa, super.key});

  final String placa;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gráficos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GraficoSection(
              titulo: 'Evolução de gastos (últimos 12 meses)',
              child: _GastosBarChart(placa: placa),
            ),
            const SizedBox(height: 24),
            _GraficoSection(
              titulo: 'Consumo médio km/l (últimos 12 meses)',
              child: _ConsumoLineChart(placa: placa),
            ),
            const SizedBox(height: 24),
            _GraficoSection(
              titulo: 'Distribuição por categoria (últimos 12 meses)',
              child: _DistribuicaoPieChart(placa: placa),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Seção com título e card envolvente
// ---------------------------------------------------------------------------

class _GraficoSection extends StatelessWidget {
  const _GraficoSection({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          child: Padding(padding: const EdgeInsets.all(12), child: child),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Placeholder de estado vazio
// ---------------------------------------------------------------------------

// Recebe o BuildContext para obter a cor do tema, evitando Colors.grey
// hardcoded que não se adapta ao dark mode.
Widget _semDados(BuildContext context, String msg) => SizedBox(
  height: 120,
  child: Center(
    child: Text(
      msg,
      style: TextStyle(
        fontStyle: FontStyle.italic,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    ),
  ),
);

Widget _loading() => const SizedBox(
  height: 120,
  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
);

Widget _erro(Object e) =>
    SizedBox(height: 40, child: Center(child: Text('Erro: $e', maxLines: 2)));

// ---------------------------------------------------------------------------
// Formatadores pt-BR
// ---------------------------------------------------------------------------

String _fmtMes(DateTime d) {
  const nomes = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];
  return nomes[d.month - 1];
}

String _fmtMoeda(double v) {
  if (v >= 1000) {
    return 'R\$${(v / 1000).toStringAsFixed(1).replaceAll('.', ',')}k';
  }
  return 'R\$${v.toStringAsFixed(0)}';
}

String _fmtKmL(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

// ---------------------------------------------------------------------------
// Gráfico 1 — Barras empilhadas (gastos mensais)
// ---------------------------------------------------------------------------

class _GastosBarChart extends ConsumerWidget {
  const _GastosBarChart({required this.placa});

  final String placa;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(gastosMensaisProvider(placa));
    final labelColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return async.when(
      loading: _loading,
      error: (e, _) => _erro(e),
      data: (meses) {
        final comDados = meses.any((m) => m.total > 0);
        if (!comDados) {
          return _semDados(
            context,
            'Nenhum gasto registrado nos últimos 12 meses.',
          );
        }

        final maxY = meses.fold<double>(
          1,
          (max, m) => m.total > max ? m.total : max,
        );

        final barGroups = <BarChartGroupData>[];
        for (var i = 0; i < meses.length; i++) {
          final m = meses[i];
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: m.total,
                  width: 12,
                  rodStackItems: [
                    BarChartRodStackItem(0, m.abastec, _corAbastec),
                    BarChartRodStackItem(
                      m.abastec,
                      m.abastec + m.manut,
                      _corManut,
                    ),
                    BarChartRodStackItem(
                      m.abastec + m.manut,
                      m.total,
                      _corDespesas,
                    ),
                  ],
                  borderRadius: BorderRadius.zero,
                ),
              ],
            ),
          );
        }

        return Semantics(
          label: 'Gráfico de barras: evolução de gastos mensais por categoria',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    maxY: maxY * 1.15,
                    barGroups: barGroups,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox.shrink();
                            return Text(
                              _fmtMoeda(value),
                              style: TextStyle(fontSize: 9, color: labelColor),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= meses.length) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              _fmtMes(meses[idx].mes),
                              style: TextStyle(fontSize: 9, color: labelColor),
                            );
                          },
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final m = meses[group.x];
                          final linhas = [
                            'Abastec: ${_fmtMoeda(m.abastec)}',
                            'Manut: ${_fmtMoeda(m.manut)}',
                            'Despesas: ${_fmtMoeda(m.despesas)}',
                            'Total: ${_fmtMoeda(m.total)}',
                          ];
                          // Colors.white mantido intencionalmente: o fundo
                          // padrão do tooltip do fl_chart é blueGrey.shade700
                          // (escuro), portanto branco tem contraste adequado
                          // em ambos os modos. Ver PR #108 para detalhes.
                          return BarTooltipItem(
                            linhas.join('\n'),
                            const TextStyle(color: Colors.white, fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _LegendaBarras(),
            ],
          ),
        );
      },
    );
  }
}

class _LegendaBarras extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendaItem(cor: _corAbastec, rotulo: 'Abastec.'),
        SizedBox(width: 12),
        _LegendaItem(cor: _corManut, rotulo: 'Manut.'),
        SizedBox(width: 12),
        _LegendaItem(cor: _corDespesas, rotulo: 'Despesas'),
      ],
    );
  }
}

class _LegendaItem extends StatelessWidget {
  const _LegendaItem({required this.cor, required this.rotulo});

  final Color cor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: cor, shape: BoxShape.rectangle),
        ),
        const SizedBox(width: 4),
        Text(
          rotulo,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Gráfico 2 — Linha de consumo (km/l por mês)
// ---------------------------------------------------------------------------

class _ConsumoLineChart extends ConsumerWidget {
  const _ConsumoLineChart({required this.placa});

  final String placa;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(consumoMensalProvider(placa));
    final labelColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return async.when(
      loading: _loading,
      error: (e, _) => _erro(e),
      data: (meses) {
        final comDados = meses.any((m) => m.kmPorLitro != null);
        if (!comDados) {
          return _semDados(
            context,
            'Dados insuficientes.\nRegistre abastecimentos com tanque cheio para ver o consumo.',
          );
        }

        final spots = <FlSpot>[];
        double maxY = 1;
        for (var i = 0; i < meses.length; i++) {
          final v = meses[i].kmPorLitro;
          if (v != null) {
            spots.add(FlSpot(i.toDouble(), v));
            if (v > maxY) maxY = v;
          }
        }

        return Semantics(
          label: 'Gráfico de linha: consumo médio em km por litro',
          child: SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: _corAbastec,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _corAbastec.withAlpha(30),
                    ),
                  ),
                ],
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '${_fmtKmL(value)} km/l',
                          style: TextStyle(fontSize: 9, color: labelColor),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 ||
                            idx >= meses.length ||
                            value != idx.toDouble()) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          _fmtMes(meses[idx].mes),
                          style: TextStyle(fontSize: 9, color: labelColor),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((s) {
                        final idx = s.spotIndex;
                        final m = spots[idx];
                        // Colors.white mantido intencionalmente: o fundo
                        // padrão do tooltip do fl_chart é blueGrey.shade700
                        // (escuro), portanto branco tem contraste adequado
                        // em ambos os modos. Ver PR #108 para detalhes.
                        return LineTooltipItem(
                          '${_fmtKmL(m.y)} km/l',
                          const TextStyle(color: Colors.white, fontSize: 11),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Gráfico 3 — Pizza por categoria
// ---------------------------------------------------------------------------

class _DistribuicaoPieChart extends ConsumerWidget {
  const _DistribuicaoPieChart({required this.placa});

  final String placa;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(distribuicaoCategoriaProvider(placa));

    return async.when(
      loading: _loading,
      error: (e, _) => _erro(e),
      data: (categorias) {
        if (categorias.isEmpty) {
          return _semDados(context, 'Nenhum gasto nos últimos 12 meses.');
        }

        final total = categorias.fold<double>(0, (s, c) => s + c.total);

        final sections = <PieChartSectionData>[];
        for (var i = 0; i < categorias.length; i++) {
          final c = categorias[i];
          final pct = (c.total / total) * 100;
          final cor = _coresPie[i % _coresPie.length];
          sections.add(
            PieChartSectionData(
              value: c.total,
              title: '${pct.toStringAsFixed(1).replaceAll('.', ',')}%',
              color: cor,
              radius: 70,
              // Colors.white mantido intencionalmente: o rótulo é renderizado
              // sobre a fatia colorida da pizza (não sobre o fundo do Scaffold).
              // As cores da paleta _coresPie são suficientemente saturadas para
              // fornecer contraste adequado contra branco em ambos os modos.
              // Ver PR #108 para detalhes.
              titleStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );
        }

        return Semantics(
          label: 'Gráfico de pizza: distribuição de gastos por categoria',
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _LegendaPie(categorias: categorias, total: total),
            ],
          ),
        );
      },
    );
  }
}

class _LegendaPie extends StatelessWidget {
  const _LegendaPie({required this.categorias, required this.total});

  final List<CategoriaGasto> categorias;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        for (var i = 0; i < categorias.length; i++)
          _LegendaPieItem(
            cor: _coresPie[i % _coresPie.length],
            rotulo: categorias[i].rotulo,
            valor: categorias[i].total,
          ),
      ],
    );
  }
}

class _LegendaPieItem extends StatelessWidget {
  const _LegendaPieItem({
    required this.cor,
    required this.rotulo,
    required this.valor,
  });

  final Color cor;
  final String rotulo;
  final double valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$rotulo: ${_fmtMoeda(valor)}',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
