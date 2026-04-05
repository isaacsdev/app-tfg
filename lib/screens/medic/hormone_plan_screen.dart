import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HormonePlanScreen extends StatefulWidget {
  final String uid;
  final String nombrePaciente;

  const HormonePlanScreen({
    super.key,
    required this.uid,
    required this.nombrePaciente,
  });

  @override
  State<HormonePlanScreen> createState() => _HormonePlanScreenState();
}

class _HormonePlanScreenState extends State<HormonePlanScreen> {
  final _medicamentoController = TextEditingController();
  final _dosisController = TextEditingController();
  final _frecuenciaController = TextEditingController();
  final _notasController = TextEditingController();
  String _via = 'Oral';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _planExiste = false;

  final List<String> _vias = [
    'Oral', 'Inyección IM', 'Inyección SC',
    'Gel transdérmico', 'Parche', 'Otra',
  ];

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.uid)
        .collection('plan_hormonal')
        .doc('actual')
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      _medicamentoController.text = data['medicamento'] ?? '';
      _dosisController.text = data['dosis'] ?? '';
      _frecuenciaController.text = data['frecuencia'] ?? '';
      _notasController.text = data['notas'] ?? '';
      _via = data['via'] ?? 'Oral';
      _planExiste = true;
    }

    setState(() => _isLoading = false);
  }

  Future<void> _savePlan() async {
    if (_medicamentoController.text.isEmpty ||
        _dosisController.text.isEmpty) return;

    setState(() => _isSaving = true);

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.uid)
        .collection('plan_hormonal')
        .doc('actual')
        .set({
      'medicamento': _medicamentoController.text.trim(),
      'dosis': _dosisController.text.trim(),
      'via': _via,
      'frecuencia': _frecuenciaController.text.trim(),
      'notas': _notasController.text.trim(),
      'actualizado_en': Timestamp.now(),
    });

    setState(() {
      _isSaving = false;
      _planExiste = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan hormonal guardado correctamente'),
          backgroundColor: Color(0xFF2ECC71),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0FFF4),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plan hormonal',
              style: TextStyle(
                color: Color(0xFF2ECC71),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              widget.nombrePaciente,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2ECC71)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ECC71)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_planExiste)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF2ECC71).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Color(0xFF2ECC71), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Plan activo — puedes modificarlo',
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                  _SectionTitle('Medicamento'),
                  const SizedBox(height: 12),
                  _Field(
                    controller: _medicamentoController,
                    label: 'Nombre del medicamento',
                    hint: 'Ej: Testosterona Enantato',
                    icon: Icons.medication_outlined,
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    controller: _dosisController,
                    label: 'Dosis',
                    hint: 'Ej: 250mg',
                    icon: Icons.scale_outlined,
                  ),
                  const SizedBox(height: 12),

                  // Vía
                  DropdownButtonFormField<String>(
                    value: _via,
                    decoration: InputDecoration(
                      labelText: 'Vía de administración',
                      prefixIcon: const Icon(Icons.route_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _vias
                        .map((v) =>
                            DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => _via = v!),
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    controller: _frecuenciaController,
                    label: 'Frecuencia',
                    hint: 'Ej: Cada 2 semanas',
                    icon: Icons.repeat_outlined,
                  ),
                  const SizedBox(height: 24),

                  _SectionTitle('Notas clínicas'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notasController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Instrucciones especiales, consideraciones clínicas...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _planExiste
                                  ? 'Actualizar plan'
                                  : 'Crear plan hormonal',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2ECC71),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}