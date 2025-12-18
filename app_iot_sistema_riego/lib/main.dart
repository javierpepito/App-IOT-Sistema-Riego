// Importaciones necesarias para Flutter, Firebase y las pantallas de la app
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

/// Punto de entrada principal de la aplicación
/// Inicializa Firebase antes de ejecutar la app
void main() async {
  // Asegura que los widgets de Flutter estén inicializados antes de usar plugins
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa Firebase con las opciones de configuración específicas de la plataforma
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Ejecuta la aplicación
  runApp(const MainApp());
}

/// Widget principal de la aplicación
/// Configura el tema y maneja la navegación basada en el estado de autenticación
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Riego IoT',
      debugShowCheckedModeBanner: false,
      // Configuración del tema de la aplicación con Material 3
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // StreamBuilder escucha los cambios en el estado de autenticación
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Mostrando pantalla de carga mientras se verifica el estado de autenticación
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Si el usuario está autenticado (snapshot.hasData), mostrar HomeScreen
          if (snapshot.hasData) {
            return const HomeScreen();
          }

          // Si no está autenticado, mostrar LoginScreen
          return const LoginScreen();
        },
      ),
    );
  }
}
