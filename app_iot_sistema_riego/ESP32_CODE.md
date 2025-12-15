# Código ESP32 para Sistema de Riego IoT

Este documento contiene el código completo para el ESP32 que se conecta a Firebase Realtime Database y controla el sistema de riego.

## Requisitos de Hardware

- ESP32 (cualquier modelo con WiFi)
- Relé de 5V (para controlar la bomba de agua o electroválvula)
- Bomba de agua o electroválvula
- Fuente de alimentación adecuada
- Cables y resistencias según sea necesario

## Conexiones

```
ESP32 GPIO 2  -> LED integrado (indicador de estado)
ESP32 GPIO 5  -> Pin de señal del relé
GND           -> GND del relé
VCC           -> VCC del relé (5V)
```

## Librerías Necesarias

Instala estas librerías desde el Library Manager de Arduino IDE:

1. **Firebase ESP32 Client** by Mobizt
2. **WiFi** (incluida con ESP32)
3. **ArduinoJson** by Benoit Blanchon

## Código Completo

```cpp
#include <WiFi.h>
#include <FirebaseESP32.h>
#include <time.h>

// ============================================
// CONFIGURACIÓN - MODIFICA ESTOS VALORES
// ============================================

// WiFi credentials
#define WIFI_SSID "TU_NOMBRE_DE_WIFI"
#define WIFI_PASSWORD "TU_CONTRASEÑA_WIFI"

// Firebase credentials
#define FIREBASE_HOST "tu-proyecto-firebase-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH "tu_database_secret_o_token"  // Opcional si las reglas lo permiten

// Pines
#define RELAY_PIN 5
#define LED_PIN 2

// ============================================
// VARIABLES GLOBALES
// ============================================

FirebaseData firebaseData;
FirebaseData streamData;

String estadoActual = "desactivado";
unsigned long lastCheckTime = 0;
const unsigned long CHECK_INTERVAL = 1000; // Revisar cada 1 segundo

// Para programaciones automáticas
struct Programacion {
  String id;
  String fecha;
  String hora;
  int duracionMinutos;
  bool activo;
  bool ejecutado;
};

// ============================================
// FUNCIONES
// ============================================

void setup() {
  Serial.begin(115200);
  
  // Configurar pines
  pinMode(RELAY_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);
  digitalWrite(LED_PIN, LOW);
  
  // Conectar a WiFi
  Serial.println();
  Serial.print("Conectando a WiFi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println();
  Serial.println("WiFi conectado!");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());
  
  // Configurar tiempo (NTP)
  configTime(0, 0, "pool.ntp.org", "time.nist.gov");
  Serial.println("Esperando sincronización de tiempo...");
  
  // Inicializar Firebase
  Firebase.begin(FIREBASE_HOST, FIREBASE_AUTH);
  Firebase.reconnectWiFi(true);
  Firebase.setReadTimeout(firebaseData, 1000 * 60);
  Firebase.setwriteSizeLimit(firebaseData, "tiny");
  
  Serial.println("Firebase conectado!");
  
  // Comenzar a escuchar cambios en el estado
  if (!Firebase.beginStream(streamData, "/riego/estado")) {
    Serial.println("Error al iniciar stream:");
    Serial.println(streamData.errorReason());
  } else {
    Serial.println("Stream iniciado correctamente");
  }
  
  // Leer estado inicial
  leerEstadoInicial();
}

void loop() {
  // Verificar conexión WiFi
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi desconectado, reconectando...");
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    while (WiFi.status() != WL_CONNECTED) {
      delay(500);
    }
    Serial.println("WiFi reconectado");
  }
  
  // Escuchar cambios en tiempo real
  if (!Firebase.readStream(streamData)) {
    Serial.println("Error en stream:");
    Serial.println(streamData.errorReason());
  }
  
  if (streamData.streamAvailable()) {
    Serial.println("Cambio detectado en Firebase:");
    
    if (streamData.dataType() == "string") {
      String nuevoEstado = streamData.stringData();
      Serial.print("Nuevo estado: ");
      Serial.println(nuevoEstado);
      
      actualizarEstado(nuevoEstado);
    }
  }
  
  // Verificar programaciones cada minuto
  if (millis() - lastCheckTime > CHECK_INTERVAL) {
    lastCheckTime = millis();
    verificarProgramaciones();
  }
  
  delay(100);
}

void leerEstadoInicial() {
  Serial.println("Leyendo estado inicial...");
  
  if (Firebase.getString(firebaseData, "/riego/estado")) {
    estadoActual = firebaseData.stringData();
    Serial.print("Estado inicial: ");
    Serial.println(estadoActual);
    actualizarEstado(estadoActual);
  } else {
    Serial.println("Error al leer estado inicial:");
    Serial.println(firebaseData.errorReason());
  }
}

void actualizarEstado(String nuevoEstado) {
  estadoActual = nuevoEstado;
  
  if (nuevoEstado == "activo") {
    digitalWrite(RELAY_PIN, HIGH);
    digitalWrite(LED_PIN, HIGH);
    Serial.println("✓ RIEGO ACTIVADO");
  } else {
    digitalWrite(RELAY_PIN, LOW);
    digitalWrite(LED_PIN, LOW);
    Serial.println("✗ RIEGO DESACTIVADO");
  }
}

void verificarProgramaciones() {
  // Obtener programaciones de Firebase
  if (!Firebase.getJSON(firebaseData, "/riego/programaciones")) {
    return;
  }
  
  if (firebaseData.dataType() != "json") {
    return;
  }
  
  FirebaseJson &json = firebaseData.jsonObject();
  size_t len = json.iteratorBegin();
  String key, value;
  int type = 0;
  
  time_t now;
  struct tm timeinfo;
  time(&now);
  localtime_r(&now, &timeinfo);
  
  char fechaActual[11];
  char horaActual[6];
  strftime(fechaActual, sizeof(fechaActual), "%Y-%m-%d", &timeinfo);
  strftime(horaActual, sizeof(horaActual), "%H:%M", &timeinfo);
  
  for (size_t i = 0; i < len; i++) {
    json.iteratorGet(i, type, key, value);
    
    if (type == FirebaseJson::JSON_OBJECT) {
      FirebaseJson programacionJson;
      programacionJson.setJsonData(value);
      
      FirebaseJsonData fechaData, horaData, activoData, ejecutadoData, duracionData;
      programacionJson.get(fechaData, "fecha");
      programacionJson.get(horaData, "hora");
      programacionJson.get(activoData, "activo");
      programacionJson.get(ejecutadoData, "ejecutado");
      programacionJson.get(duracionData, "duracionMinutos");
      
      if (activoData.success && horaData.success && !ejecutadoData.boolValue) {
        String fechaProg = fechaData.stringValue;
        String horaProg = horaData.stringValue;
        
        // Extraer solo la fecha (primeros 10 caracteres de ISO)
        if (fechaProg.length() >= 10) {
          fechaProg = fechaProg.substring(0, 10);
        }
        
        // Verificar si es hora de activar
        if (fechaProg == String(fechaActual) && horaProg == String(horaActual)) {
          Serial.println("¡Programación coincide! Activando riego automático...");
          
          // Activar riego
          Firebase.setString(firebaseData, "/riego/estado", "activo");
          Firebase.setBool(firebaseData, "/riego/manual", false);
          
          // Marcar como ejecutado
          String path = "/riego/programaciones/" + key + "/ejecutado";
          Firebase.setBool(firebaseData, path, true);
          
          // Programar desactivación después de la duración
          // (Esto requeriría implementar un timer, simplificado aquí)
          int duracion = duracionData.intValue;
          Serial.print("Duración programada: ");
          Serial.print(duracion);
          Serial.println(" minutos");
        }
      }
    }
  }
  
  json.iteratorEnd();
}

// ============================================
// FUNCIONES OPCIONALES
// ============================================

void mostrarInfoWiFi() {
  Serial.println("\n=== Info WiFi ===");
  Serial.print("SSID: ");
  Serial.println(WiFi.SSID());
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());
  Serial.print("Señal: ");
  Serial.print(WiFi.RSSI());
  Serial.println(" dBm");
}

void testRelé() {
  Serial.println("Test del relé...");
  digitalWrite(RELAY_PIN, HIGH);
  delay(2000);
  digitalWrite(RELAY_PIN, LOW);
  delay(1000);
  Serial.println("Test completado");
}
```

## Instrucciones de Uso

### 1. Configuración Inicial

Antes de subir el código al ESP32:

1. Reemplaza `TU_NOMBRE_DE_WIFI` con el nombre de tu red WiFi
2. Reemplaza `TU_CONTRASEÑA_WIFI` con la contraseña de tu WiFi
3. Reemplaza `tu-proyecto-firebase-default-rtdb.firebaseio.com` con tu URL de Firebase
4. Si tus reglas de Firebase requieren autenticación, agrega el token en `FIREBASE_AUTH`

### 2. Obtener el Database Secret (Opcional)

Si necesitas autenticación:

1. Ve a Firebase Console
2. Configuración del proyecto → Cuentas de servicio
3. Secretos de base de datos → Mostrar
4. Copia el secret y úsalo en `FIREBASE_AUTH`

### 3. Subir el Código

1. Conecta el ESP32 a tu computadora
2. Selecciona la placa correcta: **Herramientas → Placa → ESP32 Dev Module**
3. Selecciona el puerto correcto
4. Haz clic en **Subir**

### 4. Monitor Serial

Abre el monitor serial (115200 baudios) para ver:
- Estado de conexión WiFi
- Estado de conexión Firebase
- Cambios en el estado del riego
- Verificación de programaciones

## Mejoras Sugeridas para el ESP32

### Control con Duración Automática

Para implementar duración automática cuando se activa desde programación:

```cpp
unsigned long tiempoActivacion = 0;
int duracionActual = 0;
bool riegoAutomatico = false;

void activarRiegoProgramado(int duracionMinutos) {
  Firebase.setString(firebaseData, "/riego/estado", "activo");
  tiempoActivacion = millis();
  duracionActual = duracionMinutos;
  riegoAutomatico = true;
}

void verificarDuracion() {
  if (riegoAutomatico && estadoActual == "activo") {
    unsigned long tiempoTranscurrido = (millis() - tiempoActivacion) / 60000; // minutos
    
    if (tiempoTranscurrido >= duracionActual) {
      Serial.println("Duración completada. Desactivando riego...");
      Firebase.setString(firebaseData, "/riego/estado", "desactivado");
      riegoAutomatico = false;
    }
  }
}

// Agregar en loop():
// verificarDuracion();
```

### Sensor de Humedad (Opcional)

Para integrar un sensor de humedad y evitar riego innecesario:

```cpp
#define SENSOR_PIN 34  // Pin analógico

int leerHumedad() {
  int valor = analogRead(SENSOR_PIN);
  int porcentaje = map(valor, 0, 4095, 0, 100);
  return porcentaje;
}

// Antes de activar el riego, verificar:
int humedad = leerHumedad();
if (humedad < 30) {  // Solo regar si humedad < 30%
  // Activar riego
}
```

## Diagrama de Flujo

```
ESP32 Inicia
    ↓
Conecta WiFi
    ↓
Conecta Firebase
    ↓
Escucha cambios en /riego/estado
    ↓
Detecta cambio → Actualiza relé
    ↓
Verifica programaciones cada minuto
    ↓
Si coincide hora → Activa riego
```

## Solución de Problemas

### Error de conexión WiFi
- Verifica SSID y contraseña
- Asegúrate de estar en rango de la señal

### Error de conexión Firebase
- Verifica la URL de Firebase
- Verifica las reglas de seguridad
- Comprueba que el proyecto tenga Realtime Database habilitado

### El relé no se activa
- Verifica las conexiones
- Prueba con `testRelé()` en setup
- Verifica el voltaje del relé

### Las programaciones no se ejecutan
- Verifica que el ESP32 tenga la hora correcta (NTP)
- Revisa el formato de fecha/hora en Firebase
- Comprueba los logs del monitor serial

## Mejoras de Seguridad

1. **Autenticación ESP32**: Usa tokens de Firebase para autenticar el ESP32
2. **Cifrado**: Usa HTTPS (ya implementado con Firebase)
3. **Reglas de Firebase**: Restringe acceso solo a lectura para el ESP32
4. **Watchdog**: Implementa watchdog timer para reiniciar si se cuelga

## Consumo de Energía

Para optimizar batería si usas energía solar:
- Usa deep sleep entre lecturas
- Reduce frecuencia de verificación
- Usa WiFi en modo de bajo consumo

## Referencias

- [Firebase ESP32 Client](https://github.com/mobizt/Firebase-ESP32)
- [Documentación ESP32](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/)
- [Firebase Realtime Database](https://firebase.google.com/docs/database)
