import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../patient/patient_home.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _aceptado = false;
  bool _isSaving = false;

  Future<void> _aceptarConsentimiento() async {
    if (!_aceptado) return;
    setState(() => _isSaving = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .set({
      'consentimiento': {
        'aceptado': true,
        'fecha': Timestamp.now(),
        'version': '1.0',
      },
      'rol': 'paciente',
    }, SetOptions(merge: true));

    setState(() => _isSaving = false);

    if (mounted){
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => PatientHome()),
      (route) => false,
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
          'Consentimiento informado',
          style: TextStyle(
            color: Color(0xFF6B48FF),
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabecera
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B48FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined,
                            color: Color(0xFF6B48FF), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tu privacidad es importante',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B48FF),
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'Lee detenidamente antes de continuar',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _SeccionConsentimiento(
                    titulo: '1. ¿Qué es MEtanoia?',
                    contenido:
                        'MEtanoia es una aplicación de telemonitorización diseñada para apoyar el seguimiento de la terapia hormonal sustitutiva (THS) en personas transgénero. Su objetivo es facilitar la comunicación entre paciente y profesional sanitario, y NO sustituye en ningún caso la atención médica profesional.',
                  ),
                  _SeccionConsentimiento(
                    titulo: '2. Datos que recopilamos',
                    contenido:
                        'Con tu consentimiento, recopilamos los siguientes datos personales y clínicos:\n\n• Datos de identificación: nombre, pronombres, fecha de nacimiento, teléfono\n• Datos clínicos: parámetros analíticos, síntomas, adherencia al tratamiento\n• Datos fisiológicos: registros de check-ins semanales\n• Datos de uso: alertas activadas, recordatorios configurados\n\nEstos datos son necesarios para el funcionamiento de la aplicación.',
                  ),
                  _SeccionConsentimiento(
                    titulo: '3. Cómo usamos tus datos',
                    contenido:
                        'Tus datos se utilizan exclusivamente para:\n\n• Mostrar tu información clínica a tu sanitario asignado\n• Generar alertas automáticas en caso de valores fuera de rango\n• Permitir el seguimiento remoto de tu tratamiento\n• Mejorar la calidad asistencial de tu terapia hormonal\n\nNunca venderemos ni cederemos tus datos a terceros con fines comerciales.',
                  ),
                  _SeccionConsentimiento(
                    titulo: '4. Base legal (RGPD)',
                    contenido:
                        'El tratamiento de tus datos se realiza conforme al Reglamento General de Protección de Datos (RGPD) de la UE, bajo la base legal de tu consentimiento expreso y el interés legítimo en la prestación de servicios de salud.\n\nTus datos se almacenan en servidores ubicados en Europa (Madrid, España) mediante Google Firebase.',
                  ),
                  _SeccionConsentimiento(
                    titulo: '5. Tus derechos',
                    contenido:
                        'Tienes derecho a:\n\n• Acceder a tus datos personales\n• Rectificar datos incorrectos\n• Solicitar la eliminación de tus datos\n• Oponerte al tratamiento de tus datos\n• Portabilidad de tus datos\n\nPuedes ejercer estos derechos contactando con tu sanitario o a través de la configuración de la aplicación.',
                  ),
                  _SeccionConsentimiento(
                    titulo: '6. Seguridad',
                    contenido:
                        'Implementamos medidas de seguridad técnicas y organizativas para proteger tus datos, incluyendo autenticación segura, cifrado en tránsito y almacenamiento seguro en la nube.',
                  ),
                  _SeccionConsentimiento(
                    titulo: '7. Asistente de IA',
                    contenido:
                        'MEtanoia incluye un asistente de inteligencia artificial para responder dudas frecuentes sobre la THS. Este asistente NO puede ajustar dosis, interpretar resultados clínicos individuales ni sustituir la consulta médica. En situaciones de emergencia, siempre llama al 112.',
                  ),
                  const SizedBox(height: 24),

                  // Checkbox de aceptación
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _aceptado
                            ? const Color(0xFF6B48FF).withOpacity(0.5)
                            : Colors.grey.withOpacity(0.3),
                        width: _aceptado ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _aceptado,
                          onChanged: (v) =>
                              setState(() => _aceptado = v ?? false),
                          activeColor: const Color(0xFF6B48FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'He leído y acepto el consentimiento informado. Entiendo que mis datos serán tratados conforme a lo descrito y que puedo retirar mi consentimiento en cualquier momento.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Botón de aceptar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _aceptado && !_isSaving
                    ? _aceptarConsentimiento
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B48FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
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
                    : const Text(
                        'Aceptar y continuar',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionConsentimiento extends StatelessWidget {
  final String titulo;
  final String contenido;

  const _SeccionConsentimiento({
    required this.titulo,
    required this.contenido,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B48FF),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            contenido,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}