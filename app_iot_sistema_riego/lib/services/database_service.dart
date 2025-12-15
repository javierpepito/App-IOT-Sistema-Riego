import 'package:firebase_database/firebase_database.dart';

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
        'manual': true,
        'ultimaActualizacion': ServerValue.timestamp,
      });
    } catch (e) {
      throw 'Error al actualizar estado: $e';
    }
  }

  // Obtener programaciones
  Stream<DatabaseEvent> get programacionesStream => 
      riegoRef.child('programaciones').onValue;

  // Agregar programación
  Future<void> agregarProgramacion({
    required DateTime fecha,
    required String hora,
    required int duracionMinutos,
  }) async {
    try {
      final programacionRef = riegoRef.child('programaciones').push();
      await programacionRef.set({
        'fecha': fecha.toIso8601String(),
        'hora': hora,
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
