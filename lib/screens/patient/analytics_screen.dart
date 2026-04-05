import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'charts_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        title: const Text(
          'Mis analíticas',
          style: TextStyle(
            color: Color(0xFF6B48FF),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart, color: Color(0xFF6B48FF)),
            tooltip: 'Ver evolución',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChartsScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .collection('analiticas')
            .orderBy('fecha', descending: true)
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
                  Icon(Icons.science_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes analíticas todavía',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tu sanitario programará las próximas',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddAnalyticDialog(context, uid),
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir valores manualmente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B48FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: snapshot.data!.docs.length + 1,
            itemBuilder: (context, index) {
              if (index == snapshot.data!.docs.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddAnalyticDialog(context, uid),
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir nueva analítica'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B48FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                );
              }

              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _AnalyticCard(data: data, docId: doc.id, uid: uid);
            },
          );
        },
      ),
    );
  }

  void _showAddAnalyticDialog(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddAnalyticForm(uid: uid),
    );
  }
}

// ── TARJETA DE ANALÍTICA ─────────────────────────────────────
class _AnalyticCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String uid;

  const _AnalyticCard({
    required this.data,
    required this.docId,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final fecha = data['fecha'] != null
        ? (data['fecha'] as Timestamp).toDate()
        : DateTime.now();
    final valores = data['valores'] as Map<String, dynamic>? ?? {};
    final validada = data['validada'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${fecha.day}/${fecha.month}/${fecha.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF6B48FF),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: validada
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  validada ? 'Validada' : 'Pendiente',
                  style: TextStyle(
                    color: validada ? Colors.green : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (valores.isEmpty)
            Text(
              'Sin valores introducidos',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: valores.entries.map((e) {
                final enRango = _isInRange(e.key, double.tryParse(e.value.toString()) ?? 0);
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: enRango
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: enRango
                          ? Colors.green.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        enRango ? Icons.check_circle : Icons.warning,
                        size: 14,
                        color: enRango ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_labelFor(e.key)}: ${e.value} ${_unitFor(e.key)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: enRango
                              ? Colors.green[800]
                              : Colors.red[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  bool _isInRange(String key, double value) {
    final rangos = {
      'hematocrito': [38.0, 54.0],
      'hemoglobina': [12.0, 17.5],
      'alt': [0.0, 40.0],
      'ast': [0.0, 40.0],
      'colesterol_total': [0.0, 200.0],
      'ldl': [0.0, 130.0],
      'hdl': [40.0, 999.0],
      'glucosa': [70.0, 100.0],
      'testosterona': [0.0, 999.0],
    };
    final r = rangos[key];
    if (r == null) return true;
    return value >= r[0] && value <= r[1];
  }

  String _labelFor(String key) {
    const labels = {
      'hematocrito': 'Hematocrito',
      'hemoglobina': 'Hemoglobina',
      'alt': 'ALT',
      'ast': 'AST',
      'colesterol_total': 'Colesterol',
      'ldl': 'LDL',
      'hdl': 'HDL',
      'glucosa': 'Glucosa',
      'testosterona': 'Testosterona',
    };
    return labels[key] ?? key;
  }

  String _unitFor(String key) {
    const units = {
      'hematocrito': '%',
      'hemoglobina': 'g/dL',
      'alt': 'U/L',
      'ast': 'U/L',
      'colesterol_total': 'mg/dL',
      'ldl': 'mg/dL',
      'hdl': 'mg/dL',
      'glucosa': 'mg/dL',
      'testosterona': 'ng/dL',
    };
    return units[key] ?? '';
  }
}

// ── FORMULARIO AÑADIR ANALÍTICA ──────────────────────────────
class _AddAnalyticForm extends StatefulWidget {
  final String uid;
  const _AddAnalyticForm({required this.uid});

  @override
  State<_AddAnalyticForm> createState() => _AddAnalyticFormState();
}

class _AddAnalyticFormState extends State<_AddAnalyticForm> {
  final Map<String, TextEditingController> _controllers = {
    'hematocrito': TextEditingController(),
    'hemoglobina': TextEditingController(),
    'alt': TextEditingController(),
    'ast': TextEditingController(),
    'colesterol_total': TextEditingController(),
    'ldl': TextEditingController(),
    'hdl': TextEditingController(),
    'glucosa': TextEditingController(),
    'testosterona': TextEditingController(),
  };

  bool _isSaving = false;
  DateTime _fecha = DateTime.now();

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final valores = <String, dynamic>{};
    _controllers.forEach((key, ctrl) {
      if (ctrl.text.isNotEmpty) {
        valores[key] = ctrl.text.trim();
      }
    });

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.uid)
        .collection('analiticas')
        .add({
      'fecha': Timestamp.fromDate(_fecha),
      'valores': valores,
      'validada': false,
      'origen': 'paciente',
    });

    setState(() => _isSaving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Introducir valores',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B48FF),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rellena solo los valores que tengas disponibles',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            ..._controllers.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: e.value,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      labelText: _labelFor(e.key),
                      suffixText: _unitFor(e.key),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F0FF),
                    ),
                  ),
                )),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B48FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar analítica',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(String key) {
    const labels = {
      'hematocrito': 'Hematocrito',
      'hemoglobina': 'Hemoglobina',
      'alt': 'ALT',
      'ast': 'AST',
      'colesterol_total': 'Colesterol total',
      'ldl': 'LDL',
      'hdl': 'HDL',
      'glucosa': 'Glucosa',
      'testosterona': 'Testosterona',
    };
    return labels[key] ?? key;
  }

  String _unitFor(String key) {
    const units = {
      'hematocrito': '%',
      'hemoglobina': 'g/dL',
      'alt': 'U/L',
      'ast': 'U/L',
      'colesterol_total': 'mg/dL',
      'ldl': 'mg/dL',
      'hdl': 'mg/dL',
      'glucosa': 'mg/dL',
      'testosterona': 'ng/dL',
    };
    return units[key] ?? '';
  }
}