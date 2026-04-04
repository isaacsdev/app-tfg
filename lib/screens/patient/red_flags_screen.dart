import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RedFlagsScreen extends StatelessWidget {
  const RedFlagsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        title: const Text(
          'Alertas y banderas rojas',
          style: TextStyle(color: Color(0xFF6B48FF), fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Si notas alguno de estos síntomas, pulsa el botón correspondiente. Tu sanitario recibirá una alerta inmediata.',
                      style: TextStyle(color: Colors.orange[800], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('🚨 Emergencia — llama al 112'),
            const SizedBox(height: 12),
            _RedFlagButton(uid: uid, label: 'Dolor en el pecho',
              description: 'Presión, opresión o dolor intenso en el pecho',
              severity: 'emergencia',
              instruction: 'Llama al 112 inmediatamente. No conduzcas solo/a. Este síntoma puede indicar un evento cardiovascular grave.',
              color: Colors.red, icon: Icons.favorite_border),
            _RedFlagButton(uid: uid, label: 'Dificultad para respirar',
              description: 'Sensación de ahogo o falta de aire repentina',
              severity: 'emergencia',
              instruction: 'Llama al 112 inmediatamente. Siéntate erguido/a y mantén la calma mientras esperas ayuda.',
              color: Colors.red, icon: Icons.air),
            _RedFlagButton(uid: uid, label: 'Desmayo o pérdida de consciencia',
              description: 'Pérdida de consciencia o sensación inminente de desmayo',
              severity: 'emergencia',
              instruction: 'Llama al 112. Si ya te has desmayado, necesitas que alguien llame por ti. Túmbate con las piernas elevadas.',
              color: Colors.red, icon: Icons.person_off_outlined),
            _RedFlagButton(uid: uid, label: 'Sangrado abundante',
              description: 'Sangrado vaginal o de otro tipo intenso e incontrolable',
              severity: 'emergencia',
              instruction: 'Llama al 112 o acude a urgencias. Aplica presión sobre la zona si es posible.',
              color: Colors.red, icon: Icons.water_drop_outlined),
            const SizedBox(height: 24),
            const _SectionTitle('⚠️ Urgente — contacta con tu sanitario'),
            const SizedBox(height: 12),
            _RedFlagButton(uid: uid, label: 'Cefalea intensa',
              description: 'Dolor de cabeza muy fuerte o diferente al habitual',
              severity: 'urgente',
              instruction: 'Contacta con tu sanitario hoy. Si el dolor es el peor que has tenido en tu vida, acude a urgencias.',
              color: Colors.orange, icon: Icons.psychology_outlined),
            _RedFlagButton(uid: uid, label: 'Hinchazón o dolor en piernas',
              description: 'Pierna hinchada, roja o dolorosa al tacto',
              severity: 'urgente',
              instruction: 'Puede indicar trombosis. Contacta con tu sanitario urgentemente o acude a urgencias.',
              color: Colors.orange, icon: Icons.accessibility_new_outlined),
            _RedFlagButton(uid: uid, label: 'Cambios de humor extremos',
              description: 'Cambios de estado de ánimo muy bruscos o inusuales',
              severity: 'urgente',
              instruction: 'Anota cuándo ocurre y contacta con tu sanitario. Puede ser necesario ajustar la dosis.',
              color: Colors.orange, icon: Icons.mood_bad_outlined),
            _RedFlagButton(uid: uid, label: 'Náuseas o vómitos persistentes',
              description: 'Náuseas o vómitos que duran más de 24 horas',
              severity: 'urgente',
              instruction: 'Mantente hidratado/a y contacta con tu sanitario. Puede ser una reacción al tratamiento.',
              color: Colors.orange, icon: Icons.sick_outlined),
            const SizedBox(height: 24),
            const _SectionTitle('📋 Historial de alertas'),
            const SizedBox(height: 12),
            _AlertHistory(uid: uid),
          ],
        ),
      ),
    );
  }
}

// ── BOTÓN DE BANDERA ROJA ────────────────────────────────────
class _RedFlagButton extends StatelessWidget {
  final String uid;
  final String label;
  final String description;
  final String severity;
  final String instruction;
  final Color color;
  final IconData icon;

  const _RedFlagButton({
    required this.uid,
    required this.label,
    required this.description,
    required this.severity,
    required this.instruction,
    required this.color,
    required this.icon,
  });

  Future<void> _trigger(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 17))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¿Confirmas que estás experimentando este síntoma ahora mismo?',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Solo pulsa si realmente lo estás notando.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sí, confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 18))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(instruction, style: const TextStyle(fontSize: 15, height: 1.5)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, color: color, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Tu sanitario ha sido notificado.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }

    await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(uid)
      .collection('alertas')
      .add({
    'tipo': label,
    'severidad': severity,
    'fecha': Timestamp.now(),
    'vista_por_sanitario': false,
    'leida_por_paciente': false,
  });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _trigger(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15, color: color)),
                  const SizedBox(height: 4),
                  Text(description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}

// ── HISTORIAL DE ALERTAS ─────────────────────────────────────
class _AlertHistory extends StatelessWidget {
  final String uid;
  const _AlertHistory({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('alertas')
          .orderBy('fecha', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Sin alertas registradas',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final fecha = (data['fecha'] as Timestamp).toDate();
            final severidad = data['severidad'] ?? 'urgente';
            final color = severidad == 'emergencia' ? Colors.red : Colors.orange;
            final respuesta = data['respuesta_sanitario'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: color, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['tipo'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              '${fecha.day}/${fecha.month}/${fecha.year} · ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(severidad,
                            style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Eliminar alerta'),
                              content: const Text(
                                  '¿Seguro que quieres eliminar esta alerta?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('Eliminar',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await FirebaseFirestore.instance
                                .collection('usuarios')
                                .doc(uid)
                                .collection('alertas')
                                .doc(doc.id)
                                .delete();
                          }
                        },
                        child: Icon(Icons.delete_outline,
                            color: Colors.grey[400], size: 18),
                      ),
                    ],
                  ),

                  // Respuesta del sanitario
                  if (respuesta.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.medical_services_outlined,
                              color: Colors.green, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              respuesta,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ── TÍTULO DE SECCIÓN ────────────────────────────────────────
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