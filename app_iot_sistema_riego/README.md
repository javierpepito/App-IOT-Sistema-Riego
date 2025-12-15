# 🌱 Sistema de Riego IoT con Flutter y ESP32

Aplicación móvil Flutter para controlar un sistema de riego inteligente mediante Firebase Realtime Database y ESP32.

## 📋 Características

- ✅ **Autenticación de usuarios** con Firebase Authentication
- ✅ **Control manual** del riego en tiempo real
- ✅ **Programación automática** con calendario
- ✅ **Sincronización en tiempo real** entre app y ESP32
- ✅ **Interfaz intuitiva** con Material Design 3

## 🏗️ Arquitectura

```
┌─────────────────┐
│   App Flutter   │ ←→ Firebase Auth
│                 │
│  • Login/Signup │
│  • Control      │
│  • Calendario   │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  Firebase RTDB  │
│                 │
│  /riego/estado  │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│     ESP32       │
│                 │
│  • Lee estado   │
│  • Control relé │
└─────────────────┘
```

## 🚀 Inicio Rápido

### Prerrequisitos

- Flutter 3.9.2 o superior
- Dart 3.0 o superior
- Cuenta de Firebase
- ESP32 con WiFi
- Android Studio / VS Code

### Instalación

1. **Clonar el repositorio**
   ```bash
   git clone <tu-repositorio>
   cd app_iot_sistema_riego
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar Firebase**
   ```bash
   # Instalar FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configurar Firebase (sigue las instrucciones)
   flutterfire configure
   ```
   
   Esto generará automáticamente `lib/firebase_options.dart`

4. **Configurar Realtime Database**
   - Ve a [Firebase Console](https://console.firebase.google.com/)
   - Selecciona tu proyecto
   - Ve a Realtime Database → Crear base de datos
   - Configura las reglas de seguridad (ver [FIREBASE_SETUP.md](FIREBASE_SETUP.md))

5. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

## 📱 Pantallas de la Aplicación

### 1. Login / Registro
- Autenticación con email y contraseña
- Validación de campos
- Manejo de errores

### 2. Pantalla Principal (Home)
- **Estado en tiempo real** del riego (Activo/Desactivado)
- **Indicador visual** con animaciones
- **Botón de control** para activar/desactivar manualmente
- **Acceso rápido** al calendario de programación

### 3. Calendario de Programación
- **Calendario interactivo** para seleccionar fechas
- **Configuración de hora** con TimePicker
- **Duración personalizable** (5-120 minutos)
- **Lista de programaciones** con opción de activar/desactivar/eliminar

## 🔧 Configuración de Firebase

### Estructura de la Base de Datos

```json
{
  "riego": {
    "estado": "desactivado",
    "manual": true,
    "ultimaActualizacion": 1702651200000,
    "programaciones": {
      "-NxYzAbC123": {
        "fecha": "2025-12-20T00:00:00.000Z",
        "hora": "08:30",
        "duracionMinutos": 30,
        "activo": true,
        "ejecutado": false
      }
    }
  }
}
```

### Reglas de Seguridad

```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null",
    "riego": {
      ".read": true,
      ".write": "auth != null"
    }
  }
}
```

Para más detalles, consulta [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

## 🔌 Configuración del ESP32

### Hardware Necesario
- ESP32 (cualquier modelo con WiFi)
- Relé de 5V
- Bomba de agua o electroválvula
- Fuente de alimentación

### Conexiones
```
ESP32 GPIO 5  → Relé (señal)
ESP32 GND     → Relé GND
ESP32 VCC     → Relé VCC (5V)
```

### Código del ESP32

El código completo y las instrucciones están en [ESP32_CODE.md](ESP32_CODE.md)

**Librerías necesarias**:
- Firebase ESP32 Client by Mobizt
- WiFi (incluida)
- ArduinoJson

**Configuración básica**:
```cpp
#define WIFI_SSID "TU_WIFI"
#define WIFI_PASSWORD "TU_PASSWORD"
#define FIREBASE_HOST "tu-proyecto.firebaseio.com"
```

## 📦 Dependencias

```yaml
dependencies:
  firebase_core: ^3.8.1
  firebase_auth: ^5.3.4
  firebase_database: ^11.2.1
  table_calendar: ^3.1.2
  intl: ^0.19.0
```

## 🗂️ Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada
├── services/
│   ├── auth_service.dart       # Servicio de autenticación
│   └── database_service.dart   # Servicio de base de datos
└── screens/
    ├── login_screen.dart       # Pantalla de login
    ├── register_screen.dart    # Pantalla de registro
    ├── home_screen.dart        # Pantalla principal
    └── schedule_screen.dart    # Pantalla de calendario
```

## 🎯 Uso de la Aplicación

### Control Manual

1. Inicia sesión en la aplicación
2. En la pantalla principal, presiona el botón "Activar Riego"
3. El ESP32 detectará el cambio y activará el relé
4. El estado se actualiza en tiempo real en todos los dispositivos

### Programación Automática

1. Presiona el botón "Programar Riego" o el ícono de calendario
2. Selecciona la fecha en el calendario
3. Configura la hora de inicio
4. Ajusta la duración del riego
5. Presiona "Agregar Programación"
6. El ESP32 verificará cada minuto si hay programaciones y las ejecutará automáticamente

## 🔄 Flujo de Datos

```
Usuario → App Flutter → Firebase RTDB → ESP32 → Relé → Bomba
                ↓
         Actualización en tiempo real
```

## 📝 Notas Importantes

### Para la Aplicación Flutter

1. **Configuración de Firebase**: Debes ejecutar `flutterfire configure` antes de ejecutar la app
2. **Permisos de Internet**: Ya están configurados en Android y iOS
3. **MinSDK**: Android requiere minSdkVersion 21+

### Para el ESP32

1. **Sincronización de tiempo**: El ESP32 usa NTP para sincronizar la hora
2. **Zona horaria**: Configura tu zona horaria en el código si es necesario
3. **Programaciones**: Se verifican cada minuto
4. **Duración automática**: Implementa la función de duración si quieres que se desactive automáticamente

## ⚠️ Consideraciones de Seguridad

1. **Autenticación requerida**: Solo usuarios autenticados pueden escribir en Firebase
2. **Lectura pública del estado**: El ESP32 puede leer sin autenticación (simplificado)
3. **Tokens de seguridad**: Para mayor seguridad, implementa autenticación del ESP32
4. **No compartas**: Mantén secretos tus credenciales de Firebase

## 🐛 Solución de Problemas

### La app no se conecta a Firebase
- Verifica que ejecutaste `flutterfire configure`
- Revisa que el archivo `firebase_options.dart` existe
- Comprueba la conexión a Internet

### El ESP32 no responde
- Verifica la conexión WiFi
- Comprueba la URL de Firebase en el código del ESP32
- Revisa el monitor serial para ver errores
- Verifica las reglas de seguridad de Firebase

### Las programaciones no se ejecutan
- Asegúrate de que el ESP32 tenga la hora correcta (NTP)
- Verifica el formato de fecha/hora en Firebase
- Revisa los logs del ESP32

## 🔮 Mejoras Futuras

- [ ] Sensor de humedad del suelo
- [ ] Notificaciones push cuando se activa el riego
- [ ] Historial de riegos
- [ ] Estadísticas de consumo de agua
- [ ] Múltiples zonas de riego
- [ ] Integración con pronóstico del clima
- [ ] Modo ahorro de agua

## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:
1. Haz fork del proyecto
2. Crea una rama para tu función (`git checkout -b feature/nueva-funcion`)
3. Commit tus cambios (`git commit -am 'Agrega nueva función'`)
4. Push a la rama (`git push origin feature/nueva-funcion`)
5. Crea un Pull Request

## 📧 Contacto

Si tienes preguntas o sugerencias, no dudes en crear un issue en el repositorio.

---

**¡Feliz riego! 🌱💧**
