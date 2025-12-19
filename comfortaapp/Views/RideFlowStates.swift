import SwiftUI
import CoreLocation

// MARK: - Driver En Route View

struct DriverEnRouteView: View {
    let tripData: TripData
    let driver: Driver
    let status: RideStatus
    
    var body: some View {
        VStack(spacing: 20) {
            // Status Header
            HStack {
                Image(systemName: status.icon)
                    .foregroundColor(Color(status.color))
                    .font(.title2)
                
                Text(status.rawValue)
                    .font(.title2.bold())
                
                Spacer()
            }
            
            // Driver Card
            HStack(spacing: 16) {
                // Driver Photo Placeholder
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                            .font(.title2)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(driver.name)
                        .font(.headline.bold())
                    
                    HStack {
                        ForEach(0..<5, id: \.self) { index in
                            Image(systemName: index < Int(driver.rating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                        Text(String(format: "%.1f", driver.rating))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(driver.vehicleColor) \(driver.vehicleModel)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(driver.vehiclePlate)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Button(action: {
                        // Call driver
                        print("Calling driver")
                    }) {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.green)
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        // Message driver
                        print("Messaging driver")
                    }) {
                        Image(systemName: "message.fill")
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            
            // ETA Information
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.accentColor)
                    Text("Llegada estimada")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text("\(Int(driver.estimatedArrival / 60)) min")
                        .font(.subheadline.bold())
                        .foregroundColor(.accentColor)
                }
                
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Punto de recogida")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                        Text(tripData.pickupAddress)
                            .font(.subheadline)
                            .lineLimit(2)
                    }
                    Spacer()
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Driver Arrived View

struct DriverArrivedView: View {
    let tripData: TripData
    let driver: Driver
    
    var body: some View {
        VStack(spacing: 20) {
            // Status Header
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 40))
                
                Text("¡Tu conductor ha llegado!")
                    .font(.title2.bold())
                    .textAlign(.center)
                
                Text("Busca el vehículo y aborda cuando estés listo")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Vehicle Info
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Vehículo")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                        Text("\(driver.vehicleColor) \(driver.vehicleModel)")
                            .font(.headline.bold())
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Matrícula")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                        Text(driver.vehiclePlate)
                            .font(.headline.bold())
                            .foregroundColor(.accentColor)
                    }
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Conductor")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                        Text(driver.name)
                            .font(.headline.bold())
                    }
                    
                    Spacer()
                    
                    HStack {
                        ForEach(0..<5, id: \.self) { index in
                            Image(systemName: index < Int(driver.rating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                        Text(String(format: "%.1f", driver.rating))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            
            // Action Buttons
            HStack(spacing: 16) {
                Button(action: {
                    // Call driver
                    print("Calling driver")
                }) {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("Llamar")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: {
                    // Message driver
                    print("Messaging driver")
                }) {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Mensaje")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Trip In Progress View

struct TripInProgressView: View {
    let tripData: TripData
    let driver: Driver
    
    var body: some View {
        VStack(spacing: 20) {
            // Status Header
            VStack(spacing: 8) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.purple)
                    .font(.system(size: 32))
                
                Text("Viaje en curso")
                    .font(.title2.bold())
                
                Text("Disfruta tu viaje")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Trip Info
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "flag.checkered")
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Destino")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                        Text(tripData.destinationAddress)
                            .font(.subheadline)
                            .lineLimit(2)
                    }
                    Spacer()
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tiempo estimado")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                        Text(tripData.estimatedDuration)
                            .font(.headline.bold())
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Precio")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                        Text(tripData.estimatedFare)
                            .font(.headline.bold())
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            
            // Emergency Button
            Button(action: {
                // Emergency action
                print("Emergency button pressed")
            }) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Emergencia")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Trip Completed View

struct TripCompletedView: View {
    let tripData: TripData
    let driver: Driver
    let onComplete: () -> Void
    
    @State private var driverRating: Int = 5
    @State private var feedbackText: String = ""
    
    var body: some View {
        VStack(spacing: 24) {
            // Success Header
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 50))
                
                Text("¡Viaje completado!")
                    .font(.title.bold())
                
                Text("Esperamos que hayas tenido una excelente experiencia")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Trip Summary
            VStack(spacing: 16) {
                HStack {
                    Text("Precio final")
                        .font(.headline)
                    Spacer()
                    Text(tripData.estimatedFare)
                        .font(.title2.bold())
                        .foregroundColor(.accentColor)
                }
                
                HStack {
                    Text("Duración")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(tripData.estimatedDuration)
                        .font(.subheadline.weight(.semibold))
                }
                
                HStack {
                    Text("Distancia")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(tripData.estimatedDistance)
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            
            // Rating Section
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("Califica tu experiencia con \(driver.name)")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { rating in
                            Button(action: {
                                driverRating = rating
                            }) {
                                Image(systemName: rating <= driverRating ? "star.fill" : "star")
                                    .foregroundColor(rating <= driverRating ? .yellow : .gray)
                                    .font(.title2)
                            }
                        }
                    }
                }
                
                TextField("Comentarios (opcional)", text: $feedbackText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3, reservesSpace: true)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            
            // Finish Button
            Button(action: {
                // Submit rating and complete
                submitRating()
                onComplete()
            }) {
                Text("Finalizar")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private func submitRating() {
        // Submit rating and feedback
        print("Rating submitted: \(driverRating) stars")
        print("Feedback: \(feedbackText)")
    }
}

// MARK: - Trip Cancelled View

struct TripCancelledView: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 50))
                
                Text("Viaje cancelado")
                    .font(.title.bold())
                
                Text("Tu viaje ha sido cancelado. No se ha realizado ningún cargo.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onComplete) {
                Text("Volver al inicio")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

extension Text {
    func textAlign(_ alignment: TextAlignment) -> some View {
        multilineTextAlignment(alignment)
    }
}