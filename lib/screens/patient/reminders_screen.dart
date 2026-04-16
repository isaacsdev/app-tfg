import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'adherence_screen.dart';
import '../../services/notification_service.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        title: const Text(
          'Recordatorios de dosis',
          style: TextStyle(
            color: Color(0xFF6B48FF),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Color(0xFF6B48FF)),
            tooltip: 'Ver adherencia',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdherenceScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF6B48FF)),
            onPressed: () => _showAddReminderDialog(context, uid),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .collection('recordatorios')
            .orderBy('creado_en', descending: false)
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
                  Icon(Icons.alarm_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes recordatorios activos',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddReminderDialog(context, uid),
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir recordatorio'),
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
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _ReminderCard(data: data, docId: doc.id, uid: uid);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReminderDialog(context, uid),
        backgroundColor: const Color(0xFF6B48FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddReminderForm(uid: uid),
    );
  }
}

// ── TARJETA RECORDATORIO ─────────────────────────────────────
class _ReminderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String uid;

  const _ReminderCard({
    required this.data,
    required this.docId,
    required this.uid,
  });

  String _formatDiasSemana(List<dynamic> dias) {
    const nombres = {1: 'L', 2: 'M', 3: 'X', 4: 'J', 5: 'V', 6: 'S', 7: 'D'};
    final sorted = List<int>.from(dias)..sort();
    return sorted.map((d) => nombres[d] ?? '').join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final medicamento = data['medicamento'] ?? '';
    final dosis = data['dosis'] ?? '';
    final via = data['via'] ?? '';
    final frecuencia = data['frecuencia'] ?? '';
    final hora = data['hora'] ?? '';
    final activo = data['activo'] ?? true;
    final diasSemana = data['dias_semana'] as List<dynamic>? ?? [];
    final diaMes = data['dia_mes'] as int?;

    String subtitleExtra = '';
    if (diasSemana.isNotEmpty) {
      subtitleExtra = ' · ${_formatDiasSemana(diasSemana)}';
    } else if (diaMes != null && frecuencia == 'Mensual') {
      subtitleExtra = ' · día $diaMes de cada mes';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: activo
              ? const Color(0xFF6B48FF).withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
        ),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: activo
                  ? const Color(0xFF6B48FF).withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.medication,
              color: activo ? const Color(0xFF6B48FF) : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicamento,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: activo ? Colors.black87 : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dosis · $via',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.repeat, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '$frecuencia$subtitleExtra',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hora.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        hora,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Switch(
                value: activo,
                onChanged: (value) async {
                  await FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(uid)
                      .collection('recordatorios')
                      .doc(docId)
                      .update({'activo': value});
                  if (!value) {
                    await NotificationService()
                        .cancelarRecordatorio(docId.hashCode);
                  }
                },
                activeColor: const Color(0xFF6B48FF),
              ),
              GestureDetector(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Eliminar recordatorio'),
                      content: const Text(
                          '¿Seguro que quieres eliminar este recordatorio?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Eliminar',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await NotificationService()
                        .cancelarRecordatorio(docId.hashCode);
                    await FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(uid)
                        .collection('recordatorios')
                        .doc(docId)
                        .delete();
                  }
                },
                child: Icon(Icons.delete_outline,
                    color: Colors.red[300], size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── FORMULARIO AÑADIR RECORDATORIO ───────────────────────────
class _AddReminderForm extends StatefulWidget {
  final String uid;
  const _AddReminderForm({required this.uid});

  @override
  State<_AddReminderForm> createState() => _AddReminderFormState();
}

class _AddReminderFormState extends State<_AddReminderForm> {
  final _medicamentoController = TextEditingController();
  final _dosisController = TextEditingController();
  String _via = 'Oral';
  String _frecuencia = 'Diaria';
  TimeOfDay _hora = TimeOfDay.now();
  bool _isSaving = false;
  List<int> _diasSemana = [];
  int _diaMes = 1;

  final List<String> _vias = [
    'Oral', 'Inyección IM', 'Inyección SC',
    'Gel transdérmico', 'Parche', 'Otra',
  ];

  final List<String> _frecuencias = [
    'Diaria', 'Cada 2 días', 'Semanal',
    'Cada 2 semanas', 'Mensual', 'Otra',
  ];

  Future<void> _save() async {
    if (_medicamentoController.text.isEmpty ||
        _dosisController.text.isEmpty) return;
    setState(() => _isSaving = true);

    final horaStr =
        '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}';

    final docRef = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.uid)
        .collection('recordatorios')
        .add({
      'medicamento': _medicamentoController.text.trim(),
      'dosis': _dosisController.text.trim(),
      'via': _via,
      'frecuencia': _frecuencia,
      'hora': horaStr,
      'dias_semana': _diasSemana,
      'dia_mes': _diaMes,
      'activo': true,
      'creado_en': Timestamp.now(),
    });

    await NotificationService().programarRecordatorio(
      id: docRef.id.hashCode,
      medicamento: _medicamentoController.text.trim(),
      dosis: _dosisController.text.trim(),
      hora: horaStr,
    );

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
              'Nuevo recordatorio',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B48FF),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _medicamentoController,
              decoration: InputDecoration(
                labelText: 'Medicamento',
                hintText: 'Ej: Testosterona Enantato',
                prefixIcon: const Icon(Icons.medication_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF5F0FF),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dosisController,
              decoration: InputDecoration(
                labelText: 'Dosis',
                hintText: 'Ej: 250mg',
                prefixIcon: const Icon(Icons.scale_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF5F0FF),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _via,
              decoration: InputDecoration(
                labelText: 'Vía de administración',
                prefixIcon: const Icon(Icons.route_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF5F0FF),
              ),
              items: _vias
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) => setState(() => _via = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _frecuencia,
              decoration: InputDecoration(
                labelText: 'Frecuencia',
                prefixIcon: const Icon(Icons.repeat_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF5F0FF),
              ),
              items: _frecuencias
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (f) => setState(() {
                _frecuencia = f!;
                _diasSemana = [];
              }),
            ),
            if (_frecuencia == 'Semanal' ||
                _frecuencia == 'Cada 2 semanas' ||
                _frecuencia == 'Cada 2 días') ...[
              const SizedBox(height: 16),
              const Text(
                'Días de la semana',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _DayChip(
                      label: 'L',
                      value: 1,
                      selected: _diasSemana.contains(1),
                      onTap: () => setState(() => _diasSemana.contains(1)
                          ? _diasSemana.remove(1)
                          : _diasSemana.add(1))),
                  _DayChip(
                      label: 'M',
                      value: 2,
                      selected: _diasSemana.contains(2),
                      onTap: () => setState(() => _diasSemana.contains(2)
                          ? _diasSemana.remove(2)
                          : _diasSemana.add(2))),
                  _DayChip(
                      label: 'X',
                      value: 3,
                      selected: _diasSemana.contains(3),
                      onTap: () => setState(() => _diasSemana.contains(3)
                          ? _diasSemana.remove(3)
                          : _diasSemana.add(3))),
                  _DayChip(
                      label: 'J',
                      value: 4,
                      selected: _diasSemana.contains(4),
                      onTap: () => setState(() => _diasSemana.contains(4)
                          ? _diasSemana.remove(4)
                          : _diasSemana.add(4))),
                  _DayChip(
                      label: 'V',
                      value: 5,
                      selected: _diasSemana.contains(5),
                      onTap: () => setState(() => _diasSemana.contains(5)
                          ? _diasSemana.remove(5)
                          : _diasSemana.add(5))),
                  _DayChip(
                      label: 'S',
                      value: 6,
                      selected: _diasSemana.contains(6),
                      onTap: () => setState(() => _diasSemana.contains(6)
                          ? _diasSemana.remove(6)
                          : _diasSemana.add(6))),
                  _DayChip(
                      label: 'D',
                      value: 7,
                      selected: _diasSemana.contains(7),
                      onTap: () => setState(() => _diasSemana.contains(7)
                          ? _diasSemana.remove(7)
                          : _diasSemana.add(7))),
                ],
              ),
            ],
            if (_frecuencia == 'Mensual') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Día del mes:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  Expanded(
                    child: Slider(
                      value: _diaMes.toDouble(),
                      min: 1,
                      max: 31,
                      divisions: 30,
                      label: 'Día $_diaMes',
                      activeColor: const Color(0xFF6B48FF),
                      onChanged: (v) => setState(() => _diaMes = v.toInt()),
                    ),
                  ),
                  Text(
                    'Día $_diaMes',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B48FF),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(
                    context: context, initialTime: _hora);
                if (picked != null) setState(() => _hora = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_outlined,
                        color: Colors.grey),
                    const SizedBox(width: 12),
                    Text(
                      'Hora: ${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B48FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar recordatorio',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── DÍA CHIP ─────────────────────────────────────────────────
class _DayChip extends StatelessWidget {
  final String label;
  final int value;
  final bool selected;
  final VoidCallback onTap;

  const _DayChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6B48FF)
              : const Color(0xFF6B48FF).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF6B48FF),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}