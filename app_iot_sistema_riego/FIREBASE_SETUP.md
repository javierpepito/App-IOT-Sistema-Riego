# Configuración de Firebase para Sistema de Riego IoT

## Estructura de la Base de Datos en Firebase Realtime Database

La base de datos debe tener la siguiente estructura en formato JSON:

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
        "ejecutado": false,
        "createdAt": 1702651200000
      },
      "-NxYzAbC456": {
        "fecha": "2025-12-21T00:00:00.000Z",
        "hora": "18:00",
        "duracionMinutos": 45,
        "activo": true,
        "ejecutado": false,
        "createdAt": 1702651200000
      }
    }
  }
}
```

## Campos Principales

### `riego/estado`
- **Tipo**: String
- **Valores**: `"activo"` o `"desactivado"`
- **Descripción**: Estado actual del sistema de riego. El ESP32 lee este valor para activar o desactivar el riego.

### `riego/manual`
- **Tipo**: Boolean
- **Descripción**: Indica si el cambio fue manual (true) o automático por programación (false).

### `riego/ultimaActualizacion`
- **Tipo**: Timestamp (número)
- **Descripción**: Timestamp de la última actualización del estado.

### `riego/programaciones/{id}`
- **fecha**: Fecha en formato ISO 8601
- **hora**: Hora en formato "HH:mm" (24 horas)
- **duracionMinutos**: Duración del riego en minutos
- **activo**: Si la programación está activa o pausada
- **ejecutado**: Si ya se ejecutó la programación
- **createdAt**: Timestamp de creación

## Reglas de Seguridad para Firebase Realtime Database

Para configurar las reglas de seguridad en la consola de Firebase:

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

**Nota**: La regla `.read: true` en `riego` permite que el ESP32 lea el estado sin autenticación. Si prefieres mayor seguridad, puedes usar tokens de autenticación en el ESP32.

## Pasos para Configurar Firebase en Flutter

1. **Crear proyecto en Firebase Console**:
   - Ve a [https://console.firebase.google.com/](https://console.firebase.google.com/)
   - Crea un nuevo proyecto o selecciona uno existente
   - Habilita Authentication (Email/Password)
   - Habilita Realtime Database

2. **Configurar Firebase CLI**:
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

3. **Configurar FlutterFire**:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   
   Esto generará automáticamente el archivo `firebase_options.dart` con tu configuración.

4. **Agregar firebase_options.dart al proyecto**:
   El archivo se generará en `lib/firebase_options.dart`. Luego actualiza el `main.dart`:
   
   ```dart
   import 'firebase_options.dart';
   
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```

5. **Configurar Realtime Database**:
   - En Firebase Console, ve a Realtime Database
   - Crea la base de datos
   - Inicia en modo de prueba o configura las reglas de seguridad
   - Copia la URL de la base de datos (la necesitarás para el ESP32)

6. **Inicializar datos iniciales**:
   Puedes crear manualmente en la consola de Firebase o importar este JSON:
   
   ```json
   {
     "riego": {
       "estado": "desactivado",
       "manual": true,
       "ultimaActualizacion": 0
     }
   }
   ```

## URL de la Base de Datos

Tu URL de Realtime Database tendrá este formato:
```
https://tu-proyecto-firebase-default-rtdb.firebaseio.com/
```

**Importante**: Guarda esta URL, la necesitarás para configurar el ESP32.

## Configuración para Android

En `android/app/build.gradle`, asegúrate de tener:
```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

## Configuración para iOS

En `ios/Runner/Info.plist`, agrega si es necesario permisos adicionales.

## Notas de Seguridad

1. **No compartas** tu archivo `google-services.json` (Android) o `GoogleService-Info.plist` (iOS) públicamente
2. Configura reglas de seguridad apropiadas en Firebase
3. Para producción, considera usar autenticación del ESP32 con Firebase
4. Implementa rate limiting si es necesario para prevenir abuso

## Próximos Pasos

- Ejecuta `flutter pub get` para instalar dependencias
- Ejecuta `flutterfire configure` para generar la configuración
- Revisa el código del ESP32 en `ESP32_CODE.md` para la integración del hardware
