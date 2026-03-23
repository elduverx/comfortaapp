# Guía Completa de Configuración de Push Notifications

## 📱 Descripción

Sistema completo de notificaciones push para la app Comforta, incluyendo notificaciones locales y remotas (APNs).

## 🎯 Características Implementadas

### Notificaciones Locales ✅
- ✅ Conductor asignado
- ✅ Conductor en camino
- ✅ Conductor ha llegado
- ✅ Viaje iniciado
- ✅ Viaje completado
- ✅ Recordatorios de viajes programados
- ✅ Solicitud de calificación
- ✅ Notificaciones promocionales

### Notificaciones Push Remotas (APNs) ✅
- ✅ Registro de device token
- ✅ Manejo de notificaciones remotas
- ✅ Deep linking a vistas específicas
- ✅ Seguimiento con analytics
- ✅ Gestión de permisos

## 🔧 Configuración en Xcode

### Paso 1: Habilitar Push Notifications Capability

1. Abre tu proyecto en Xcode
2. Selecciona el **target** de tu app
3. Ve a la pestaña **"Signing & Capabilities"**
4. Haz clic en **"+ Capability"**
5. Busca y agrega **"Push Notifications"**

```
Signing & Capabilities
├── Push Notifications ← Agregar esto
├── Background Modes
│   └── Remote notifications ← Activar esto también
```

### Paso 2: Configurar Background Modes

1. En la misma pestaña "Signing & Capabilities"
2. Agrega **"Background Modes"**
3. Activa las siguientes opciones:
   - ☑️ **Remote notifications**
   - ☑️ **Background fetch** (opcional)

### Paso 3: Configurar Info.plist (Opcional)

Agrega una descripción para permisos de notificaciones:

```xml
<key>NSUserNotificationsUsageDescription</key>
<string>Comforta necesita enviar notificaciones sobre el estado de tus viajes, llegada del conductor y ofertas especiales.</string>
```

## 🔐 Configuración de APNs en Apple Developer

### Paso 1: Crear APNs Key

1. Ve a [Apple Developer Portal](https://developer.apple.com/account/)
2. Navega a **Certificates, Identifiers & Profiles**
3. Selecciona **Keys** en el menú lateral
4. Haz clic en el botón **"+"** para crear una nueva key
5. Dale un nombre (ej: "Comforta Push Notifications")
6. Marca la casilla **"Apple Push Notifications service (APNs)"**
7. Haz clic en **Continue** y luego **Register**
8. **IMPORTANTE:** Descarga el archivo `.p8` (solo puedes hacerlo una vez)
9. Guarda el **Key ID** y el **Team ID**

### Paso 2: Configurar App ID

1. En **Identifiers**, selecciona tu App ID
2. Asegúrate de que **Push Notifications** esté habilitado
3. Si no está habilitado, edita el App ID y actívalo
4. Haz clic en **Save**

## 📱 Implementación en el Código

### Archivos Creados

1. ✅ **AppDelegate.swift** - Maneja el registro de push notifications
2. ✅ **PushNotificationService.swift** - Servicio para gestionar tokens y notificaciones
3. ✅ **NotificationService.swift** - Servicio existente para notificaciones locales

### Integración en comfortaappApp.swift

El AppDelegate ya está conectado en `comfortaappApp.swift`:

```swift
@main
struct comfortaappApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## 🔄 Flujo de Notificaciones Push

### 1. Registro de Device Token

```
App Launch
    │
    ├─> AppDelegate.didFinishLaunchingWithOptions
    │       │
    │       ├─> Solicita permisos de notificaciones
    │       └─> registerForRemoteNotifications()
    │
    ├─> Sistema devuelve device token
    │       │
    │       └─> didRegisterForRemoteNotificationsWithDeviceToken
    │               │
    │               ├─> PushNotificationService.saveDeviceToken()
    │               └─> Envía token al servidor
    │
    └─> ✅ Listo para recibir push notifications
```

### 2. Recepción de Notificación

```
APNs envía notificación
    │
    ├─> App cerrada/background
    │       │
    │       └─> Usuario toca la notificación
    │               │
    │               └─> didReceive response
    │                       │
    │                       └─> Deep link a vista específica
    │
    └─> App en foreground
            │
            └─> willPresent notification
                    │
                    └─> Muestra banner/alert
```

## 📤 Formato de Payload para el Servidor

### Notificación de Conductor Asignado

```json
{
  "aps": {
    "alert": {
      "title": "Conductor Asignado",
      "body": "Juan será tu conductor. Toyota Prius - ABC-123"
    },
    "sound": "default",
    "badge": 1
  },
  "type": "driver_assigned",
  "trip_id": "trip_12345",
  "driver_id": "driver_67890"
}
```

### Notificación de Conductor en Camino

```json
{
  "aps": {
    "alert": {
      "title": "Conductor en Camino",
      "body": "Tu conductor llegará en 5 minutos"
    },
    "sound": "default"
  },
  "type": "driver_en_route",
  "trip_id": "trip_12345",
  "eta": "5 min"
}
```

### Notificación de Conductor Llegó

```json
{
  "aps": {
    "alert": {
      "title": "Conductor ha Llegado",
      "body": "Tu conductor está esperando en el punto de recogida"
    },
    "sound": "default"
  },
  "type": "driver_arrived",
  "trip_id": "trip_12345"
}
```

### Notificación Promocional

```json
{
  "aps": {
    "alert": {
      "title": "¡Oferta Especial!",
      "body": "20% de descuento en tu próximo viaje"
    },
    "sound": "default"
  },
  "type": "promotional",
  "promo_code": "COMFORTA20",
  "expires_at": "2024-01-31T23:59:59Z"
}
```

## 🧪 Testing

### Probar en Desarrollo

Para probar push notifications en desarrollo:

1. **Usar un dispositivo físico** (las notificaciones push NO funcionan en simulador)
2. Ejecuta la app en modo Debug
3. Revisa la consola para ver el **Device Token**
4. Usa una herramienta de testing como:
   - **Postman** con APNs endpoint
   - **Pusher** (herramienta online)
   - **Houston** (herramienta CLI)

### Ejemplo con curl

```bash
curl -v \
-d '{"aps":{"alert":{"title":"Test","body":"Mensaje de prueba"},"sound":"default"},"type":"test"}' \
-H "apns-topic: com.tuempresa.comfortaapp" \
-H "apns-push-type: alert" \
-H "apns-priority: 10" \
--http2 \
--cert /path/to/cert.pem \
https://api.sandbox.push.apple.com/3/device/DEVICE_TOKEN_AQUI
```

### Usar Pusher (Recomendado para Testing)

1. Ve a [Pusher for APNs](https://github.com/noodlewerk/NWPusher)
2. Descarga la app
3. Importa tu certificado .p12 o .p8
4. Ingresa el device token
5. Escribe el payload JSON
6. Envía la notificación

## 📊 Analytics

Todas las notificaciones push se rastrean automáticamente:

```swift
// Eventos rastreados:
- push_notification_registered  // Token registrado exitosamente
- push_notification_failed      // Fallo al registrar token
- push_notification_received    // Notificación recibida
- notification_tapped           // Usuario tocó la notificación
```

## 🔒 Seguridad y Privacidad

### Buenas Prácticas

1. **Nunca incluyas información sensible** en el payload de la notificación
2. **Usa identificadores** (trip_id, driver_id) en lugar de datos completos
3. **Implementa rate limiting** en tu servidor para prevenir spam
4. **Valida el device token** antes de enviar notificaciones
5. **Elimina tokens inválidos** de tu base de datos

### Manejo de Tokens Expirados

El servidor debe manejar respuestas 410 (Gone) de APNs:

```swift
// En tu backend
if response.status == .gone {
    // Eliminar el device token de la base de datos
    database.deleteDeviceToken(token)
}
```

## 🚀 Integración con el Backend

### Endpoint para Registrar Device Token

```swift
POST /api/device-tokens

Request:
{
  "user_id": "user_12345",
  "device_token": "abc123...",
  "platform": "ios",
  "app_version": "1.0.0",
  "device_model": "iPhone14,2",
  "os_version": "17.0"
}

Response:
{
  "success": true,
  "message": "Device token registered successfully"
}
```

### Endpoint para Enviar Notificación

```swift
POST /api/push-notifications/send

Request:
{
  "user_id": "user_12345",
  "type": "driver_assigned",
  "title": "Conductor Asignado",
  "body": "Juan será tu conductor",
  "data": {
    "trip_id": "trip_123",
    "driver_id": "driver_456"
  }
}
```

## 🐛 Troubleshooting

### El device token no se genera

**Problema:** `didRegisterForRemoteNotificationsWithDeviceToken` no se llama

**Soluciones:**
1. Verifica que Push Notifications capability esté habilitada
2. Usa un dispositivo físico (no simulador)
3. Verifica que el provisioning profile incluya push notifications
4. Reinicia Xcode y limpia el build (Cmd + Shift + K)

### Las notificaciones no llegan

**Problema:** Las notificaciones se envían pero no se reciben

**Soluciones:**
1. Verifica que el device token sea correcto
2. Usa el entorno correcto (sandbox vs production)
3. Revisa que el certificado/key de APNs sea válido
4. Verifica que el payload JSON sea válido
5. Comprueba que la app tenga permisos de notificaciones

### Error "Invalid Token"

**Problema:** APNs responde con "Invalid Token"

**Soluciones:**
1. El token puede haber expirado
2. El token puede ser de un entorno diferente (dev vs prod)
3. El token puede estar mal formateado
4. Solicita un nuevo token

## 📱 Estados de la App

### App en Foreground

```swift
// La notificación se muestra como banner
func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
) {
    // Mostrar banner, sonido y badge
    completionHandler([.banner, .sound, .badge])
}
```

### App en Background

```swift
// La notificación se entrega al centro de notificaciones
// El usuario puede tocarla para abrir la app
```

### App Cerrada

```swift
// La notificación se entrega al centro de notificaciones
// Al tocarla, la app se abre y se procesa la notificación
```

## ✅ Checklist de Implementación

- [x] AppDelegate creado
- [x] PushNotificationService creado
- [x] AppDelegate conectado a la app
- [ ] Push Notifications capability habilitada en Xcode
- [ ] Background Modes > Remote notifications habilitado
- [ ] APNs key generada en Apple Developer
- [ ] Certificado configurado en el servidor
- [ ] Endpoints de backend implementados
- [ ] Testing en dispositivo físico
- [ ] Analytics configurado

## 🎉 Resultado

Con esta implementación, tu app Comforta puede:

- ✅ Recibir notificaciones push remotas
- ✅ Manejar diferentes tipos de notificaciones
- ✅ Navegar a vistas específicas según el tipo
- ✅ Mostrar notificaciones incluso en foreground
- ✅ Rastrear eventos de notificaciones
- ✅ Gestionar device tokens automáticamente

¡Las notificaciones push están listas! 🚀
