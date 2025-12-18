// Importaciones necesarias para la pantalla principal
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'login_screen.dart';
import 'schedule_screen.dart';

/// Pantalla principal de control del sistema de riego
/// Permite activar/desactivar el riego manualmente y ver el estado en tiempo real
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Servicios para autenticación y base de datos
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  
  // Estado actual del sistema de riego
  String _estadoRiego = 'desactivado';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Carga el estado inicial del riego desde Firebase
    _cargarEstadoInicial();
  }

  /// Carga el estado inicial del riego desde Firebase
  Future<void> _cargarEstadoInicial() async {
    try {
      // Obtiene el estado actual del riego desde la base de datos
      final estado = await _databaseService.obtenerEstadoActual();
      if (mounted) {
        setState(() => _estadoRiego = estado);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Cambia el estado del riego entre activo y desactivado
  /// Actualiza el valor en Firebase y el ESP32 lo lee en tiempo real
  Future<void> _cambiarEstado() async {
    setState(() => _isLoading = true);

    try {
      // Alterna entre activo y desactivado
      final nuevoEstado = _estadoRiego == 'activo' ? 'desactivado' : 'activo';
      
      // Actualiza el estado en Firebase Database
      await _databaseService.cambiarEstadoRiego(nuevoEstado);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Riego ${nuevoEstado == "activo" ? "activado" : "desactivado"}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Cierra la sesión del usuario y regresa a la pantalla de login
  Future<void> _cerrarSesion() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Riego'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Programar riego',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ScheduleScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      // StreamBuilder escucha cambios en tiempo real del estado del riego en Firebase
      body: StreamBuilder<DatabaseEvent>(
        stream: _databaseService.estadoRiegoStream,
        builder: (context, snapshot) {
          // Actualiza el estado local cuando hay cambios en Firebase
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            _estadoRiego = snapshot.data!.snapshot.value.toString();
          }

          final isActivo = _estadoRiego == 'activo';

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Indicador visual del estado
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActivo ? Colors.blue.shade100 : Colors.grey.shade200,
                      border: Border.all(
                        color: isActivo ? Colors.blue.shade700 : Colors.grey.shade400,
                        width: 8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isActivo
                              ? Colors.blue.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        isActivo ? Icons.water_drop : Icons.water_drop_outlined,
                        size: 100,
                        color: isActivo ? Colors.blue.shade700 : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Estado actual
                  Text(
                    'Estado del Sistema',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isActivo ? 'ACTIVO' : 'DESACTIVADO',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isActivo ? Colors.blue.shade700 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Botón de control
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _cambiarEstado,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Icon(
                              isActivo ? Icons.stop : Icons.play_arrow,
                              size: 32,
                            ),
                      label: Text(
                        isActivo ? 'Desactivar Riego' : 'Activar Riego',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActivo ? Colors.red.shade600 : Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Botón de programación
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ScheduleScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.schedule),
                      label: const Text(
                        'Programar Riego',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                        side: BorderSide(color: Colors.blue.shade700, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Información adicional
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'El ESP32 lee el estado en tiempo real desde Firebase',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              Icon(Icons.schedule, color: Colors.blue.shade700),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Puedes programar el riego automático desde el calendario',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
