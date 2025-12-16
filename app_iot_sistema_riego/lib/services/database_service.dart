import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Obtener referencia al estado del riego
  DatabaseReference get riegoRef => _db.child('riego');

  // Stream del estado del riego
  Stream<DatabaseEvent> get estadoRiegoStream => riegoRef.child('estado').onValue;

  // Cambiar estado del riego manualmente
  Future<void> cambiarEstadoRiego(String estado) async {
    try {
      await riegoRef.update({
        'estado': estado,
        'manual': true,  // Activar modo manual
        'ultimaActualizacion': ServerValue.timestamp,
      });
    } catch (e) {
      throw 'Error al actualizar estado: $e';
    }
  }

  // Cambiar modo manual/automático
  Future<void> setModoManual(bool manual) async {
    try {
      await riegoRef.update({
        'manual': manual,
      });
    } catch (e) {
      throw 'Error al actualizar modo: $e';
    }
  }

  // Obtener modo actual
  Stream<DatabaseEvent> get modoManualStream => riegoRef.child('manual').onValue;

  // Obtener programaciones
  Stream<DatabaseEvent> get programacionesStream => 
      riegoRef.child('programaciones').onValue;

  // Agregar programación
  Future<void> agregarProgramacion({
    required DateTime fecha,
    required TimeOfDay hora,
    required int duracionMinutos,
  }) async {
    try {
      // Crear DateTime local combinando fecha y hora
      final local = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );
      
      // Convertir a timestamp UTC en segundos
      final tsSec = local.toUtc().millisecondsSinceEpoch ~/ 1000;
      
      final programacionRef = riegoRef.child('programaciones').push();
      await programacionRef.set({
        'timestamp': tsSec,  // Timestamp en segundos UTC
        'duracionMinutos': duracionMinutos,
        'activo': true,
        'ejecutado': false,
        'createdAt': ServerValue.timestamp,
      });
    } catch (e) {
      throw 'Error al agregar programación: $e';
    }
  }

  // Eliminar programación
  Future<void> eliminarProgramacion(String programacionId) async {
    try {
      await riegoRef.child('programaciones/$programacionId').remove();
    } catch (e) {
      throw 'Error al eliminar programación: $e';
    }
  }

  // Actualizar programación
  Future<void> actualizarProgramacion({
    required String programacionId,
    required bool activo,
  }) async {
    try {
      await riegoRef.child('programaciones/$programacionId').update({
        'activo': activo,
      });
    } catch (e) {
      throw 'Error al actualizar programación: $e';
    }
  }

  // Obtener estado actual del riego
  Future<String> obtenerEstadoActual() async {
    try {
      final snapshot = await riegoRef.child('estado').get();
      if (snapshot.exists) {
        return snapshot.value as String;
      }
      return 'desactivado';
    } catch (e) {
      throw 'Error al obtener estado: $e';
    }
  }
}
