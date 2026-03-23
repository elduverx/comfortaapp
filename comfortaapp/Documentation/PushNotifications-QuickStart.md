# 🚀 Push Notifications - Quick Start

## ✅ Código Ya Implementado

He implementado el código completo para push notifications:

1. ✅ **AppDelegate.swift** - Maneja registro y recepción
2. ✅ **PushNotificationService.swift** - Servicio de gestión
3. ✅ **comfortaappApp.swift** - Conectado con AppDelegate
4. ✅ **NotificationService.swift** - Notificaciones locales

## 🔧 Configuración Requerida en Xcode (5 minutos)

### Paso 1: Habilitar Push Notifications

1. Abre el proyecto en Xcode
2. Selecciona el **target "comfortaapp"**
3. Ve a **"Signing & Capabilities"**
4. Haz clic en **"+ Capability"**
5. Busca y agrega **"Push Notifications"**

### Paso 2: Habilitar Background Modes

1. En la misma pestaña, haz clic en **"+ Capability"**
2. Agrega **"Background Modes"**
3. Marca **"Remote notifications"**

```
✅ Tu configuración debe verse así:

Signing & Capabilities
├── Push Notifications ✓
└── Background Modes
    └── ☑️ Remote notifications
```

## 🔐 Configuración en Apple Developer (10 minutos)

### Opción A: APNs Authentication Key (Recomendado)

1. Ve a [developer.apple.com/account](https://developer.apple.com/account)
2. **Certificates, Identifiers & Profiles** → **Keys**
3. Haz clic en **"+"**
4. Nombre: "Comforta Push Notifications"
5. Marca **"Apple Push Notifications service (APNs)"**
6. Haz clic en **Continue** → **Register**
7. **DESCARGA el archivo .p8** (¡solo puedes hacerlo UNA vez!)
8. Guarda:
   - **Key ID**
   - **Team ID**
   - Archivo **.p8**

### Opción B: APNs Certificate (Alternativa)

1. Ve a **Certificates, Identifiers & Profiles** → **Certificates**
2. Haz clic en **"+"**
3. Selecciona **"Apple Push Notification service SSL"**
4. Selecciona tu App ID
5. Genera un CSR desde Keychain Access
6. Sube el CSR y descarga el certificado
7. Haz doble clic para instalarlo en Keychain

## 📱 Testing en Dispositivo

### Requisitos

- **Dispositivo físico** (NO funciona en simulador)
- Cable USB conectado
- Xcode ejecutando la app en Debug

### Pasos

1. Conecta tu iPhone/iPad
2. Ejecuta la app desde Xcode
3. Acepta los permisos de notificaciones
4. Revisa la consola de Xcode, verás:

```
✅ Device Token: abc123def456...
```

5. Copia ese token para testing

## 🧪 Enviar una Notificación de Prueba

### Opción 1: Usar Pusher (Más Fácil)

1. Descarga [NWPusher](https://github.com/noodlewerk/NWPusher/releases)
2. Abre la app
3. Importa tu certificado .p12 o key .p8
4. Pega el device token
5. Escribe el payload:

```json
{
  "aps": {
    "alert": {
      "title": "¡Funciona!",
      "body": "Tu primera notificación push"
    },
    "sound": "default"
  },
  "type": "test"
}
```

6. Haz clic en **"Push"**

### Opción 2: Usar Terminal (Avanzado)

```bash
# Reemplaza DEVICE_TOKEN con tu token
# Reemplaza /path/to/key.p8 con la ruta a tu archivo

curl -v \
  --header "apns-topic: com.tuempresa.comfortaapp" \
  --header "apns-push-type: alert" \
  --header "apns-priority: 10" \
  --header "authorization: bearer $JWT_TOKEN" \
  --data '{"aps":{"alert":{"title":"Test","body":"Hola!"}}}' \
  --http2 \
  https://api.sandbox.push.apple.com/3/device/DEVICE_TOKEN
```

## 🎯 Tipos de Notificaciones Soportadas

El código ya maneja estos tipos:

| Tipo | Descripción | Acción |
|------|-------------|--------|
| `driver_assigned` | Conductor asignado | Abre vista de viaje |
| `driver_en_route` | Conductor en camino | Abre vista de viaje |
| `driver_arrived` | Conductor llegó | Abre vista de viaje + vibración |
| `trip_started` | Viaje iniciado | Abre vista de viaje |
| `trip_completed` | Viaje completado | Abre calificación |
| `promotional` | Oferta/promoción | Muestra en app |
| `trip_reminder` | Recordatorio | Abre detalles de viaje |

## 📤 Formato de Payload

### Ejemplo Completo

```json
{
  "aps": {
    "alert": {
      "title": "Conductor Asignado",
      "body": "Juan será tu conductor. Toyota Prius - ABC123"
    },
    "sound": "default",
    "badge": 1
  },
  "type": "driver_assigned",
  "trip_id": "trip_12345",
  "driver_id": "driver_67890"
}
```

## 🔗 Integración con tu Backend

### 1. Endpoint para Registrar Token

Tu backend debe recibir y guardar el device token:

```swift
POST /api/device-tokens

Body:
{
  "user_id": "user123",
  "device_token": "abc123...",
  "platform": "ios"
}
```

### 2. Endpoint para Enviar Notificación

Tu backend usa APNs para enviar notificaciones:

```python
# Ejemplo en Python con PyAPNs2
from apns2.client import APNsClient
from apns2.payload import Payload

client = APNsClient('/path/to/key.p8', key_id='KEY_ID', team_id='TEAM_ID')

payload = Payload(
    alert={
        "title": "Conductor Asignado",
        "body": "Juan será tu conductor"
    },
    sound="default",
    custom={
        "type": "driver_assigned",
        "trip_id": "trip_123"
    }
)

client.send_notification(device_token, payload, topic='com.tuempresa.comfortaapp')
```

## ✅ Checklist Rápido

- [ ] Agregada capability "Push Notifications" en Xcode
- [ ] Agregada capability "Background Modes" → "Remote notifications"
- [ ] Generada APNs key en Apple Developer
- [ ] Probado en dispositivo físico
- [ ] Device token obtenido correctamente
- [ ] Enviada notificación de prueba
- [ ] Notificación recibida exitosamente
- [ ] Backend configurado para recibir tokens
- [ ] Backend configurado para enviar notificaciones

## 🐛 Problemas Comunes

### No recibo el device token

**Solución:**
- Asegúrate de usar un dispositivo físico
- Verifica que Push Notifications esté habilitado
- Limpia el build (Cmd + Shift + K)
- Reinicia Xcode

### La notificación no llega

**Solución:**
- Verifica que usas el entorno correcto (sandbox vs production)
- Comprueba que el device token sea correcto
- Verifica que el certificado/key sea válido
- Revisa que la app tenga permisos

### Error "Invalid Token"

**Solución:**
- El token puede haber cambiado
- Desinstala y reinstala la app
- Vuelve a obtener el device token

## 📚 Documentación Completa

Para más detalles, consulta:
- `Documentation/PushNotificationsGuide.md`

## 🎉 ¡Listo!

Con estos pasos, tus push notifications estarán funcionando en minutos. El código ya está implementado, solo necesitas la configuración en Xcode y Apple Developer.

**Siguiente paso:** Configura tu backend para enviar notificaciones cuando ocurran eventos (conductor asignado, viaje iniciado, etc.)
