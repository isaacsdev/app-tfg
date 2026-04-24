import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Madrid'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> programarRecordatorio({
    required int id,
    required String medicamento,
    required String dosis,
    required String hora,
  }) async {
    if (kIsWeb) return;
    final partes = hora.split(':');
    final horaInt = int.parse(partes[0]);
    final minutoInt = int.parse(partes[1]);

    final ahora = tz.TZDateTime.now(tz.local);
    var fechaProgramada = tz.TZDateTime(
      tz.local,
      ahora.year,
      ahora.month,
      ahora.day,
      horaInt,
      minutoInt,
    );

    if (fechaProgramada.isBefore(ahora)) {
      fechaProgramada = fechaProgramada.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      '💊 Recordatorio de dosis',
      '$medicamento · $dosis',
      fechaProgramada,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'recordatorios_ths',
          'Recordatorios THS',
          channelDescription: 'Notificaciones de dosis de medicación',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> mostrarNotificacion({
    required int id,
    required String titulo,
    required String cuerpo,
  }) async {
    if (kIsWeb) return;
    await _plugin.show(
      id,
      titulo,
      cuerpo,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'respuestas_sanitario',
          'Respuestas del sanitario',
          channelDescription: 'Notificaciones cuando tu sanitario responde',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
    );
  }

  Future<void> cancelarRecordatorio(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id);
  }

  Future<void> cancelarTodos() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }
}