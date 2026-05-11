import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final _notasController = TextEditingController();
  bool _isSaving = false;
  bool _yaCompletado = false;
  Map<String, dynamic>? _ultimoCheckin;

  final Map<String, double> _valores = {
    'bienestar': 3,
    'energia': 3,
    'animo': 3,
    'acne': 1,
    'irritabilidad': 1,
  };

  final Map<String, bool> _sintomas = {
    'sangrado_intermenstrual': false,
    'dolor_cabeza': false,
    'nauseas': false,
    'cambios_peso': false,
  };

  @override
  void initState() {
    super.initState();
    _checkIfCompleted();
  }

  Future<void> _checkIfCompleted() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ahora = DateTime.now();
    final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
    final inicioSemanaDate = DateTime(
        inicioSemana.year, inicioSemana.month, inicioSemana.day);

    final query = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('checkins')
        .where('fecha',
            isGreaterThanOrEqualTo: Timestamp.fromDate(inicioSemanaDate))
        .orderBy('fecha', descending: true)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty && mounted) {
      setState(() {
        _yaCompletado = true;
        _ultimoCheckin = query.docs.first.data();
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('checkins')
        .add({
      'fecha': Timestamp.now(),
      'valores': _valores,
      'sintomas': _sintomas,
      'notas': _notasController.text.trim(),
    });

    setState(() {
      _isSaving = false;
      _yaCompletado = true;
      _ultimoCheckin = {
        'valores': Map.from(_valores),
        'sintomas': Map.from(_sintomas),
        'notas': _notasController.text.trim(),
        'fecha': Timestamp.now(),
      };
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in guardado. ¡Gracias por registrarlo!'),
          backgroundColor: Color(0xFF6B48FF),
        ),
      );
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
          'Check-in semanal',
          style: TextStyle(
            color: Color(0xFF6B48FF),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _yaCompletado
          ? _CompletadoView(checkin: _ultimoCheckin)
          : _FormView(
              valores: _valores,
              sintomas: _sintomas,
              notasController: _notasController,
              isSaving: _isSaving,
              onSave: _save,
              onValorChanged: (key, value) =>
                  setState(() => _valores[key] = value),
              onSintomaChanged: (key, value) =>
                  setState(() => _sintomas[key] = value),
            ),
    );
  }
}

// ── VISTA YA COMPLETADO ──────────────────────────────────────
class _CompletadoView extends StatelessWidget {
  final Map<String, dynamic>? checkin;
  const _CompletadoView({this.checkin});

  String _emoji(String key, double valor) {
    final positivos = ['bienestar', 'energia', 'animo'];
    if (positivos.contains(key)) {
      if (valor >= 4) return '😊';
      if (valor >= 3) return '😐';
      return '😔';
    } else {
      if (valor <= 2) return '✅';
      if (valor <= 3) return '⚠️';
      return '🔴';
    }
  }

  String _label(String key) {
    const labels = {
      'bienestar': 'Bienestar',
      'energia': 'Energía',
      'animo': 'Ánimo',
      'acne': 'Acné',
      'irritabilidad': 'Irritabilidad',
    };
    return labels[key] ?? key;
  }

  String _sintomaLabel(String key) {
    const labels = {
      'sangrado_intermenstrual': 'Sangrado intermenstrual',
      'dolor_cabeza': 'Dolor de cabeza',
      'nauseas': 'Náuseas',
      'cambios_peso': 'Cambios de peso',
    };
    return labels[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final valores = Map<String, dynamic>.from(checkin?['valores'] as Map? ?? {});
    final sintomas = Map<String, dynamic>.from(checkin?['sintomas'] as Map? ?? {});
    final notas = checkin?['notas'] as String? ?? '';
    final sintomasActivos = sintomas.entries
        .where((e) => e.value == true)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6B48FF).withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    size: 40, color: Color(0xFF6B48FF)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¡Check-in completado!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B48FF),
                        ),
                      ),
                      Text(
                        'Aquí tienes el resumen de esta semana',
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Valores
          if (valores.isNotEmpty) ...[
            const Text(
              'Cómo te has sentido',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B48FF),
              ),
            ),
            const SizedBox(height: 12),
            ...valores.entries.map((e) {
              final valor = (e.value as num).toDouble();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(_emoji(e.key, valor),
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _label(e.key),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Container(
                          margin: const EdgeInsets.only(left: 3),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < valor.toInt()
                                ? const Color(0xFF6B48FF)
                                : const Color(0xFF6B48FF).withValues(alpha:0.2),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${valor.toInt()}/5',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B48FF),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // Síntomas
          const Text(
            'Síntomas registrados',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B48FF),
            ),
          ),
          const SizedBox(height: 12),
          if (sintomasActivos.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('✅', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Text(
                    'Sin síntomas esta semana',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            )
          else
            ...sintomasActivos.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha:0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text('⚠️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 12),
                      Text(
                        _sintomaLabel(e.key),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                )),

          // Notas
          if (notas.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Notas',
              style: TextStyle(
                fontSize: 15,
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
              ),
              child: Text(
                notas,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
            ),
          ],

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: Color(0xFF6B48FF), size: 18),
                const SizedBox(width: 12),
                Text(
                  'Vuelve la semana que viene 🙂',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── FORMULARIO ───────────────────────────────────────────────
class _FormView extends StatelessWidget {
  final Map<String, double> valores;
  final Map<String, bool> sintomas;
  final TextEditingController notasController;
  final bool isSaving;
  final VoidCallback onSave;
  final Function(String, double) onValorChanged;
  final Function(String, bool) onSintomaChanged;

  const _FormView({
    required this.valores,
    required this.sintomas,
    required this.notasController,
    required this.isSaving,
    required this.onSave,
    required this.onValorChanged,
    required this.onSintomaChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6B48FF).withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF6B48FF)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tómate un momento para reflexionar sobre cómo te has sentido esta semana.',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('¿Cómo te has sentido?'),
          const SizedBox(height: 16),
          _SliderItem(
            label: 'Bienestar general',
            emoji: '😊',
            value: valores['bienestar']!,
            onChanged: (v) => onValorChanged('bienestar', v),
          ),
          _SliderItem(
            label: 'Nivel de energía',
            emoji: '⚡',
            value: valores['energia']!,
            onChanged: (v) => onValorChanged('energia', v),
          ),
          _SliderItem(
            label: 'Estado de ánimo',
            emoji: '💜',
            value: valores['animo']!,
            onChanged: (v) => onValorChanged('animo', v),
          ),
          _SliderItem(
            label: 'Acné',
            emoji: '🔴',
            value: valores['acne']!,
            onChanged: (v) => onValorChanged('acne', v),
            invertedLabel: true,
          ),
          _SliderItem(
            label: 'Irritabilidad',
            emoji: '😤',
            value: valores['irritabilidad']!,
            onChanged: (v) => onValorChanged('irritabilidad', v),
            invertedLabel: true,
          ),
          const SizedBox(height: 24),
          const _SectionTitle('¿Has notado alguno de estos síntomas?'),
          const SizedBox(height: 12),
          _SintomaItem(
            label: 'Sangrado intermenstrual',
            value: sintomas['sangrado_intermenstrual']!,
            onChanged: (v) => onSintomaChanged('sangrado_intermenstrual', v),
          ),
          _SintomaItem(
            label: 'Dolor de cabeza frecuente',
            value: sintomas['dolor_cabeza']!,
            onChanged: (v) => onSintomaChanged('dolor_cabeza', v),
          ),
          _SintomaItem(
            label: 'Náuseas',
            value: sintomas['nauseas']!,
            onChanged: (v) => onSintomaChanged('nauseas', v),
          ),
          _SintomaItem(
            label: 'Cambios de peso notables',
            value: sintomas['cambios_peso']!,
            onChanged: (v) => onSintomaChanged('cambios_peso', v),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Notas adicionales'),
          const SizedBox(height: 12),
          TextField(
            controller: notasController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Cuéntanos cualquier cosa que quieras que tu sanitario sepa...',
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
              onPressed: isSaving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B48FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Enviar check-in',
                      style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 24),
        ],
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

class _SliderItem extends StatelessWidget {
  final String label;
  final String emoji;
  final double value;
  final Function(double) onChanged;
  final bool invertedLabel;

  const _SliderItem({
    required this.label,
    required this.emoji,
    required this.value,
    required this.onChanged,
    this.invertedLabel = false,
  });

  String get _leftLabel => invertedLabel ? 'Poco' : 'Bajo';
  String get _rightLabel => invertedLabel ? 'Mucho' : 'Alto';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF6B48FF),
              thumbColor: const Color(0xFF6B48FF),
              inactiveTrackColor: const Color(0xFF6B48FF).withValues(alpha:0.2),
              overlayColor: const Color(0xFF6B48FF).withValues(alpha:0.1),
            ),
            child: Slider(
              value: value,
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_leftLabel,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              Text(value.toInt().toString(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B48FF))),
              Text(_rightLabel,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }
}

class _SintomaItem extends StatelessWidget {
  final String label;
  final bool value;
  final Function(bool) onChanged;

  const _SintomaItem({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? const Color(0xFF6B48FF).withValues(alpha:0.5)
              : Colors.transparent,
        ),
      ),
      child: CheckboxListTile(
        title: Text(label, style: const TextStyle(fontSize: 14)),
        value: value,
        onChanged: (v) => onChanged(v ?? false),
        activeColor: const Color(0xFF6B48FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}