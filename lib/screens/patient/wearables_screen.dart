import 'package:flutter/material.dart';
import 'package:health/health.dart';

class WearablesScreen extends StatefulWidget {
  const WearablesScreen({super.key});

  @override
  State<WearablesScreen> createState() => _WearablesScreenState();
}

class _WearablesScreenState extends State<WearablesScreen> {
  final Health _health = Health();
  bool _permisosOk = false;
  bool _loading = false;

  // Datos
  int _pasos = 0;
  double _frecuenciaCardiaca = 0;
  double _peso = 0;
  double _spo2 = 0;
  double _glucosa = 0;

  final List<HealthDataType> _tipos = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.WEIGHT,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BLOOD_GLUCOSE,
  ];

  @override
  void initState() {
    super.initState();
    _solicitarPermisos();
  }

  Future<void> _solicitarPermisos() async {
    try {
      final disponible = await _health.isHealthConnectAvailable();
      if (!disponible) {
        await _health.installHealthConnect();
        return;
      }
      final permisos = _tipos.map((_) => HealthDataAccess.READ).toList();
      final ok = await _health.requestAuthorization(_tipos, permissions: permisos);
      setState(() => _permisosOk = ok);
      if (ok) _sincronizar();
    } catch (e) {
      await _health.installHealthConnect();
    }
  }

  Future<void> _sincronizar() async {
    setState(() => _loading = true);

    final ahora = DateTime.now();
    final hace7dias = ahora.subtract(const Duration(days: 7));

    try {
      final datos = await _health.getHealthDataFromTypes(
        startTime: hace7dias,
        endTime: ahora,
        types: _tipos,
      );

      int pasos = 0;
      double fc = 0;
      double peso = 0;
      double spo2 = 0;
      double glucosa = 0;
      int countFc = 0;

      for (final punto in datos) {
        final valor = (punto.value as NumericHealthValue).numericValue.toDouble();
        switch (punto.type) {
          case HealthDataType.STEPS:
            pasos += valor.toInt();
            break;
          case HealthDataType.HEART_RATE:
            fc += valor;
            countFc++;
            break;
          case HealthDataType.WEIGHT:
            peso = valor;
            break;
          case HealthDataType.BLOOD_OXYGEN:
            spo2 = valor;
            break;
          case HealthDataType.BLOOD_GLUCOSE:
            glucosa = valor;
            break;
          default:
            break;
        }
      }

      setState(() {
        _pasos = pasos;
        _frecuenciaCardiaca = countFc > 0 ? fc / countFc : 0;
        _peso = peso;
        _spo2 = spo2;
        _glucosa = glucosa;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        title: const Text(
          'Wearables',
          style: TextStyle(
            color: Color(0xFF6B48FF),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6B48FF)),
            onPressed: _sincronizar,
            tooltip: 'Sincronizar',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B48FF)))
          : !_permisosOk
              ? _PermisosDenegados(onRetry: _solicitarPermisos)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B48FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.watch,
                                color: Color(0xFF6B48FF)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Datos de los últimos 7 días desde Health Connect',
                                style: TextStyle(
                                    color: Colors.grey[700], fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Actividad',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B48FF),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DatoCard(
                        icono: Icons.directions_walk,
                        titulo: 'Pasos',
                        valor: _pasos > 0 ? '$_pasos' : 'Sin datos',
                        unidad: 'pasos',
                        color: Colors.green,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Salud',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B48FF),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DatoCard(
                        icono: Icons.favorite,
                        titulo: 'Frecuencia cardíaca',
                        valor: _frecuenciaCardiaca > 0
                            ? _frecuenciaCardiaca.toStringAsFixed(0)
                            : 'Sin datos',
                        unidad: 'lpm',
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      _DatoCard(
                        icono: Icons.monitor_weight_outlined,
                        titulo: 'Peso',
                        valor: _peso > 0
                            ? _peso.toStringAsFixed(1)
                            : 'Sin datos',
                        unidad: 'kg',
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _DatoCard(
                        icono: Icons.air,
                        titulo: 'SpO2',
                        valor: _spo2 > 0
                            ? _spo2.toStringAsFixed(0)
                            : 'Sin datos',
                        unidad: '%',
                        color: Colors.cyan,
                      ),
                      const SizedBox(height: 12),
                      _DatoCard(
                        icono: Icons.water_drop_outlined,
                        titulo: 'Glucosa',
                        valor: _glucosa > 0
                            ? _glucosa.toStringAsFixed(0)
                            : 'Sin datos',
                        unidad: 'mg/dL',
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ── SIN PERMISOS ─────────────────────────────────────────────
class _PermisosDenegados extends StatelessWidget {
  final VoidCallback onRetry;
  const _PermisosDenegados({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.watch_off_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Health Connect no disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B48FF),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Esta función requiere Android 14 o superior con Google Health Connect instalado.',
                          style: TextStyle(color: Colors.orange[800], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Health Connect permite sincronizar datos de salud desde tu wearable (smartwatch, pulsera de actividad, tensiómetro inteligente) directamente con MEtanoia.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Datos que podrás sincronizar:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B48FF)),
            ),
            const SizedBox(height: 12),
            _CompatibilidadItem(icono: Icons.directions_walk, texto: 'Pasos diarios'),
            _CompatibilidadItem(icono: Icons.favorite, texto: 'Frecuencia cardíaca'),
            _CompatibilidadItem(icono: Icons.monitor_weight_outlined, texto: 'Peso corporal'),
            _CompatibilidadItem(icono: Icons.air, texto: 'Saturación de oxígeno (SpO2)'),
            _CompatibilidadItem(icono: Icons.water_drop_outlined, texto: 'Glucosa en sangre'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B48FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompatibilidadItem extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _CompatibilidadItem({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icono, color: const Color(0xFF6B48FF), size: 18),
          const SizedBox(width: 12),
          Text(texto, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

// ── TARJETA DE DATO ──────────────────────────────────────────
class _DatoCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final String unidad;
  final Color color;

  const _DatoCard({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.unidad,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tieneDatos = valor != 'Sin datos';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 15),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                valor,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: tieneDatos ? color : Colors.grey[400],
                ),
              ),
              if (tieneDatos)
                Text(
                  unidad,
                  style: TextStyle(
                      color: Colors.grey[500], fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }
}