import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'hormone_plan_screen.dart';

class MedicHome extends StatefulWidget {
  const MedicHome({super.key});

  @override
  State<MedicHome> createState() => _MedicHomeState();
}

class _MedicHomeState extends State<MedicHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _PatientsTab(),
    const _MedicProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF2ECC71).withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: Color(0xFF2ECC71)),
            label: 'Pacientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF2ECC71)),
            label: 'Mi perfil',
          ),
        ],
      ),
    );
  }
}

// ── TAB PACIENTES ────────────────────────────────────────────
class _PatientsTab extends StatelessWidget {
  const _PatientsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0FFF4),
        elevation: 0,
        title: const Text(
          'Mis pacientes',
          style: TextStyle(color: Color(0xFF2ECC71), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF2ECC71)),
            onPressed: () async => await FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .where('rol', isEqualTo: 'paciente')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No hay pacientes registrados',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16)),
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
              return _PatientCard(uid: doc.id, data: data);
            },
          );
        },
      ),
    );
  }
}

// ── TARJETA PACIENTE ─────────────────────────────────────────
class _PatientCard extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> data;

  const _PatientCard({required this.uid, required this.data});

  @override
  Widget build(BuildContext context) {
    final nombre = data['nombre'] ?? 'Sin nombre';
    final pronombres = data['pronombres'] ?? '';
    final telefono = data['telefono'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2ECC71).withOpacity(0.1),
          radius: 28,
          child: Text(
            nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Color(0xFF2ECC71),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        title: Text(nombre,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pronombres.isNotEmpty)
              Text(pronombres,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            if (telefono.isNotEmpty)
              Text(telefono,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF2ECC71)),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientDetailScreen(uid: uid, nombre: nombre),
          ),
        ),
      ),
    );
  }
}

// ── DETALLE DEL PACIENTE ─────────────────────────────────────
class PatientDetailScreen extends StatelessWidget {
  final String uid;
  final String nombre;

  const PatientDetailScreen({super.key, required this.uid, required this.nombre});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FFF4),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF0FFF4),
          elevation: 0,
          title: Text(nombre,
              style: const TextStyle(
                  color: Color(0xFF2ECC71), fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2ECC71)),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF2ECC71),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF2ECC71),
            tabs: [
              Tab(text: 'Analíticas'),
              Tab(text: 'Check-ins'),
              Tab(text: 'Alertas'),
            ],
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.medication, color: Color(0xFF2ECC71)),
              label: const Text(
                'Plan hormonal',
                style: TextStyle(color: Color(0xFF2ECC71)),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HormonePlanScreen(
                    uid: uid,
                    nombrePaciente: nombre,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _PatientAnalytics(uid: uid),
            _PatientCheckins(uid: uid),
            _PatientAlerts(uid: uid),
          ],
        ),
      ),
    );
  }
}

// ── ANALÍTICAS DEL PACIENTE ──────────────────────────────────
class _PatientAnalytics extends StatelessWidget {
  final String uid;
  const _PatientAnalytics({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('analiticas')
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ECC71)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text('Sin analíticas registradas',
                  style: TextStyle(color: Colors.grey[600])));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final fecha = data['fecha'] != null
                ? (data['fecha'] as Timestamp).toDate()
                : DateTime.now();
            final valores = data['valores'] as Map<String, dynamic>? ?? {};
            final validada = data['validada'] ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${fecha.day}/${fecha.month}/${fecha.year}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2ECC71))),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
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
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (!validada) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                await FirebaseFirestore.instance
                                    .collection('usuarios')
                                    .doc(uid)
                                    .collection('analiticas')
                                    .doc(doc.id)
                                    .update({'validada': true});
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Analítica validada'),
                                      backgroundColor: Color(0xFF2ECC71),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF2ECC71).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('Validar',
                                    style: TextStyle(
                                        color: Color(0xFF2ECC71),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: valores.entries.map((e) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${e.key}: ${e.value}',
                            style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── CHECK-INS DEL PACIENTE ───────────────────────────────────
class _PatientCheckins extends StatelessWidget {
  final String uid;
  const _PatientCheckins({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('checkins')
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ECC71)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text('Sin check-ins registrados',
                  style: TextStyle(color: Colors.grey[600])));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final fecha = data['fecha'] != null
                ? (data['fecha'] as Timestamp).toDate()
                : DateTime.now();
            final valores = data['valores'] as Map<String, dynamic>? ?? {};
            final notas = data['notas'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${fecha.day}/${fecha.month}/${fecha.year}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2ECC71),
                          fontSize: 15)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: valores.entries.map((e) {
                      final valor = (e.value as num).toInt();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2ECC71).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${e.key}: $valor/5',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF2ECC71))),
                      );
                    }).toList(),
                  ),
                  if (notas.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Notas: $notas',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── ALERTAS DEL PACIENTE ─────────────────────────────────────
class _PatientAlerts extends StatelessWidget {
  final String uid;
  const _PatientAlerts({required this.uid});

  void _showResponseDialog(
      BuildContext context, String uid, String docId, String current) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar respuesta',
            style: TextStyle(color: Color(0xFF2ECC71))),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Escribe tus instrucciones para el paciente...',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: const Color(0xFFF0FFF4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(uid)
                  .collection('alertas')
                  .doc(docId)
                  .update({'respuesta_sanitario': controller.text.trim()});
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('alertas')
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ECC71)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text('Sin alertas registradas',
                  style: TextStyle(color: Colors.grey[600])));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final fecha = (data['fecha'] as Timestamp).toDate();
            final severidad = data['severidad'] ?? 'urgente';
            final vistaPor = data['vista_por_sanitario'] ?? false;
            final color =
                severidad == 'emergencia' ? Colors.red : Colors.orange;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: vistaPor
                      ? Colors.grey.withOpacity(0.2)
                      : color.withOpacity(0.4),
                  width: vistaPor ? 1 : 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: color, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            data['tipo'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: vistaPor ? Colors.grey : Colors.black87,
                            ),
                          ),
                        ],
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
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${fecha.day}/${fecha.month}/${fecha.year} a las ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),

                  // Respuesta existente
                  if (data['respuesta_sanitario'] != null &&
                      (data['respuesta_sanitario'] as String).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFF2ECC71).withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.medical_services_outlined,
                              color: Color(0xFF2ECC71), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(data['respuesta_sanitario'],
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF2ECC71))),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  if (!vistaPor)
                    _AlertResponseForm(uid: uid, docId: doc.id)
                  else
                    Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.grey[400], size: 16),
                        const SizedBox(width: 4),
                        Text('Vista por el sanitario',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 12)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _showResponseDialog(
                              context,
                              uid,
                              doc.id,
                              data['respuesta_sanitario'] ?? ''),
                          child: Text(
                            'Editar respuesta',
                            style: TextStyle(
                              color: const Color(0xFF2ECC71),
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── FORMULARIO RESPUESTA ALERTA ───────────────────────────────
class _AlertResponseForm extends StatefulWidget {
  final String uid;
  final String docId;
  const _AlertResponseForm({required this.uid, required this.docId});

  @override
  State<_AlertResponseForm> createState() => _AlertResponseFormState();
}

class _AlertResponseFormState extends State<_AlertResponseForm> {
  final _controller = TextEditingController();
  bool _isSaving = false;

  Future<void> _save() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.uid)
        .collection('alertas')
        .doc(widget.docId)
        .update({
      'vista_por_sanitario': true,
      'respuesta_sanitario': _controller.text.trim(),
    });
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Escribe instrucciones para el paciente...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xFFF0FFF4),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Marcar como vista y responder'),
          ),
        ),
      ],
    );
  }
}

// ── PERFIL SANITARIO ─────────────────────────────────────────
class _MedicProfileTab extends StatelessWidget {
  const _MedicProfileTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0FFF4),
        elevation: 0,
        title: const Text('Mi perfil',
            style: TextStyle(
                color: Color(0xFF2ECC71), fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: Color(0xFF2ECC71),
              child: Icon(Icons.person, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Dra. Rojas',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2ECC71))),
            const SizedBox(height: 8),
            Text(user?.email ?? '',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async => await FirebaseAuth.instance.signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
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