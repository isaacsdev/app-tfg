import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'analytics_screen.dart';
import 'chat_screen.dart';
import 'checkin_screen.dart';
import 'reminders_screen.dart';
import 'red_flags_screen.dart';

class PatientHome extends StatefulWidget {
  const PatientHome({super.key});

  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _HomeTab(),
    const _AnalyticsTab(),
    const _ChatTab(),
    const _ProfileTab(),
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
        indicatorColor: const Color(0xFF6B48FF).withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF6B48FF)),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF6B48FF)),
            label: 'Analíticas',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: Color(0xFF6B48FF)),
            label: 'Chat IA',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF6B48FF)),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ── TAB INICIO ──────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  String _nombre = '';
  String _proximoRecordatorio = '';
  String _proximaHora = '';

  @override
  void initState() {
    super.initState();
    _loadNombre();
    _loadProximoRecordatorio();
  }

  Future<void> _loadNombre() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();
    if (doc.exists && mounted) {
      setState(() {
        _nombre = doc.data()?['nombre'] ?? '';
      });
    }
  }

  Future<void> _loadProximoRecordatorio() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('recordatorios')
        .where('activo', isEqualTo: true)
        .get();

    if (snapshot.docs.isNotEmpty && mounted) {
      final total = snapshot.docs.length;
      final ahora =
          '${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}';

      String proximaHora = '';
      for (final doc in snapshot.docs) {
        final hora = doc.data()['hora'] ?? '';
        if (hora.isNotEmpty) {
          if (proximaHora.isEmpty || hora.compareTo(ahora) > 0) {
            proximaHora = hora;
          }
        }
      }

      setState(() {
        _proximoRecordatorio =
            '$total recordatorio${total > 1 ? 's' : ''} activo${total > 1 ? 's' : ''}';
        _proximaHora =
            proximaHora.isNotEmpty ? 'próximo a las $proximaHora' : '';
      });
    } else if (mounted) {
      setState(() {
        _proximoRecordatorio = '';
        _proximaHora = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        _nombre.isNotEmpty ? _nombre : user?.email ?? 'usuario';

    return SafeArea(
      child: Column(
        children: [
          // Banner de respuesta del sanitario
          _AlertResponseBanner(uid: user!.uid),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola 👋',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B48FF),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Card(
                    icon: Icons.medication_outlined,
                    title: 'Plan hormonal',
                    subtitle: 'Sin pauta asignada aún',
                    color: const Color(0xFF6B48FF),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RemindersScreen()),
                    ),
                    child: _Card(
                      icon: Icons.alarm_outlined,
                      title: 'Próxima dosis',
                      subtitle: _proximoRecordatorio.isNotEmpty
                          ? '$_proximoRecordatorio · $_proximaHora'
                          : 'No hay recordatorios activos',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CheckinScreen()),
                    ),
                    child: _Card(
                      icon: Icons.check_circle_outline,
                      title: 'Check-in semanal',
                      subtitle: 'Pendiente de completar',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RedFlagsScreen()),
                    ),
                    child: _Card(
                      icon: Icons.notifications_outlined,
                      title: 'Alertas',
                      subtitle: 'Sin alertas activas',
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── BANNER RESPUESTA SANITARIO ───────────────────────────────
class _AlertResponseBanner extends StatelessWidget {
  final String uid;
  const _AlertResponseBanner({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('alertas')
          .where('vista_por_sanitario', isEqualTo: true)
          .where('leida_por_paciente', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final doc = snapshot.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        final respuesta = data['respuesta_sanitario'] ?? '';
        final tipo = data['tipo'] ?? '';

        if (respuesta.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.medical_services,
                      color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Tu sanitario ha respondido a tu alerta',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(uid)
                          .collection('alertas')
                          .doc(doc.id)
                          .update({'leida_por_paciente': true});
                    },
                    child: const Icon(Icons.close,
                        color: Colors.green, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Sobre: $tipo',
                style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 4),
              Text(
                respuesta,
                style:
                    const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── TARJETA REUTILIZABLE ─────────────────────────────────────
class _Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _Card({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }
}

// ── TABS ─────────────────────────────────────────────────────
class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();
  @override
  Widget build(BuildContext context) => const AnalyticsScreen();
}

class _ChatTab extends StatelessWidget {
  const _ChatTab();
  @override
  Widget build(BuildContext context) => const ChatScreen();
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) => const ProfileScreen();
}