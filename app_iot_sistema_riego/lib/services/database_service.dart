import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

/// Servicio para interactuar con Firebase Realtime Database
/// Maneja el estado del riego y las programaciones automáticas
class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Referencia al nodo 'riego' en Firebase Database
  /// Este nodo contiene: estado, manual, programaciones, etc.
  DatabaseReference get riegoRef => _db.child('riego');

  /// Stream que notifica cambios en tiempo real del estado del riego
  /// El ESP32 y la app escuchan este valor
  Stream<DatabaseEvent> get estadoRiegoStream => riegoRef.child('estado').onValue;

  /// Cambia el estado del riego manualmente (activo/desactivado)
  /// Actualiza el estado en Firebase y el ESP32 lo lee en tiempo real
  Future<void> cambiarEstadoRiego(String estado) async {
    try {
      await riegoRef.update({
        'estado': estado, // 'activo' o 'desactivado'
        'manual': true,  // Marca que el cambio fue manual (no automático)
        'ultimaActualizacion': ServerValue.timestamp, // Timestamp del servidor
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

  /// Agrega una nueva programación de riego automático
  /// El ESP32 verifica las programaciones y activa el riego a la hora indicada
  Future<void> agregarProgramacion({
    required DateTime fecha,
    required TimeOfDay hora,
    required int duracionMinutos,
  }) async {
    try {
      // Combina la fecha seleccionada con la hora
      final local = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );
      
      // Convierte a timestamp UTC en segundos (formato compatible con ESP32)
      final tsSec = local.toUtc().millisecondsSinceEpoch ~/ 1000;
      
      // Crea una nueva programación con ID único
      final programacionRef = riegoRef.child('programaciones').push();
      await programacionRef.set({
        'timestamp': tsSec,  // Momento en que debe ejecutarse
        'duracionMinutos': duracionMinutos, // Cuánto tiempo regar
        'activo': true, // Si está habilitada o pausada
        'ejecutado': false, // Si ya se ejecutó
        'createdAt': ServerValue.timestamp, // Cuándo se creó
      });
    } catch (e) {
      throw 'Error al agregar programación: $e';
    }
  }

  /// Elimina una programación específica de Firebase
  Future<void> eliminarProgramacion(String programacionId) async {
    try {
      await riegoRef.child('programaciones/$programacionId').remove();
    } catch (e) {
      throw 'Error al eliminar programación: $e';
    }
  }

  /// Activa o desactiva una programación sin eliminarla
  /// Útil para pausar temporalmente una programación
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

  /// Obtiene el estado actual del riego desde Firebase (lectura única)
  /// Retorna 'activo' o 'desactivado'
  Future<String> obtenerEstadoActual() async {
    try {
      final snapshot = await riegoRef.child('estado').get();
      if (snapshot.exists) {
        return snapshot.value as String;
      }
      // Si no existe el valor, retorna desactivado por defecto
      return 'desactivado';
    } catch (e) {
      throw 'Error al obtener estado: $e';
    }
  }
}
