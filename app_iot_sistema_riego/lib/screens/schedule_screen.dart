// Importaciones necesarias para la pantalla de programación
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

/// Pantalla de programación de riego
/// Permite a los usuarios programar el riego automático usando un calendario
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // Servicio para interactuar con Firebase Database
  final _databaseService = DatabaseService();
  
  // Configuración del calendario
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Configuración de la programación
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _duracionMinutos = 3; // Duración del riego en minutos (1-5)

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  /// Agrega una nueva programación de riego a Firebase
  /// El ESP32 leerá esta programación y activará el riego automáticamente
  Future<void> _agregarProgramacion() async {
    // Valida que se haya seleccionado una fecha
    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una fecha'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Guarda la programación en Firebase Database
      await _databaseService.agregarProgramacion(
        fecha: _selectedDay!,
        hora: _selectedTime,
        duracionMinutos: _duracionMinutos,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Programación agregada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Muestra el selector de hora y actualiza la hora seleccionada
  Future<void> _seleccionarHora() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        // Personaliza el tema del selector de hora
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
            ),
          ),
          child: child!,
        );
      },
    );

    // Actualiza la hora si el usuario seleccionó una nueva
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  /// Muestra un diálogo para seleccionar la duración del riego (1-5 minutos)
  Future<void> _mostrarDialogoDuracion() async {
    int? duracionTemp = _duracionMinutos;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duración del riego'),
        // StatefulBuilder permite actualizar el estado dentro del diálogo
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${duracionTemp ?? 3} minutos',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Slider(
                  value: (duracionTemp ?? 3).toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '${duracionTemp ?? 3} min',
                  onChanged: (value) {
                    setStateDialog(() => duracionTemp = value.toInt());
                  },
                ),
                const Text('1 - 5 minutos'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _duracionMinutos = duracionTemp ?? 3);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Programar Riego'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Calendario para seleccionar la fecha de riego
            Card(
              margin: const EdgeInsets.all(8.0),
              elevation: 2,
              // Widget de calendario interactivo
              child: TableCalendar(
              firstDay: DateTime.now(), // No permite programar fechas pasadas
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              // Callback cuando el usuario selecciona un día
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              // Callback cuando se cambia el formato del calendario
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              // Callback cuando se cambia de mes
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.blue.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonDecoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                formatButtonTextStyle: const TextStyle(color: Colors.white),
              ),
            ),
          ),

          // Configuración de programación
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuración',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20),
                    
                    // Fecha seleccionada
                    ListTile(
                      leading: Icon(Icons.calendar_today, color: Colors.blue.shade700),
                      title: const Text('Fecha'),
                      subtitle: Text(
                        _selectedDay != null
                            ? DateFormat('dd/MM/yyyy').format(_selectedDay!)
                            : 'No seleccionada',
                      ),
                    ),
                    
                    // Hora
                    ListTile(
                      leading: Icon(Icons.access_time, color: Colors.blue.shade700),
                      title: const Text('Hora'),
                      subtitle: Text(_selectedTime.format(context)),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _seleccionarHora,
                      ),
                    ),
                    
                    // Duración
                    ListTile(
                      leading: Icon(Icons.timer, color: Colors.blue.shade700),
                      title: const Text('Duración'),
                      subtitle: Text('$_duracionMinutos minutos'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _mostrarDialogoDuracion,
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Botón agregar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _agregarProgramacion,
                        icon: const Icon(Icons.add),
                        label: const Text(
                          'Agregar Programación',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Lista de programaciones guardadas en Firebase
          // Escucha cambios en tiempo real
          StreamBuilder<DatabaseEvent>(
            stream: _databaseService.programacionesStream,
            builder: (context, snapshot) {
              // Muestra indicador de carga mientras se obtienen los datos
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              // Muestra mensaje si no hay programaciones
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'No hay programaciones.\nAgrega una nueva usando el calendario.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              // Convierte el Map de Firebase a una lista
              final programacionesMap =
                  snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              final programaciones = programacionesMap.entries.toList();

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: programaciones.length,
                itemBuilder: (context, index) {
                  final entry = programaciones[index];
                  final key = entry.key; // ID único de la programación
                  final data = entry.value as Map<dynamic, dynamic>;

                  // Convierte el timestamp (segundos UTC) a DateTime local
                  // Firebase guarda en segundos, necesitamos milisegundos
                  final timestampSec = data['timestamp'] ?? 0;
                  final fechaHora = DateTime.fromMillisecondsSinceEpoch(
                    timestampSec * 1000,
                    isUtc: true,
                  ).toLocal();
                  
                  // Obtiene los datos de la programación
                  final duracion = data['duracionMinutos'] ?? 1;
                  final activo = data['activo'] ?? true; // Si está habilitada
                  final ejecutado = data['ejecutado'] ?? false; // Si ya se ejecutó

                  // Tarjeta para cada programación
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      // Icono que indica el estado de la programación
                      leading: CircleAvatar(
                        backgroundColor: ejecutado
                            ? Colors.grey // Gris si ya se ejecutó
                            : activo
                                ? Colors.blue.shade700 // Azul si está activa
                                : Colors.orange, // Naranja si está pausada
                        child: Icon(
                          ejecutado
                              ? Icons.check
                              : activo
                                  ? Icons.schedule
                                  : Icons.pause,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(fechaHora),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Duración: $duracion minutos'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Switch para activar/desactivar (solo si no se ejecutó)
                            if (!ejecutado)
                              Switch(
                                value: activo,
                                activeColor: Colors.blue.shade700,
                                onChanged: (value) {
                                  _databaseService.actualizarProgramacion(
                                    programacionId: key,
                                    activo: value,
                                  );
                                },
                              ),
                            // Botón para eliminar la programación
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                // Muestra diálogo de confirmación antes de eliminar
                                final confirmar = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Eliminar programación'),
                                    content: const Text(
                                        '¿Estás seguro de eliminar esta programación?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                );

                                // Si el usuario confirmó, elimina la programación
                                if (confirmar == true) {
                                  await _databaseService
                                      .eliminarProgramacion(key);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
