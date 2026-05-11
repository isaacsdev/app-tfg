import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HormonePlanPatientScreen extends StatefulWidget {
  const HormonePlanPatientScreen({super.key});

  @override
  State<HormonePlanPatientScreen> createState() =>
      _HormonePlanPatientScreenState();
}

class _HormonePlanPatientScreenState
    extends State<HormonePlanPatientScreen> {
  Map<String, dynamic>? _plan;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('plan_hormonal')
        .doc('actual')
        .get();

    if (mounted) {
      setState(() {
        _plan = doc.exists ? doc.data() : null;
        _loading = false;
      });
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
          'Mi plan hormonal',
          style: TextStyle(
            color: Color(0xFF6B48FF),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6B48FF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B48FF)))
          : _plan == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medication_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Sin plan asignado',
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tu sanitario todavía no ha asignado\nun plan hormonal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 13),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B48FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color:
                                  const Color(0xFF6B48FF).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFF6B48FF),
                              radius: 24,
                              child: Icon(Icons.medication,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _plan!['medicamento'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6B48FF),
                                    ),
                                  ),
                                  Text(
                                    _plan!['dosis'] ?? '',
                                    style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Detalles del tratamiento',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B48FF),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetalleItem(
                        icono: Icons.route_outlined,
                        titulo: 'Vía de administración',
                        valor: _plan!['via'] ?? '-',
                      ),
                      _DetalleItem(
                        icono: Icons.repeat_outlined,
                        titulo: 'Frecuencia',
                        valor: _plan!['frecuencia'] ?? '-',
                      ),
                      if (_plan!['notas'] != null &&
                          (_plan!['notas'] as String).isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Notas clínicas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B48FF),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.notes_outlined,
                                  color: Color(0xFF6B48FF), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _plan!['notas'],
                                  style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                      height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_outlined,
                                color: Colors.orange, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No modifiques tu tratamiento sin consultar con tu sanitario.',
                                style: TextStyle(
                                    color: Colors.orange[800],
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _DetalleItem extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;

  const _DetalleItem({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Icon(icono, color: const Color(0xFF6B48FF), size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              Text(
                valor,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }
}