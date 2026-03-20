import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
            selectedIcon:
                Icon(Icons.chat_bubble, color: Color(0xFF6B48FF)),
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
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'usuario';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo
            Text(
              'Hola 👋',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              email,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B48FF),
              ),
            ),
            const SizedBox(height: 24),

            // Tarjeta plan hormonal
            _Card(
              icon: Icons.medication_outlined,
              title: 'Plan hormonal',
              subtitle: 'Sin pauta asignada aún',
              color: const Color(0xFF6B48FF),
            ),
            const SizedBox(height: 16),

            // Próxima dosis
            _Card(
              icon: Icons.alarm_outlined,
              title: 'Próxima dosis',
              subtitle: 'No hay recordatorios activos',
              color: Colors.orange,
            ),
            const SizedBox(height: 16),

            // Check-in semanal
            _Card(
              icon: Icons.check_circle_outline,
              title: 'Check-in semanal',
              subtitle: 'Pendiente de completar',
              color: Colors.green,
            ),
            const SizedBox(height: 16),

            // Alertas
            _Card(
              icon: Icons.notifications_outlined,
              title: 'Alertas',
              subtitle: 'Sin alertas activas',
              color: Colors.red,
            ),
          ],
        ),
      ),
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

// ── TABS VACÍOS (por ahora) ──────────────────────────────────
class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();
  @override
  Widget build(BuildContext context) => const Center(
      child: Text('Analíticas', style: TextStyle(fontSize: 20)));
}

class _ChatTab extends StatelessWidget {
  const _ChatTab();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Chat IA', style: TextStyle(fontSize: 20)));
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Perfil', style: TextStyle(fontSize: 20)));
}