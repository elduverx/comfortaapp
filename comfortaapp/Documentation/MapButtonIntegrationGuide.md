# Guía de Integración: Botón "Seleccionar en el Mapa"

## 🎯 Descripción

Se ha agregado un botón **"Seleccionar en el mapa"** debajo de los inputs de destino en las vistas principales de la aplicación. Este botón abre el selector de destino interactivo con tap directo en el mapa.

## 📍 Ubicaciones Implementadas

### 1. **Step1TripDataView** (Wizard de Reservas)
**Archivo:** `Views/Step1TripDataView.swift`

**Ubicación:** Debajo del campo "¿A dónde vamos?"

**Características:**
- ✅ Botón azul con gradiente
- ✅ Ícono de mapa
- ✅ Flecha indicadora
- ✅ Validación de ubicación de recogida
- ✅ Actualiza automáticamente el campo de destino

**Código:**
```swift
Section("¿A dónde vamos?") {
    AddressSearchField(
        selectedAddress: $viewModel.destino,
        placeholder: "Dirección de destino"
    )

    // Botón para seleccionar en el mapa
    Button {
        showMapSelector = true
    } label: {
        HStack(spacing: 12) {
            Image(systemName: "map.fill")
            Text("Seleccionar en el mapa")
            Spacer()
            Image(systemName: "chevron.right")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(...))
        )
    }
}
```

### 2. **SimpleRideView** (Vista Principal de Viajes)
**Archivo:** `Views/SimpleRideView.swift`

**Ubicación:** Debajo del campo de destino y las sugerencias

**Características:**
- ✅ Diseño compacto adaptado a la UI existente
- ✅ Cierra automáticamente las sugerencias
- ✅ Desactiva el teclado antes de abrir el mapa
- ✅ Actualiza ruta automáticamente
- ✅ Integrado con SimpleRideViewModel

**Código:**
```swift
// Botón para seleccionar en el mapa
Button {
    isDestinationFieldFocused = false
    viewModel.deactivateFields()
    showMapSelector = true
} label: {
    HStack(spacing: 12) {
        Image(systemName: "map.fill")
        Text("Seleccionar en el mapa")
        Spacer()
        Image(systemName: "chevron.right")
    }
    .padding()
    .background(RoundedRectangle(cornerRadius: 10).fill(...))
}
```

## 🔧 Cambios en ViewModels

### WizardViewModel
**Archivo:** `ViewModels/WizardViewModel.swift`

**Propiedades Agregadas:**
```swift
// Coordenadas de ubicaciones
@Published var lugarRecogidaCoordinate: CLLocationCoordinate2D?
@Published var destinoCoordinate: CLLocationCoordinate2D?
```

**Beneficios:**
- Almacena coordenadas exactas además de direcciones
- Útil para cálculos de distancia y rutas
- Mejora precisión en la geocodificación

## 🎨 Diseño del Botón

### Estilo Visual

```
┌─────────────────────────────────────────┐
│  🗺️  Seleccionar en el mapa        ›   │
└─────────────────────────────────────────┘
```

**Características de diseño:**
- **Color:** Azul con gradiente (.blue → .blue.opacity(0.8))
- **Forma:** RoundedRectangle con cornerRadius 10-12
- **Ícono:** `map.fill` (mapa relleno)
- **Indicador:** `chevron.right` (flecha derecha)
- **Texto:** Peso semibold, color blanco
- **Padding:** 10-16 puntos horizontal y vertical

### Variantes por Vista

| Vista | Corner Radius | Padding H | Padding V | Tamaño |
|-------|--------------|-----------|-----------|--------|
| Step1TripDataView | 12 | 16 | 12 | Grande |
| SimpleRideView | 10 | 14 | 10 | Compacto |

## 📱 Flujo de Usuario

### En Step1TripDataView:

1. Usuario ingresa ubicación de recogida (requerido)
2. Usuario toca "Seleccionar en el mapa"
3. **Si NO hay recogida:** Muestra mensaje de error
4. **Si hay recogida:** Abre mapa con pin de recogida
5. Usuario toca el mapa donde quiere ir
6. Aparece panel de confirmación con dirección
7. Usuario confirma
8. Campo de destino se actualiza automáticamente
9. Sheet se cierra

### En SimpleRideView:

1. Usuario ingresa ubicación de recogida (requerido)
2. Usuario toca "Seleccionar en el mapa"
3. **Acción:** Cierra teclado y sugerencias
4. Abre mapa con pin de recogida
5. Usuario toca el mapa
6. Confirma destino
7. **Acciones automáticas:**
   - Actualiza `destinationText`
   - Actualiza `destinationCoordinate`
   - Llama `fetchRoute()` para dibujar ruta
   - Cierra sheet

## ⚠️ Validaciones

### Validación de Ubicación de Recogida

Ambas vistas validan que exista una ubicación de recogida antes de abrir el mapa:

```swift
if let pickupCoord = getPickupCoordinate() {
    // Mostrar MapDestinationPicker
} else {
    // Mostrar mensaje de error
    VStack {
        Image(systemName: "exclamationmark.triangle.fill")
        Text("Primero selecciona la ubicación de recogida")
        Button("Cerrar") { ... }
    }
}
```

### Prioridad de Coordenadas (Step1TripDataView)

```swift
private func getPickupCoordinate() -> CLLocationCoordinate2D? {
    // 1. Coordenadas guardadas en ViewModel
    if let coord = viewModel.lugarRecogidaCoordinate {
        return coord
    }

    // 2. Ubicación actual del dispositivo
    if let location = locationService.currentLocation {
        return location.coordinate
    }

    // 3. Ubicación por defecto (Valencia)
    return CLLocationCoordinate2D(latitude: 39.4699, longitude: -0.3763)
}
```

## 🔗 Integración con MapDestinationPicker

### Sheet Configuration

```swift
.sheet(isPresented: $showMapSelector) {
    NavigationView {
        MapDestinationPicker(
            selectedDestination: $selectedDestinationCoord,
            selectedAddress: $selectedDestinationAddress,
            pickupLocation: pickupCoord,
            pickupAddress: pickupAddress,
            onDestinationConfirmed: { coordinate, address in
                // Actualizar ViewModel
                viewModel.destino = address
                viewModel.destinoCoordinate = coordinate
                showMapSelector = false
            }
        )
        .navigationTitle("Seleccionar destino")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cerrar") {
                    showMapSelector = false
                }
            }
        }
    }
}
```

### Callback onDestinationConfirmed

El callback se ejecuta cuando el usuario confirma el destino:

**Step1TripDataView:**
```swift
onDestinationConfirmed: { coordinate, address in
    viewModel.destino = address
    viewModel.destinoCoordinate = coordinate
    showMapSelector = false
}
```

**SimpleRideView:**
```swift
onDestinationConfirmed: { coordinate, address in
    viewModel.destinationCoordinate = coordinate
    viewModel.destinationText = address
    viewModel.fetchRoute()  // Dibuja ruta en el mapa
    showMapSelector = false
}
```

## 🎯 Casos de Uso

### Caso 1: Usuario Nuevo
1. Abre la app
2. Ve el botón "Seleccionar en el mapa"
3. Toca el botón
4. Ve mensaje "Primero selecciona recogida"
5. Ingresa recogida
6. Vuelve a tocar el botón
7. Selecciona destino en el mapa

### Caso 2: Usuario Experimentado
1. Ingresa recogida rápidamente
2. Toca "Seleccionar en el mapa"
3. Toca destino en el mapa
4. Confirma
5. Continúa con la reserva

### Caso 3: Cambio de Destino
1. Ya tiene destino seleccionado
2. Quiere cambiarlo
3. Toca el campo de destino
4. Borra el texto
5. Toca "Seleccionar en el mapa"
6. Selecciona nuevo destino

## 🐛 Solución de Problemas

### El botón no aparece
**Problema:** No veo el botón "Seleccionar en el mapa"

**Solución:**
1. Verifica que estés en Step1TripDataView o SimpleRideView
2. Asegúrate de que la vista se haya actualizado
3. Recompila la app

### El mapa no se abre
**Problema:** Al tocar el botón no pasa nada

**Solución:**
1. Verifica que `showMapSelector` esté funcionando
2. Revisa que el sheet esté correctamente implementado
3. Comprueba errores en la consola

### Error de coordenadas
**Problema:** Mensaje de "Primero selecciona recogida"

**Solución:**
1. Ingresa una dirección de recogida válida
2. O usa el botón "Usar mi ubicación actual"
3. Verifica permisos de ubicación

## 📊 Beneficios

### Para el Usuario
- ✅ **Más rápido:** Selección visual directa
- ✅ **Más preciso:** Toca exactamente donde quiere ir
- ✅ **Más intuitivo:** No necesita escribir direcciones largas
- ✅ **Más flexible:** Puede explorar el mapa libremente

### Para el Negocio
- ✅ **Menos errores:** Geocodificación más precisa
- ✅ **Mejor UX:** Interfaz moderna y profesional
- ✅ **Más conversiones:** Flujo más simple = más reservas
- ✅ **Diferenciación:** Feature profesional vs competencia

## 🚀 Mejoras Futuras

- [ ] Agregar botón similar para seleccionar recogida
- [ ] Mostrar lugares de interés en el mapa
- [ ] Sugerir destinos frecuentes
- [ ] Agregar favoritos en el mapa
- [ ] Mostrar preview de la ruta antes de confirmar
- [ ] Feedback háptico al seleccionar
- [ ] Animación de "ripple" en el tap

## 📝 Notas Técnicas

### Dependencias
- MapKit
- CoreLocation
- SwiftUI
- MapDestinationPicker component

### Compatibilidad
- iOS 17.0+
- Requiere permisos de ubicación
- Funciona offline (excepto geocodificación)

### Performance
- Lazy loading del mapa
- Cache de geocodificación activo
- Animaciones optimizadas

---

## ✅ Resumen

El botón "Seleccionar en el mapa" ha sido exitosamente integrado en:

1. ✅ **Step1TripDataView** - Wizard de reservas
2. ✅ **SimpleRideView** - Vista principal
3. ✅ **WizardViewModel** - Almacenamiento de coordenadas

**Resultado:** Los usuarios ahora pueden seleccionar destinos tocando directamente en el mapa, mejorando significativamente la experiencia de usuario. 🎉
