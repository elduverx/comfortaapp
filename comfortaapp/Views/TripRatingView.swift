import SwiftUI
import CoreLocation

struct TripRatingView: View {
    let trip: Trip
    let onSubmit: (Double, String?) -> Void
    let onSkip: () -> Void
    
    @State private var rating: Double = 0
    @State private var feedback: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var isSubmitting = false
    @State private var showThankYou = false
    
    private let predefinedTags = [
        "Puntual", "Amable", "Conducción segura", "Vehículo limpio",
        "Buena conversación", "Silencioso", "Ayuda con equipaje", "Ruta eficiente"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        ComfortaDesign.Colors.background,
                        .black.opacity(0.8),
                        ComfortaDesign.Colors.background
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if showThankYou {
                    thankYouView
                } else {
                    ratingView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Omitir") {
                        onSkip()
                    }
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                }
            }
        }
    }
    
    private var ratingView: some View {
        ScrollView {
            VStack(spacing: ComfortaDesign.Spacing.xl) {
                Spacer(minLength: ComfortaDesign.Spacing.lg)
                
                // Trip Summary
                tripSummarySection
                
                // Rating Section
                ratingSection
                
                // Tags Section
                if rating >= 4 {
                    tagsSection
                }
                
                // Feedback Section
                feedbackSection
                
                // Submit Button
                submitButton
                
                Spacer(minLength: ComfortaDesign.Spacing.xl)
            }
            .padding(.horizontal, ComfortaDesign.Spacing.lg)
        }
    }
    
    private var tripSummarySection: some View {
        ModernCard(style: .glass) {
            VStack(spacing: ComfortaDesign.Spacing.md) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Viaje Completado")
                            .font(ComfortaDesign.Typography.title3)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        
                        Text("¿Cómo fue tu experiencia?")
                            .font(ComfortaDesign.Typography.body2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    }
                    
                    Spacer()
                }
                
                Divider().background(ComfortaDesign.Colors.glassBorder)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Desde")
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        Text(trip.pickupLocation.address)
                            .font(ComfortaDesign.Typography.body2)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Hasta")
                            .font(ComfortaDesign.Typography.caption1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                        Text(trip.destinationLocation.address)
                            .font(ComfortaDesign.Typography.body2)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
    }
    
    private var ratingSection: some View {
        ModernCard(style: .glass) {
            VStack(spacing: ComfortaDesign.Spacing.lg) {
                Text("Califica tu viaje")
                    .font(ComfortaDesign.Typography.title2)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                StarRatingView(rating: $rating, size: 44)
                
                if rating > 0 {
                    Text(ratingDescription)
                        .font(ComfortaDesign.Typography.body1)
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                        .animation(.easeInOut, value: rating)
                }
            }
        }
    }
    
    private var tagsSection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("¿Qué te gustó más?")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: ComfortaDesign.Spacing.sm) {
                    ForEach(predefinedTags, id: \.self) { tag in
                        TagChip(
                            text: tag,
                            isSelected: selectedTags.contains(tag)
                        ) {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                            HapticManager.shared.impact(.light)
                        }
                    }
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private var feedbackSection: some View {
        ModernCard(style: .glass) {
            VStack(alignment: .leading, spacing: ComfortaDesign.Spacing.md) {
                Text("Comentarios adicionales")
                    .font(ComfortaDesign.Typography.title3)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                
                Text("Opcional - Ayúdanos a mejorar")
                    .font(ComfortaDesign.Typography.caption1)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                
                TextField("Comparte tu experiencia...", text: $feedback, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
                    .font(ComfortaDesign.Typography.body2)
            }
        }
    }
    
    private var submitButton: some View {
        VStack(spacing: ComfortaDesign.Spacing.sm) {
            LiquidButton(
                "Enviar Calificación",
                icon: "star.fill",
                style: .primary,
                size: .large
            ) {
                submitRating()
            }
            .disabled(rating == 0 || isSubmitting)
            .opacity(rating == 0 ? 0.6 : 1.0)
            
            if isSubmitting {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Enviando...")
                        .font(ComfortaDesign.Typography.caption1)
                        .foregroundColor(ComfortaDesign.Colors.textSecondary)
                }
            }
        }
    }
    
    private var thankYouView: some View {
        VStack(spacing: ComfortaDesign.Spacing.xl) {
            Spacer()
            
            VStack(spacing: ComfortaDesign.Spacing.lg) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    .scaleEffect(showThankYou ? 1.0 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showThankYou)
                
                Text("¡Gracias por tu opinión!")
                    .font(ComfortaDesign.Typography.hero)
                    .foregroundColor(ComfortaDesign.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Tu feedback nos ayuda a brindar un mejor servicio")
                    .font(ComfortaDesign.Typography.body1)
                    .foregroundColor(ComfortaDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ComfortaDesign.Spacing.lg)
            }
            
            Spacer()
            
            LiquidButton(
                "Continuar",
                icon: "arrow.right",
                style: .primary,
                size: .large
            ) {
                onSkip()
            }
            .padding(.horizontal, ComfortaDesign.Spacing.lg)
            
            Spacer(minLength: ComfortaDesign.Spacing.xl)
        }
    }
    
    private var ratingDescription: String {
        switch Int(rating) {
        case 1:
            return "Muy malo"
        case 2:
            return "Malo"
        case 3:
            return "Regular"
        case 4:
            return "Bueno"
        case 5:
            return "Excelente"
        default:
            return ""
        }
    }
    
    private func submitRating() {
        guard rating > 0 else { return }
        
        isSubmitting = true
        HapticManager.shared.impact(.medium)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let feedbackText = feedback.isEmpty ? nil : feedback
            onSubmit(rating, feedbackText)
            
            withAnimation(.easeInOut(duration: 0.5)) {
                isSubmitting = false
                showThankYou = true
            }
            
            // Auto dismiss after showing thank you
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                onSkip()
            }
        }
    }
}

struct StarRatingView: View {
    @Binding var rating: Double
    let maxRating: Int = 5
    let size: CGFloat
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...maxRating, id: \.self) { star in
                Button {
                    rating = Double(star)
                    HapticManager.shared.impact(.light)
                } label: {
                    Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                        .font(.system(size: size))
                        .foregroundColor(star <= Int(rating) ? ComfortaDesign.Colors.primaryGreen : ComfortaDesign.Colors.textSecondary)
                        .scaleEffect(star == Int(rating) ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: rating)
                }
            }
        }
    }
}

struct TagChip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(ComfortaDesign.Typography.caption1)
                .foregroundColor(isSelected ? .white : ComfortaDesign.Colors.textPrimary)
                .padding(.horizontal, ComfortaDesign.Spacing.md)
                .padding(.vertical, ComfortaDesign.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: ComfortaDesign.Radius.lg)
                        .fill(
                            isSelected ?
                            ComfortaDesign.Colors.primaryGreen :
                            ComfortaDesign.Colors.surfaceSecondary
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: ComfortaDesign.Radius.lg)
                                .stroke(
                                    isSelected ?
                                    ComfortaDesign.Colors.primaryGreen :
                                    ComfortaDesign.Colors.glassBorder,
                                    lineWidth: 1
                                )
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

#Preview {
    TripRatingView(
        trip: Trip(
            userId: "123",
            pickupLocation: LocationInfo(address: "Plaza Mayor, Madrid", coordinate: CLLocationCoordinate2D(latitude: 40.4165, longitude: -3.7026)),
            destinationLocation: LocationInfo(address: "Aeropuerto Adolfo Suárez Madrid-Barajas", coordinate: CLLocationCoordinate2D(latitude: 40.4839, longitude: -3.5680)),
            estimatedFare: 45.50,
            estimatedDistance: 25.3,
            estimatedDuration: 1800,
            vehicleType: "sedan",
            paymentMethod: PaymentMethodInfo(type: .applePay)
        ),
        onSubmit: { rating, feedback in
            print("Rating: \(rating), Feedback: \(feedback ?? "None")")
        },
        onSkip: {
            print("Rating skipped")
        }
    )
}
