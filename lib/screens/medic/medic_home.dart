import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'hormone_plan_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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
class _PatientsTab extends StatefulWidget {
  const _PatientsTab();

  @override
  State<_PatientsTab> createState() => _PatientsTabState();
}

class _PatientsTabState extends State<_PatientsTab> {
  String _filtro = 'todos';

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
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _FilterChip(
                  label: '👥 Todos',
                  selected: _filtro == 'todos',
                  onTap: () => setState(() => _filtro = 'todos'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '🔴 Alertas',
                  selected: _filtro == 'alertas',
                  onTap: () => setState(() => _filtro = 'alertas'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '📊 Baja adherencia',
                  selected: _filtro == 'adherencia',
                  onTap: () => setState(() => _filtro = 'adherencia'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Lista de pacientes
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                final docs = snapshot.data!.docs;
                return _PatientList(docs: docs, filtro: _filtro);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── CHIP DE FILTRO ───────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2ECC71)
              : const Color(0xFF2ECC71).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF2ECC71),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ── LISTA DE PACIENTES CON FILTRO ────────────────────────────
class _PatientList extends StatefulWidget {
  final List<QueryDocumentSnapshot> docs;
  final String filtro;

  const _PatientList({required this.docs, required this.filtro});

  @override
  State<_PatientList> createState() => _PatientListState();
}

class _PatientListState extends State<_PatientList> {
  Map<String, bool> _tieneAlertas = {};
  Map<String, double> _adherencia = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(_PatientList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filtro != widget.filtro) _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final alertas = <String, bool>{};
    final adherencia = <String, double>{};

    for (final doc in widget.docs) {
      final uid = doc.id;

      // Alertas sin leer
      final alertasSnap = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('alertas')
          .where('vista_por_sanitario', isEqualTo: false)
          .get();
      alertas[uid] = alertasSnap.docs.isNotEmpty;

      // Adherencia
      final recordatoriosSnap = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('recordatorios')
          .where('activo', isEqualTo: true)
          .get();

      if (recordatoriosSnap.docs.isNotEmpty) {
        int tomados = 0;
        int total = 0;
        for (final rec in recordatoriosSnap.docs) {
          final adherenciaSnap = await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .collection('recordatorios')
              .doc(rec.id)
              .collection('adherencia')
              .limit(30)
              .get();
          for (final a in adherenciaSnap.docs) {
            total++;
            if ((a.data()['estado'] ?? '') == 'tomado') tomados++;
          }
        }
        adherencia[uid] = total > 0 ? (tomados / total * 100) : 100;
      } else {
        adherencia[uid] = 100;
      }
    }

    if (mounted) {
      setState(() {
        _tieneAlertas = alertas;
        _adherencia = adherencia;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF2ECC71)));
    }

    final filtrados = widget.docs.where((doc) {
      final uid = doc.id;
      if (widget.filtro == 'alertas') return _tieneAlertas[uid] == true;
      if (widget.filtro == 'adherencia') return (_adherencia[uid] ?? 100) < 80;
      return true;
    }).toList();

    if (filtrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              widget.filtro == 'alertas'
                  ? 'No hay alertas pendientes 🎉'
                  : 'Todos los pacientes tienen buena adherencia 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtrados.length,
      itemBuilder: (context, index) {
        final doc = filtrados[index];
        final data = doc.data() as Map<String, dynamic>;
        final uid = doc.id;
        return _PatientCard(
          uid: uid,
          data: data,
          tieneAlertas: _tieneAlertas[uid] ?? false,
          adherencia: _adherencia[uid] ?? 100,
        );
      },
    );
  }
}

// ── TARJETA PACIENTE ─────────────────────────────────────────
class _PatientCard extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> data;
  final bool tieneAlertas;
  final double adherencia;

  const _PatientCard({
    required this.uid,
    required this.data,
    required this.tieneAlertas,
    required this.adherencia,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = data['nombre'] ?? 'Sin nombre';
    final pronombres = data['pronombres'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: tieneAlertas
            ? Border.all(color: Colors.red.withOpacity(0.4), width: 2)
            : null,
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
        leading: Stack(
          children: [
            CircleAvatar(
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
            if (tieneAlertas)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(nombre,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pronombres.isNotEmpty)
              Text(pronombres,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.medication_outlined,
                    size: 12,
                    color: adherencia >= 80 ? Colors.green : Colors.orange),
                const SizedBox(width: 4),
                Text(
                  'Adherencia: ${adherencia.toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: adherencia >= 80 ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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

  Future<void> _descargarPDF(String base64, String nombre) async {
    final uri = Uri.parse('data:application/pdf;base64,$base64');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
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
                                  color: const Color(0xFF2ECC71).withOpacity(0.1),
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
                  if (data['pdf_nombre'] != null && data['pdf_base64'] != null) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _descargarPDF(data['pdf_base64'], data['pdf_nombre']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2ECC71).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF2ECC71).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.download, color: Color(0xFF2ECC71), size: 16),
                            const SizedBox(width: 6),
                            Text(data['pdf_nombre'],
                                style: const TextStyle(
                                    color: Color(0xFF2ECC71), fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
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
                        style: TextStyle(color: Colors.grey[600], fontSize: 13)),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            final color = severidad == 'emergencia' ? Colors.red : Colors.orange;

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
                          Icon(Icons.warning_amber_rounded, color: color, size: 20),
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
                        Icon(Icons.check_circle, color: Colors.grey[400], size: 16),
                        const SizedBox(width: 4),
                        Text('Vista por el sanitario',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _showResponseDialog(
                              context, uid, doc.id, data['respuesta_sanitario'] ?? ''),
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
class _MedicProfileTab extends StatefulWidget {
  const _MedicProfileTab();

  @override
  State<_MedicProfileTab> createState() => _MedicProfileTabState();
}

class _MedicProfileTabState extends State<_MedicProfileTab> {
  String _nombre = '';
  String _pronombres = '';

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
    if (doc.exists && mounted) {
      setState(() {
        _nombre = doc.data()?['nombre'] ?? '';
        _pronombres = doc.data()?['pronombres'] ?? '';
      });
    }
  }

  void _showEditProfile(BuildContext context) {
    final nombreCtrl = TextEditingController(text: _nombre);
    final pronounsCtrl = TextEditingController(text: _pronombres);
    final telefonoCtrl = TextEditingController();

    FirebaseFirestore.instance
        .collection('usuarios')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((doc) {
      telefonoCtrl.text = doc.data()?['telefono'] ?? '';
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Editar perfil',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2ECC71))),
            const SizedBox(height: 20),
            TextField(
              controller: nombreCtrl,
              decoration: InputDecoration(
                labelText: 'Nombre',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF0FFF4),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pronounsCtrl,
              decoration: InputDecoration(
                labelText: 'Pronombres',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF0FFF4),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: telefonoCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF0FFF4),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final uid = FirebaseAuth.instance.currentUser!.uid;
                  await FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(uid)
                      .update({
                    'nombre': nombreCtrl.text.trim(),
                    'pronombres': pronounsCtrl.text.trim(),
                    'telefono': telefonoCtrl.text.trim(),
                  });
                  if (context.mounted) Navigator.pop(context);
                  _loadProfile();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Guardar', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            Text(
              _nombre.isNotEmpty ? _nombre : 'Sanitario',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2ECC71)),
            ),
            if (_pronombres.isNotEmpty)
              Text(
                _pronombres,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            const SizedBox(height: 8),
            Text(user?.email ?? '',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showEditProfile(context),
              icon: const Icon(Icons.edit),
              label: const Text('Editar perfil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
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