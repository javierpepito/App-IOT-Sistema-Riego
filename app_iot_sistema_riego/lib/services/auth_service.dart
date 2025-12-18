import 'package:firebase_auth/firebase_auth.dart';

/// Servicio de autenticación con Firebase
/// Maneja login, registro, cierre de sesión y manejo de errores
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream que notifica cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Obtiene el usuario actualmente autenticado
  User? get currentUser => _auth.currentUser;

  /// Inicia sesión con correo electrónico y contraseña
  /// Retorna UserCredential si es exitoso
  /// Lanza una excepción con mensaje en español si falla
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Registra un nuevo usuario con correo electrónico y contraseña
  /// Retorna UserCredential si es exitoso
  /// Lanza una excepción con mensaje en español si falla
  Future<UserCredential?> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Cierra la sesión del usuario actual
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Convierte los códigos de error de Firebase a mensajes en español
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No se encontró un usuario con ese correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'invalid-email':
        return 'Correo electrónico inválido.';
      default:
        return 'Error: ${e.message}';
    }
  }
}
