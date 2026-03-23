# Guía de Selección de Destino en el Mapa

Sistema completo y profesional para seleccionar destinos en el mapa con tap interaction, geocodificación inversa y feedback visual.

## 📋 Tabla de Contenidos

1. [Descripción General](#descripción-general)
2. [Componentes](#componentes)
3. [Uso Básico](#uso-básico)
4. [Características](#características)
5. [Ejemplos de Integración](#ejemplos-de-integración)
6. [Personalización](#personalización)

## 🎯 Descripción General

Este sistema permite a los usuarios seleccionar un destino en el mapa de manera intuitiva y profesional. El usuario mueve el mapa para centrarlo en su ubicación deseada y presiona un botón para seleccionarla. El sistema automáticamente:

- Obtiene la dirección usando geocodificación inversa
- Muestra feedback visual con pins animados
- Proporciona confirmación antes de finalizar la selección
- Ajusta la vista del mapa para mostrar origen y destino

## 🧩 Componentes

### 1. **ReverseGeocodingService**
`Services/ReverseGeocodingService.swift`

Servicio de geocodificación inversa que convierte coordenadas a direcciones legibles.

**Características:**
- Cache automático para evitar consultas repetidas
- Manejo robusto de errores
- Formato de direcciones personalizable
- Información detallada de ubicaciones

**Uso:**
```swift
let geocoder = ReverseGeocodingService.shared

// Obtener dirección simple
let address = try await geocoder.reverseGeocode(coordinate: coordinate)

// Obtener información detallada
let details = try await geocoder.reverseGeocodeDetailed(coordinate: coordinate)
print(details.fullAddress)
print(details.city)
```

### 2. **AnimatedMapPin**
`Views/Components/AnimatedMapPin.swift`

Pin de mapa animado profesional con efectos visuales.

**Características:**
- Animaciones de entrada y selección
- Efecto de pulso cuando está seleccionado
- Animación de rebote
- Soporte para múltiples tipos de pins

**Tipos de pins:**
- `.pickup` - Pin de recogida (verde)
- `.destination` - Pin de destino (rojo)
- `.selectedLocation` - Ubicación siendo seleccionada (azul)
- `.driver` - Conductor (morado)

**Uso:**
```swift
AnimatedMapPin(
    type: .destination,
    title: "Aeropuerto",
    isSelected: true
)
```

### 3. **MapDestinationPicker**
`Views/Components/MapDestinationPicker.swift`

Componente principal de selección de destino en el mapa.

**Props:**
- `selectedDestination`: Binding a la coordenada seleccionada
- `selectedAddress`: Binding a la dirección seleccionada
- `pickupLocation`: Coordenada de recogida
- `pickupAddress`: Dirección de recogida
- `onDestinationConfirmed`: Callback cuando se confirma el destino

**Uso:**
```swift
MapDestinationPicker(
    selectedDestination: $selectedDestination,
    selectedAddress: $selectedAddress,
    pickupLocation: pickupCoordinate,
    pickupAddress: "Plaza Mayor, Madrid",
    onDestinationConfirmed: { coordinate, address in
        print("Destino: \(address)")
    }
)
```

### 4. **MapDestinationPickerDemo**
`Views/MapDestinationPickerDemo.swift`

Vista de ejemplo completa que muestra cómo integrar el selector.

## 💡 Uso Básico

### Paso 1: Importar el componente

```swift
import SwiftUI
import MapKit
import CoreLocation
```

### Paso 2: Crear estados

```swift
struct YourView: View {
    @State private var selectedDestination: CLLocationCoordinate2D?
    @State private var selectedAddress: String?

    let pickupLocation = CLLocationCoordinate2D(latitude: 39.4699, longitude: -0.3763)
    let pickupAddress = "Valencia, España"

    var body: some View {
        // ...
    }
}
```

### Paso 3: Usar el componente

```swift
MapDestinationPicker(
    selectedDestination: $selectedDestination,
    selectedAddress: $selectedAddress,
    pickupLocation: pickupLocation,
    pickupAddress: pickupAddress,
    onDestinationConfirmed: { coordinate, address in
        handleDestination(coordinate, address)
    }
)
```

## ✨ Características

### 1. **Crosshair Central**
Un indicador visual (mira) en el centro del mapa que ayuda al usuario a alinear su selección.

### 2. **Instrucciones Contextuales**
Mensajes de ayuda que guían al usuario en cada paso del proceso.

### 3. **Geocodificación Automática**
Conversión automática de coordenadas a direcciones legibles.

### 4. **Feedback Visual**
- Loading indicators durante la geocodificación
- Animaciones suaves en las transiciones
- Pins animados con bounce effect

### 5. **Confirmación de Selección**
Panel de confirmación con la dirección seleccionada antes de finalizar.

### 6. **Ajuste Automático de Vista**
El mapa se ajusta automáticamente para mostrar tanto el origen como el destino.

### 7. **Reset de Selección**
Botón para deshacer la selección y comenzar de nuevo.

## 🔧 Ejemplos de Integración

### Integración con ViewModel

```swift
class BookingViewModel: ObservableObject {
    @Published var selectedDestination: CLLocationCoordinate2D?
    @Published var selectedAddress: String?

    func confirmDestination() {
        guard let destination = selectedDestination,
              let address = selectedAddress else { return }

        // Crear reserva
        createBooking(
            pickup: pickupLocation,
            destination: destination,
            destinationAddress: address
        )
    }
}

struct BookingView: View {
    @StateObject private var viewModel = BookingViewModel()

    var body: some View {
        MapDestinationPicker(
            selectedDestination: $viewModel.selectedDestination,
            selectedAddress: $viewModel.selectedAddress,
            pickupLocation: viewModel.pickupLocation,
            pickupAddress: viewModel.pickupAddress,
            onDestinationConfirmed: { _, _ in
                viewModel.confirmDestination()
            }
        )
    }
}
```

### Integración con Navegación

```swift
struct TripFlowView: View {
    @State private var selectedDestination: CLLocationCoordinate2D?
    @State private var selectedAddress: String?
    @State private var navigateToConfirmation = false

    var body: some View {
        NavigationStack {
            MapDestinationPicker(
                selectedDestination: $selectedDestination,
                selectedAddress: $selectedAddress,
                pickupLocation: pickupLocation,
                pickupAddress: pickupAddress,
                onDestinationConfirmed: { _, _ in
                    navigateToConfirmation = true
                }
            )
            .navigationDestination(isPresented: $navigateToConfirmation) {
                TripConfirmationView(
                    destination: selectedDestination!,
                    address: selectedAddress!
                )
            }
        }
    }
}
```

### Validación Personalizada

```swift
MapDestinationPicker(
    selectedDestination: $selectedDestination,
    selectedAddress: $selectedAddress,
    pickupLocation: pickupLocation,
    pickupAddress: pickupAddress,
    onDestinationConfirmed: { coordinate, address in
        // Validar distancia mínima
        let distance = calculateDistance(
            from: pickupLocation,
            to: coordinate
        )

        if distance < 500 {
            showAlert("El destino está muy cerca")
            return
        }

        // Validar área de servicio
        if !isInServiceArea(coordinate) {
            showAlert("Fuera del área de servicio")
            return
        }

        // Proceder con la reserva
        proceedWithBooking()
    }
)
```

## 🎨 Personalización

### Personalizar Colores de Pins

Edita `AnimatedMapPin.swift`:

```swift
enum PinType {
    case pickup
    case destination

    var color: Color {
        switch self {
        case .pickup:
            return .blue  // Cambia a tu color
        case .destination:
            return .orange  // Cambia a tu color
        }
    }
}
```

### Personalizar Mensajes

Edita los textos en `MapDestinationPicker.swift`:

```swift
Text("Mueve el mapa")  // Cambiar mensaje principal
Text("Centra el mapa en tu destino...")  // Cambiar subtítulo
```

### Personalizar Animaciones

Ajusta los parámetros de animación:

```swift
.animation(.spring(response: 0.4, dampingFraction: 0.8), value: ...)

// Cambiar a:
.animation(.spring(response: 0.3, dampingFraction: 0.6), value: ...)
```

### Agregar Validación de Área

```swift
private func selectCurrentLocation() {
    let centerCoordinate = getCenterCoordinate()

    // Validar área de servicio
    guard ValenciaRegion.contains(centerCoordinate) else {
        showAlert("Fuera del área de servicio")
        return
    }

    // Continuar con la selección...
}
```

## 🚀 Características Avanzadas

### Cache de Geocodificación

El servicio de geocodificación incluye un sistema de cache:

```swift
// Limpiar cache cuando sea necesario
ReverseGeocodingService.shared.clearCache()
```

### Información Detallada de Ubicación

```swift
let details = try await geocoder.reverseGeocodeDetailed(coordinate: coordinate)

print(details.street)        // Calle
print(details.number)        // Número
print(details.city)          // Ciudad
print(details.postalCode)    // Código postal
print(details.country)       // País
print(details.fullAddress)   // Dirección completa
print(details.shortAddress)  // Dirección corta
```

### Múltiples Destinos

Para seleccionar múltiples destinos, modifica el componente:

```swift
@State private var destinations: [DestinationInfo] = []

struct DestinationInfo {
    let coordinate: CLLocationCoordinate2D
    let address: String
}
```

## 📱 Pruebas

### Probar en Simulador

1. Ejecuta la app
2. Navega a `MapDestinationPickerDemo`
3. Mueve el mapa
4. Presiona "Seleccionar esta ubicación"
5. Confirma la selección

### Probar en Dispositivo Real

El componente funciona mejor en dispositivos reales con GPS:

1. Habilita permisos de ubicación
2. Usa la ubicación actual como pickup
3. Selecciona destinos reales

## 🐛 Solución de Problemas

### El mapa no responde
- Verifica que `interactionModes` esté configurado como `.all`
- Asegúrate de que no haya overlays bloqueando los gestures

### La geocodificación falla
- Verifica la conexión a internet
- Revisa los permisos de ubicación
- Comprueba que las coordenadas sean válidas

### Los pins no aparecen
- Verifica que las coordenadas no sean nil
- Asegúrate de que las coordenadas estén dentro de la región visible
- Revisa los logs de la consola

## 📚 Recursos Adicionales

- [MapKit Documentation](https://developer.apple.com/documentation/mapkit)
- [CLGeocoder Documentation](https://developer.apple.com/documentation/corelocation/clgeocoder)
- [SwiftUI Map Documentation](https://developer.apple.com/documentation/mapkit/map)

## 🎉 Conclusión

Este sistema proporciona una experiencia de usuario profesional y pulida para la selección de destinos en el mapa. Es:

- ✅ Intuitivo y fácil de usar
- ✅ Visualmente atractivo con animaciones suaves
- ✅ Robusto con manejo de errores
- ✅ Fácil de integrar en cualquier flujo
- ✅ Personalizable según tus necesidades

¡Disfruta usando este sistema en tu app! 🚀
