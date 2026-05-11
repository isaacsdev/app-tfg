import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  String _parametroSeleccionado = 'hematocrito';
  List<Map<String, dynamic>> _datos = [];
  bool _loading = true;

  final Map<String, String> _parametros = {
    'hematocrito': 'Hematocrito (%)',
    'hemoglobina': 'Hemoglobina (g/dL)',
    'testosterona': 'Testosterona (ng/dL)',
    'alt': 'ALT (U/L)',
    'ast': 'AST (U/L)',
    'colesterol_total': 'Colesterol total (mg/dL)',
    'ldl': 'LDL (mg/dL)',
    'hdl': 'HDL (mg/dL)',
    'glucosa': 'Glucosa (mg/dL)',
  };

  final Map<String, List<double>> _rangos = {
    'hematocrito': [38.0, 54.0],
    'hemoglobina': [12.0, 17.5],
    'testosterona': [300.0, 1000.0],
    'alt': [0.0, 40.0],
    'ast': [0.0, 40.0],
    'colesterol_total': [0.0, 200.0],
    'ldl': [0.0, 130.0],
    'hdl': [40.0, 999.0],
    'glucosa': [70.0, 100.0],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('analiticas')
        .orderBy('fecha', descending: false)
        .get();

    final datos = <Map<String, dynamic>>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final valores = data['valores'] as Map<String, dynamic>? ?? {};
      if (valores.containsKey(_parametroSeleccionado)) {
        final valor =
            double.tryParse(valores[_parametroSeleccionado].toString());
        if (valor != null) {
          datos.add({
            'fecha': (data['fecha'] as Timestamp).toDate(),
            'valor': valor,
            'validada': data['validada'] ?? false,
          });
        }
      }
    }

    if (mounted) {
      setState(() {
        _datos = datos;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rango = _rangos[_parametroSeleccionado] ?? [0.0, 100.0];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        title: const Text(
          'Evolución analíticas',
          style: TextStyle(
            color: Color(0xFF6B48FF),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Selector de parámetro
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF6B48FF).withValues(alpha:0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _parametroSeleccionado,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down,
                    color: Color(0xFF6B48FF)),
                items: _parametros.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value,
                              style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _parametroSeleccionado = value);
                    _loadData();
                  }
                },
              ),
            ),
          ),

          // Gráfica o estado vacío
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF6B48FF)))
                : _datos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.show_chart,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Sin datos para este parámetro',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Añade analíticas con este valor\npara ver su evolución',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Resumen
                            _ResumenCard(
                              datos: _datos,
                              rango: rango,
                              parametro: _parametros[
                                      _parametroSeleccionado] ??
                                  '',
                            ),
                            const SizedBox(height: 16),

                            // Gráfica
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha:0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: _LineChart(
                                  datos: _datos,
                                  rango: rango,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Leyenda
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                _LegendItem(
                                    color: const Color(0xFF6B48FF),
                                    label: 'Valor'),
                                const SizedBox(width: 16),
                                _LegendItem(
                                    color: Colors.green.withValues(alpha:0.5),
                                    label: 'Rango normal'),
                              ],
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── RESUMEN ───────────────────────────────────────────────────
class _ResumenCard extends StatelessWidget {
  final List<Map<String, dynamic>> datos;
  final List<double> rango;
  final String parametro;

  const _ResumenCard({
    required this.datos,
    required this.rango,
    required this.parametro,
  });

  @override
  Widget build(BuildContext context) {
    final ultimo = datos.last['valor'] as double;
    final enRango = ultimo >= rango[0] && ultimo <= rango[1];
    final color = enRango ? Colors.green : Colors.red;

    double? cambio;
    if (datos.length > 1) {
      final penultimo = datos[datos.length - 2]['valor'] as double;
      cambio = ultimo - penultimo;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Último valor',
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  ultimo.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  enRango ? '✅ En rango' : '⚠️ Fuera de rango',
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ],
            ),
          ),
          if (cambio != null)
            Column(
              children: [
                Icon(
                  cambio > 0
                      ? Icons.trending_up
                      : cambio < 0
                          ? Icons.trending_down
                          : Icons.trending_flat,
                  color: cambio == 0
                      ? Colors.grey
                      : cambio > 0
                          ? Colors.orange
                          : Colors.blue,
                  size: 32,
                ),
                Text(
                  '${cambio > 0 ? '+' : ''}${cambio.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  'vs anterior',
                  style: TextStyle(
                      color: Colors.grey[400], fontSize: 10),
                ),
              ],
            ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${datos.length} mediciones',
                style:
                    TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                'Rango: ${rango[0].toInt()}-${rango[1] > 900 ? '∞' : rango[1].toInt()}',
                style:
                    TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── GRÁFICA DE LÍNEAS ─────────────────────────────────────────
class _LineChart extends StatelessWidget {
  final List<Map<String, dynamic>> datos;
  final List<double> rango;

  const _LineChart({required this.datos, required this.rango});

  @override
  Widget build(BuildContext context) {
    final spots = datos.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value['valor'] as double);
    }).toList();

    final valores = datos.map((d) => d['valor'] as double).toList();
    final minVal = (valores.reduce((a, b) => a < b ? a : b) * 0.9)
        .clamp(0.0, double.infinity);
    final maxVal = valores.reduce((a, b) => a > b ? a : b) * 1.1;

    return LineChart(
      LineChartData(
        minY: minVal,
        maxY: maxVal,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxVal - minVal) / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha:0.2),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style:
                    TextStyle(color: Colors.grey[500], fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= datos.length) {
                  return const SizedBox.shrink();
                }
                final fecha = datos[index]['fecha'] as DateTime;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${fecha.day}/${fecha.month}',
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 9),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        // Banda de rango normal
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            HorizontalRangeAnnotation(
              y1: rango[0].clamp(minVal, maxVal),
              y2: rango[1].clamp(minVal, maxVal),
              color: Colors.green.withValues(alpha:0.1),
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: const Color(0xFF6B48FF),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                final valor = spot.y;
                final enRango =
                    valor >= rango[0] && valor <= rango[1];
                return FlDotCirclePainter(
                  radius: 5,
                  color: enRango ? Colors.green : Colors.red,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF6B48FF).withValues(alpha:0.08),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final fecha =
                    datos[spot.spotIndex]['fecha'] as DateTime;
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)}\n${fecha.day}/${fecha.month}/${fecha.year}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

// ── LEYENDA ───────────────────────────────────────────────────
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}