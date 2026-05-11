import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdherenceScreen extends StatelessWidget {
  const AdherenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        title: const Text(
          'Adherencia al tratamiento',
          style: TextStyle(
            color: Color(0xFF6B48FF),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .collection('recordatorios')
            .where('activo', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B48FF)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes recordatorios activos',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Añade recordatorios para registrar tu adherencia',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _AdherenceCard(
                uid: uid,
                recordatorioId: doc.id,
                medicamento: data['medicamento'] ?? '',
                dosis: data['dosis'] ?? '',
                via: data['via'] ?? '',
              );
            },
          );
        },
      ),
    );
  }
}

// ── TARJETA DE ADHERENCIA ─────────────────────────────────────
class _AdherenceCard extends StatefulWidget {
  final String uid;
  final String recordatorioId;
  final String medicamento;
  final String dosis;
  final String via;

  const _AdherenceCard({
    required this.uid,
    required this.recordatorioId,
    required this.medicamento,
    required this.dosis,
    required this.via,
  });

  @override
  State<_AdherenceCard> createState() => _AdherenceCardState();
}

class _AdherenceCardState extends State<_AdherenceCard> {
  String? _estadoHoy;
  List<Map<String, dynamic>> _historial = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.uid)
        .collection('recordatorios')
        .doc(widget.recordatorioId)
        .collection('adherencia')
        .orderBy('fecha', descending: true)
        .limit(30)
        .get();

    final historial = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'fecha': data['fecha_key'] ?? '',
        'estado': data['estado'] ?? '',
      };
    }).toList();

    final hoy = historial.firstWhere(
      (h) => h['fecha'] == _todayKey,
      orElse: () => {},
    );

    if (mounted) {
      setState(() {
        _historial = historial;
        _estadoHoy = hoy.isNotEmpty ? hoy['estado'] : null;
        _loading = false;
      });
    }
  }

  Future<void> _registrar(String estado) async {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.uid)
        .collection('recordatorios')
        .doc(widget.recordatorioId)
        .collection('adherencia')
        .doc(_todayKey)
        .set({
      'fecha': Timestamp.now(),
      'fecha_key': _todayKey,
      'estado': estado,
      'medicamento': widget.medicamento,
    });

    setState(() => _estadoHoy = estado);
    await _loadData();
  }

  double get _porcentaje {
    if (_historial.isEmpty) return 0;
    final tomados =
        _historial.where((h) => h['estado'] == 'tomado').length;
    return tomados / _historial.length * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6B48FF)),
      );
    }

    final porcentaje = _porcentaje;
    final colorPorcentaje = porcentaje >= 80
        ? Colors.green
        : porcentaje >= 50
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B48FF).withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medication,
                      color: Color(0xFF6B48FF), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.medicamento,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${widget.dosis} · ${widget.via}',
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Porcentaje
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${porcentaje.toInt()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: colorPorcentaje,
                      ),
                    ),
                    Text(
                      'adherencia',
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Barra de progreso
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: porcentaje / 100,
                backgroundColor: Colors.grey.withValues(alpha:0.1),
                valueColor:
                    AlwaysStoppedAnimation<Color>(colorPorcentaje),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Registro de hoy
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoy',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Tomado ✅',
                        selected: _estadoHoy == 'tomado',
                        color: Colors.green,
                        onTap: () => _registrar('tomado'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        label: 'No tomado ❌',
                        selected: _estadoHoy == 'no_tomado',
                        color: Colors.red,
                        onTap: () => _registrar('no_tomado'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Historial últimos 30 días
          if (_historial.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Últimos ${_historial.length} días',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _historial.map((h) {
                  final tomado = h['estado'] == 'tomado';
                  final fecha = h['fecha'] as String;
                  final partes = fecha.split('-');
                  final dia = partes.length == 3 ? partes[2] : '?';

                  return Tooltip(
                    message: tomado ? 'Tomado' : 'No tomado',
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: tomado
                            ? Colors.green.withValues(alpha:0.2)
                            : Colors.red.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: tomado
                              ? Colors.green.withValues(alpha:0.5)
                              : Colors.red.withValues(alpha:0.5),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          dia,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: tomado ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── BOTÓN DE ACCIÓN ───────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha:0.15) : Colors.grey.withValues(alpha:0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.withValues(alpha:0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? color : Colors.grey[600],
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}