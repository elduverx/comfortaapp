# Comforta - Aplicación de Viajes Premium

Una aplicación iOS nativa para reservar viajes de larga distancia con diseño premium y experiencia de usuario fluida.

## Características Principales

### Para Usuarios
- **Reserva de Viajes**: Sistema completo de reserva con cálculo de rutas y tarifas en tiempo real
- **Autenticación Apple**: Sign in seguro con Apple ID
- **Seguimiento en Tiempo Real**: Tracking del conductor y del viaje
- **Sistema de Pagos**: Integración con múltiples métodos de pago
- **Historial de Viajes**: Vista completa de viajes pasados y futuros
- **Sistema de Valoraciones**: Califica conductores y viajes
- **Programa de Lealtad**: Puntos y beneficios por uso frecuente
- **Notificaciones**: Actualizaciones en tiempo real del estado del viaje

### Para Administradores
- **Panel de Control**: Dashboard completo con métricas y estadísticas
- **Gestión de Usuarios**: Administración de clientes y conductores
- **Gestión de Viajes**: Monitoreo y control de todos los viajes
- **Configuración de Precios**: Ajuste dinámico de tarifas
- **Sistema de Soporte**: Gestión de tickets y consultas

## Arquitectura

### Tecnologías
- **Framework**: SwiftUI
- **Mínimo iOS**: 17.0
- **Arquitectura**: MVVM (Model-View-ViewModel)
- **Mapas**: MapKit nativo
- **Autenticación**: Sign in with Apple
- **Networking**: URLSession con async/await
- **Persistencia**: UserDefaults + API Backend

### Estructura del Proyecto

```
comfortaapp/
├── Configuration/
│   ├── APIConfiguration.swift      # Configuración de endpoints API
│   ├── AppConfiguration.swift      # Configuración de la app
│   └── DesignSystem.swift         # Sistema de diseño y temas
│
├── Models/
│   ├── APIModels.swift            # Modelos de respuesta API
│   ├── UserModels.swift           # Modelos de usuario y conductor
│   ├── TripModels.swift           # Modelos de viajes
│   └── LocationModels.swift       # Modelos de ubicación
│
├── Services/
│   ├── APIClient.swift            # Cliente HTTP base
│   ├── AuthServiceAPI.swift       # Autenticación
│   ├── UserManager.swift          # Gestión de usuarios
│   ├── TripServiceAPI.swift       # Servicio de viajes
│   ├── PricingServiceAPI.swift    # Cálculo de precios
│   ├── PaymentService.swift       # Procesamiento de pagos
│   ├── NotificationService.swift  # Notificaciones push
│   └── RealTimeTrackingService.swift # Tracking en vivo
│
├── ViewModels/
│   ├── SimpleRideViewModel.swift  # ViewModel para vista de viaje
│   └── RideFlowViewModel.swift    # ViewModel para flujo completo
│
├── Views/
│   ├── ContentView.swift          # Vista raíz
│   ├── MainTabView.swift          # Navegación principal
│   ├── ModernRideView.swift       # Vista principal de reserva
│   ├── ProfileView.swift          # Perfil de usuario
│   ├── TripsView.swift            # Historial de viajes
│   ├── AdminDashboardView.swift   # Panel de administrador
│   └── Components/
│       ├── ModernCard.swift       # Tarjetas con glassmorphism
│       ├── LiquidSearchField.swift # Campo de búsqueda animado
│       ├── ToastView.swift        # Notificaciones toast
│       ├── LoadingView.swift      # Estados de carga
│       ├── ErrorView.swift        # Vistas de error
│       └── GlassTabBar.swift      # Barra de pestañas personalizada
│
├── Utilities/
│   ├── AnalyticsService.swift     # Tracking de eventos
│   ├── HapticManager.swift        # Feedback háptico
│   ├── AnimationSystem.swift      # Animaciones personalizadas
│   ├── ConnectivityMonitor.swift  # Monitor de conectividad
│   └── MapKitExtensions.swift     # Extensiones para MapKit
│
└── Extensions/
    ├── APITripExtensions.swift    # Extensiones de Trip API
    └── TripExtensions.swift       # Extensiones de Trip
```

## Sistema de Diseño

### Colores
- **Primario**: Dorado (#D7BA54) - Color principal de la marca
- **Oscuro**: Negro (#0C0C0E) - Fondo principal
- **Superficie**: Gris oscuro (#1E1E20) - Tarjetas y superficies
- **Texto**: Blanco con diferentes opacidades

### Componentes Reutilizables
- **ModernCard**: Tarjetas con efecto glassmorphism
- **LiquidButton**: Botones con animaciones fluidas
- **LiquidSearchField**: Campos de búsqueda con autocompletado
- **ToastView**: Notificaciones no intrusivas
- **LoadingView**: Estados de carga con animaciones

### Efectos Visuales
- **Glassmorphism**: Superficies translúcidas con blur
- **Liquid Glass**: Efectos de vidrio líquido con gradientes
- **Animaciones Spring**: Transiciones suaves y naturales
- **Haptic Feedback**: Retroalimentación táctil en interacciones

## Configuración

### Variables de Entorno
```swift
// En APIConfiguration.swift
baseURL = "https://comforta-app-ec29e2df8f7c.herokuapp.com"
```

### Capacidades Requeridas
- Sign in with Apple
- Push Notifications
- Location Services (When In Use)
- Background Modes (Location updates)

## Flujo de Usuario

### Reserva de Viaje
1. Usuario inicia sesión con Apple ID
2. Selecciona ubicación de recogida (automática o manual)
3. Selecciona destino
4. App calcula ruta y tarifa
5. Usuario confirma y paga
6. Sistema busca conductor
7. Conductor es asignado
8. Seguimiento en tiempo real
9. Viaje completado
10. Valoración y feedback

### Gestión de Perfil
1. Vista de estadísticas personales
2. Historial de viajes
3. Métodos de pago
4. Programa de lealtad
5. Configuración y soporte

## API Endpoints

### Autenticación
- `POST /api/auth/apple` - Autenticación con Apple
- `GET /api/auth/me` - Perfil del usuario actual

### Viajes
- `GET /api/trips` - Listar viajes
- `POST /api/trips` - Crear viaje
- `GET /api/trips/:id` - Detalles de viaje
- `PATCH /api/trips/:id` - Actualizar viaje
- `DELETE /api/trips/:id` - Cancelar viaje

### Precios
- `POST /api/pricing/calculate` - Calcular tarifa

### Favoritos
- `GET /api/favorites` - Obtener favoritos
- `POST /api/favorites` - Agregar favorito
- `DELETE /api/favorites/:id` - Eliminar favorito

## Testing

### Cuenta de Administrador
Para probar funcionalidades de admin, usa el botón "Iniciar como administrador" en la pantalla de login.

## Build y Ejecución

```bash
# Abrir proyecto
open Comforta.xcodeproj

# Build desde terminal
xcodebuild -project Comforta.xcodeproj -scheme Comforta -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run tests
xcodebuild test -project Comforta.xcodeproj -scheme Comforta -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Próximas Características

- [ ] Integración con Apple Pay
- [ ] Modo oscuro/claro configurable
- [ ] Compartir ubicación en tiempo real
- [ ] Chat con conductor
- [ ] Viajes programados recurrentes
- [ ] Multi-idioma (English, Español)
- [ ] Soporte para Apple Watch
- [ ] Widget para iOS Home Screen
- [ ] Accesibilidad mejorada (VoiceOver)

## Licencia

Propietario - Comforta © 2026

## Soporte

Para soporte técnico o consultas:
- Email: soporte@comforta.app
- Web: https://comforta.app
# comfortaapp

## Tests

- Target: `ComfortaTests`
- Run locally:
  - `xcodebuild -project Comforta.xcodeproj -scheme Comforta -destination 'platform=iOS Simulator,name=iPhone 15' test`

## CI/CD

- Workflow: `.github/workflows/ios.yml`

## Documentación

- API contracts: `docs/API_CONTRACTS.md`
