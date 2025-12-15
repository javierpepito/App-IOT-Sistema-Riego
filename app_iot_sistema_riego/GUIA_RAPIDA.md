# 🔥 Guía Rápida de Configuración de Firebase

Esta guía te llevará paso a paso por la configuración de Firebase para tu aplicación de riego IoT.

## ⚡ Configuración Rápida (5 minutos)

### Paso 1: Crear Proyecto en Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Haz clic en "Agregar proyecto"
3. Nombre del proyecto: `sistema-riego-iot` (o el que prefieras)
4. Desactiva Google Analytics si no lo necesitas
5. Haz clic en "Crear proyecto"

### Paso 2: Configurar Authentication

1. En el menú lateral, ve a **Authentication**
2. Haz clic en "Comenzar"
3. En la pestaña "Sign-in method":
   - Haz clic en **Email/Password**
   - Activa el primer toggle (Email/Password)
   - Haz clic en "Guardar"

### Paso 3: Configurar Realtime Database

1. En el menú lateral, ve a **Realtime Database**
2. Haz clic en "Crear base de datos"
3. Ubicación: Selecciona la más cercana (ej: `us-central1`)
4. Modo de seguridad: Selecciona **"Empezar en modo de prueba"** (por ahora)
5. Haz clic en "Habilitar"

### Paso 4: Configurar Reglas de Seguridad

1. En Realtime Database, ve a la pestaña **Reglas**
2. Reemplaza el contenido con:

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

3. Haz clic en **"Publicar"**

**Explicación**:
- Solo usuarios autenticados pueden leer/escribir en general
- El nodo `riego` puede ser leído por cualquiera (para que el ESP32 lea sin autenticación)
- Solo usuarios autenticados pueden escribir en `riego`

### Paso 5: Crear Estructura Inicial de Datos

1. Ve a la pestaña **Datos**
2. Verás la URL de tu base de datos (ej: `https://sistema-riego-iot-default-rtdb.firebaseio.com/`)
3. Haz clic en el ícono **"+"** junto a la URL
4. Nombre: `riego`
5. Haz clic en el ícono **"+"** dentro de `riego`:
   - Nombre: `estado`, Valor: `desactivado`
   - Nombre: `manual`, Valor: `true`
   - Nombre: `ultimaActualizacion`, Valor: `0`

Deberías tener algo así:
```
riego
  └── estado: "desactivado"
  └── manual: true
  └── ultimaActualizacion: 0
```

### Paso 6: Copiar URL de la Base de Datos

1. Copia la URL de tu Realtime Database
2. Se ve así: `https://tu-proyecto-default-rtdb.firebaseio.com/`
3. **Guárdala** - la necesitarás para el ESP32

---

## 📱 Configurar Firebase en Flutter

### Método 1: FlutterFire CLI (Recomendado)

1. **Instalar FlutterFire CLI**:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. **Configurar Firebase**:
   ```bash
   cd d:\App-IOT-Sistema-Riego\app_iot_sistema_riego
   flutterfire configure
   ```

3. **Seguir las instrucciones**:
   - Selecciona tu proyecto de Firebase
   - Selecciona las plataformas (Android, iOS, Web, etc.)
   - Se generará automáticamente `lib/firebase_options.dart`

4. **¡Listo!** Ya puedes ejecutar la app

### Método 2: Configuración Manual

Si FlutterFire CLI no funciona, sigue estos pasos:

#### Para Android:

1. En Firebase Console, ve a **Configuración del proyecto** (ícono de engranaje)
2. Desplázate a **Tus apps** y haz clic en el ícono de Android
3. Nombre del paquete: `com.example.app_iot_sistema_riego` (o el que uses)
4. Descarga el archivo `google-services.json`
5. Copia `google-services.json` a: `android/app/`

6. Edita `android/build.gradle.kts`:
   ```kotlin
   dependencies {
       classpath("com.google.gms:google-services:4.4.0")
   }
   ```

7. Edita `android/app/build.gradle.kts`:
   ```kotlin
   plugins {
       id("com.android.application")
       id("com.google.gms.google-services")
   }
   ```

#### Para iOS (si lo necesitas):

1. En Firebase Console, agrega una app iOS
2. Bundle ID: obtenerlo de `ios/Runner.xcodeproj`
3. Descarga `GoogleService-Info.plist`
4. Abre `ios/Runner.xcworkspace` en Xcode
5. Arrastra `GoogleService-Info.plist` a la carpeta Runner

---

## 🧪 Probar la Configuración

### 1. Ejecutar la App

```bash
flutter run
```

### 2. Registrar un Usuario

1. Abre la app
2. Haz clic en "Regístrate"
3. Ingresa un email y contraseña
4. Regístrate

### 3. Verificar en Firebase

1. Ve a Firebase Console → Authentication → Users
2. Deberías ver tu usuario registrado

### 4. Probar el Control de Riego

1. En la app, presiona "Activar Riego"
2. Ve a Firebase Console → Realtime Database → Datos
3. El campo `riego/estado` debería cambiar a `"activo"`

---

## 🔌 Configurar ESP32

### Obtener la URL de Firebase

Tu URL está en Firebase Console → Realtime Database

Formato: `https://tu-proyecto-default-rtdb.firebaseio.com/`

### Editar el Código del ESP32

En `ESP32_CODE.md`, reemplaza:

```cpp
#define WIFI_SSID "TU_NOMBRE_DE_WIFI"
#define WIFI_PASSWORD "TU_CONTRASEÑA_WIFI"
#define FIREBASE_HOST "tu-proyecto-default-rtdb.firebaseio.com"
```

**Nota**: En `FIREBASE_HOST`, **NO incluyas** `https://` ni la barra final `/`

### Opcional: Autenticación del ESP32

Si quieres mayor seguridad:

1. En Firebase Console → Configuración del proyecto → Cuentas de servicio
2. Ve a **Secretos de base de datos**
3. Haz clic en "Mostrar"
4. Copia el secret
5. En el código del ESP32:
   ```cpp
   #define FIREBASE_AUTH "tu_database_secret"
   ```

---

## 🎯 Checklist de Verificación

- [ ] Proyecto de Firebase creado
- [ ] Authentication habilitado (Email/Password)
- [ ] Realtime Database creado
- [ ] Reglas de seguridad configuradas
- [ ] Estructura inicial de datos creada (`riego/estado`)
- [ ] URL de Firebase copiada
- [ ] `flutterfire configure` ejecutado
- [ ] `flutter pub get` ejecutado
- [ ] App ejecuta sin errores
- [ ] Usuario registrado exitosamente
- [ ] Control de riego funciona en la app
- [ ] Cambios se reflejan en Firebase Console
- [ ] ESP32 configurado con WiFi y Firebase URL

---

## 🐛 Problemas Comunes

### Error: "No Firebase App '[DEFAULT]' has been created"

**Solución**:
```dart
// Verifica que en main.dart tengas:
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### Error: "MissingPluginException"

**Solución**:
```bash
flutter clean
flutter pub get
flutter run
```

### Error: "FirebaseException: Permission denied"

**Solución**: Verifica las reglas de seguridad en Firebase Console

### ESP32 no se conecta a Firebase

**Verificar**:
1. URL de Firebase correcta (sin `https://` y sin `/` al final)
2. WiFi conectado (revisa SSID y password)
3. Reglas de Firebase permiten lectura pública en `riego`

---

## 📚 Recursos Adicionales

- [Documentación de Firebase](https://firebase.google.com/docs)
- [FlutterFire](https://firebase.flutter.dev/)
- [Firebase ESP32](https://github.com/mobizt/Firebase-ESP32)
- [Flutter](https://flutter.dev/)

---

## ✅ ¡Todo Listo!

Si completaste todos los pasos, tu sistema debería estar funcionando:

1. ✅ App Flutter conectada a Firebase
2. ✅ Usuarios pueden registrarse e iniciar sesión
3. ✅ Control de riego funciona en tiempo real
4. ✅ Programaciones se pueden crear
5. ✅ ESP32 listo para leer el estado

**Siguiente paso**: Sube el código al ESP32 y conecta el relé para controlar tu sistema de riego real.

---

¿Tienes dudas? Revisa los logs en:
- Flutter: Consola de VS Code o terminal
- Firebase: Console → Realtime Database → Uso
- ESP32: Monitor Serial (115200 baud)
