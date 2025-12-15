import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _databaseService = DatabaseService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _duracionMinutos = 30;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  Future<void> _agregarProgramacion() async {
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
      final horaFormateada =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      await _databaseService.agregarProgramacion(
        fecha: _selectedDay!,
        hora: horaFormateada,
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

  Future<void> _seleccionarHora() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
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

    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _mostrarDialogoDuracion() async {
    int? duracionTemp = _duracionMinutos;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duración del riego'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${duracionTemp ?? 30} minutos',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Slider(
                  value: (duracionTemp ?? 30).toDouble(),
                  min: 5,
                  max: 120,
                  divisions: 23,
                  label: '${duracionTemp ?? 30} min',
                  onChanged: (value) {
                    setStateDialog(() => duracionTemp = value.toInt());
                  },
                ),
                const Text('5 - 120 minutos'),
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
              setState(() => _duracionMinutos = duracionTemp ?? 30);
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
      body: Column(
        children: [
          // Calendario
          Card(
            margin: const EdgeInsets.all(8.0),
            elevation: 2,
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
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

          // Lista de programaciones
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _databaseService.programacionesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'No hay programaciones.\nAgrega una nueva usando el calendario.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }

                final programacionesMap =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                final programaciones = programacionesMap.entries.toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: programaciones.length,
                  itemBuilder: (context, index) {
                    final entry = programaciones[index];
                    final key = entry.key;
                    final data = entry.value as Map<dynamic, dynamic>;

                    final fecha = DateTime.parse(data['fecha']);
                    final hora = data['hora'];
                    final duracion = data['duracionMinutos'];
                    final activo = data['activo'] ?? true;
                    final ejecutado = data['ejecutado'] ?? false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: ejecutado
                              ? Colors.grey
                              : activo
                                  ? Colors.blue.shade700
                                  : Colors.orange,
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
                          '${DateFormat('dd/MM/yyyy').format(fecha)} - $hora',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Duración: $duracion minutos'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
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
          ),
        ],
      ),
    );
  }
}
