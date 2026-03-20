import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  final _nombreController = TextEditingController();
  final _pronounsController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _alergiasController = TextEditingController();
  final _antecedentesController = TextEditingController();
  final _medicacionController = TextEditingController();
  DateTime? _fechaNacimiento;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      _nombreController.text = data['nombre'] ?? '';
      _pronounsController.text = data['pronombres'] ?? '';
      _telefonoController.text = data['telefono'] ?? '';
      _alergiasController.text = data['alergias'] ?? '';
      _antecedentesController.text = data['antecedentes'] ?? '';
      _medicacionController.text = data['medicacion_externa'] ?? '';
      if (data['fecha_nacimiento'] != null) {
        _fechaNacimiento = (data['fecha_nacimiento'] as Timestamp).toDate();
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
      'nombre': _nombreController.text.trim(),
      'pronombres': _pronounsController.text.trim(),
      'telefono': _telefonoController.text.trim(),
      'alergias': _alergiasController.text.trim(),
      'antecedentes': _antecedentesController.text.trim(),
      'medicacion_externa': _medicacionController.text.trim(),
      'fecha_nacimiento': _fechaNacimiento != null
          ? Timestamp.fromDate(_fechaNacimiento!)
          : null,
      'rol': 'paciente',
    }, SetOptions(merge: true));

    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil guardado correctamente'),
          backgroundColor: Color(0xFF6B48FF),
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(1995),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _fechaNacimiento = picked);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6B48FF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        title: const Text(
          'Mi perfil',
          style: TextStyle(
            color: Color(0xFF6B48FF),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF6B48FF),
                    ),
                  )
                : const Text(
                    'Guardar',
                    style: TextStyle(
                      color: Color(0xFF6B48FF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('Datos personales'),
              const SizedBox(height: 12),
              _Field(
                controller: _nombreController,
                label: 'Nombre',
                icon: Icons.person_outline,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _pronounsController,
                label: 'Pronombres',
                icon: Icons.badge_outlined,
                hint: 'él/ellos, ella/ellas, elle/elles...',
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _telefonoController,
                label: 'Teléfono',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),

              // Fecha de nacimiento
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cake_outlined,
                          color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Text(
                        _fechaNacimiento != null
                            ? '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}'
                            : 'Fecha de nacimiento',
                        style: TextStyle(
                          color: _fechaNacimiento != null
                              ? Colors.black87
                              : Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _SectionTitle('Información clínica'),
              const SizedBox(height: 12),
              _Field(
                controller: _alergiasController,
                label: 'Alergias conocidas',
                icon: Icons.warning_amber_outlined,
                maxLines: 3,
                hint: 'Ninguna, penicilina...',
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _antecedentesController,
                label: 'Antecedentes médicos',
                icon: Icons.history_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _medicacionController,
                label: 'Medicación externa',
                icon: Icons.medication_outlined,
                maxLines: 3,
                hint: 'Otros medicamentos que tomas habitualmente',
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B48FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Guardar perfil',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
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
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6B48FF),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
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