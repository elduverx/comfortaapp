import Foundation
import CoreLocation
import Combine

class PricingService: ObservableObject {
    static let shared = PricingService()
    
    @Published var currentPricing = PricingStructure()
    @Published var surgeMultiplier: Double = 1.0
    @Published var isHighDemandPeriod = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadPricingStructure()
        setupDemandMonitoring()
    }
    
    // MARK: - Legacy Support
    
    func calculatePricing(origin: String, destination: String) async throws -> PricingResponse {
        // Legacy method for backward compatibility
        let estimatedDistance = Double.random(in: 5...50)
        let estimatedDuration = estimateDuration(distance: estimatedDistance)
        
        let baseFare = currentPricing.baseFare
        let distanceFare = estimatedDistance * currentPricing.perKilometerRate
        let timeFare = (estimatedDuration / 60.0) * currentPricing.perMinuteRate
        let totalFare = (baseFare + distanceFare + timeFare) * surgeMultiplier
        
        return PricingResponse(
            distance: estimatedDistance,
            estimatedTime: formatDuration(estimatedDuration),
            basePrice: baseFare,
            totalPrice: max(totalFare, currentPricing.minimumFare),
            priceBreakdown: PriceBreakdown(
                baseRate: baseFare,
                distanceRate: distanceFare,
                timeRate: timeFare,
                additionalFees: 0.00
            )
        )
    }
    
    // MARK: - Advanced Fare Calculation
    
    func calculateFare(distance: Double, vehicleType: String, duration: TimeInterval? = nil) -> Double {
        let baseFare = currentPricing.baseFare
        let distanceFare = distance * currentPricing.perKilometerRate
        
        var durationFare: Double = 0
        if let duration = duration {
            durationFare = (duration / 60.0) * currentPricing.perMinuteRate
        }
        
        // Vehicle type multiplier
        let vehicleMultiplier = currentPricing.vehicleMultipliers[vehicleType] ?? 1.0
        
        // Base calculation
        var totalFare = (baseFare + distanceFare + durationFare) * vehicleMultiplier
        
        // Apply surge pricing if applicable
        totalFare *= surgeMultiplier
        
        // Apply minimum fare
        totalFare = max(totalFare, currentPricing.minimumFare)
        
        return round(totalFare * 100) / 100 // Round to 2 decimal places
    }
    
    func calculateAdvancedFare(
        pickup: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        vehicleType: VehicleType,
        scheduledTime: Date? = nil,
        promoCode: String? = nil
    ) -> FareBreakdown {
        let distance = calculateDistance(from: pickup, to: destination)
        let estimatedDuration = estimateDuration(distance: distance)
        
        let baseFare = currentPricing.baseFare
        let distanceFare = distance * currentPricing.perKilometerRate
        let durationFare = (estimatedDuration / 60.0) * currentPricing.perMinuteRate
        let vehicleMultiplier = vehicleType.baseRate
        
        var subtotal = (baseFare + distanceFare + durationFare) * vehicleMultiplier
        
        // Time-based surges
        let timeSurge = calculateTimeSurge(for: scheduledTime ?? Date())
        let demandSurge = surgeMultiplier
        let totalSurge = max(timeSurge, demandSurge)
        
        let surgeAmount = subtotal * (totalSurge - 1.0)
        subtotal += surgeAmount
        
        // Booking fees
        var bookingFee: Double = 0
        if scheduledTime != nil {
            bookingFee = 2.00
        }
        
        // Tolls estimation (basic)
        let tollEstimate = estimateTolls(from: pickup, to: destination)
        
        // Discount from promo code
        var discount: Double = 0
        if let promoCode = promoCode {
            discount = calculatePromoDiscount(code: promoCode, subtotal: subtotal)
        }
        
        let total = max(subtotal + bookingFee + tollEstimate - discount, currentPricing.minimumFare)
        
        return FareBreakdown(
            baseFare: baseFare,
            distanceFare: distanceFare,
            timeFare: durationFare,
            vehicleMultiplier: vehicleMultiplier,
            surgeMultiplier: totalSurge,
            surgeAmount: surgeAmount,
            bookingFee: bookingFee,
            tollEstimate: tollEstimate,
            discount: discount,
            promoCode: promoCode,
            subtotal: subtotal,
            total: total,
            estimatedDistance: distance,
            estimatedDuration: estimatedDuration
        )
    }
    
    // MARK: - Surge Pricing
    
    private func calculateTimeSurge(for date: Date) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let weekday = calendar.component(.weekday, from: date)
        
        // Weekend nights (Friday & Saturday)
        if (weekday == 6 || weekday == 7) && (hour >= 22 || hour <= 3) {
            return 1.5
        }
        
        // Rush hours
        if (hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19) {
            return 1.3
        }
        
        // Late night
        if hour >= 23 || hour <= 5 {
            return 1.2
        }
        
        return 1.0
    }
    
    private func setupDemandMonitoring() {
        // Simulate demand monitoring
        Timer.publish(every: 300, on: .main, in: .common) // Check every 5 minutes
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateDemandSurge()
            }
            .store(in: &cancellables)
    }
    
    private func updateDemandSurge() {
        // In a real app, this would analyze current demand vs supply
        let simulatedDemand = Double.random(in: 0.8...2.0)
        
        DispatchQueue.main.async {
            self.surgeMultiplier = simulatedDemand
            self.isHighDemandPeriod = simulatedDemand > 1.3
        }
        
        if isHighDemandPeriod {
            AnalyticsService.shared.track(.surgeActivated, metadata: [
                "multiplier": String(surgeMultiplier)
            ])
        }
    }
    
    // MARK: - Promo Codes
    
    private func calculatePromoDiscount(code: String, subtotal: Double) -> Double {
        // Simple promo code system
        let promoCodes = [
            "WELCOME10": PromoCode(code: "WELCOME10", discountType: .percentage, discountValue: 10, maxDiscount: 15),
            "SAVE5": PromoCode(code: "SAVE5", discountType: .fixed, discountValue: 5, maxDiscount: 5),
            "FIRST20": PromoCode(code: "FIRST20", discountType: .percentage, discountValue: 20, maxDiscount: 25)
        ]
        
        guard let promo = promoCodes[code.uppercased()] else {
            return 0
        }
        
        switch promo.discountType {
        case .percentage:
            let discount = subtotal * (promo.discountValue / 100.0)
            return min(discount, promo.maxDiscount)
        case .fixed:
            return min(promo.discountValue, subtotal * 0.8) // Max 80% discount
        }
    }
    
    // MARK: - Helper Methods
    
    func estimateDuration(distance: Double) -> TimeInterval {
        // More sophisticated duration estimation
        let baseSpeed: Double = 50 // km/h in city
        let trafficMultiplier = calculateTrafficMultiplier()
        let effectiveSpeed = baseSpeed * trafficMultiplier
        
        return (distance / effectiveSpeed) * 3600.0
    }
    
    private func calculateTrafficMultiplier() -> Double {
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Rush hours have slower speeds
        if (hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19) {
            return 0.6
        }
        
        // Off-peak hours
        if hour >= 22 || hour <= 6 {
            return 1.2
        }
        
        return 1.0
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000.0 // Convert to kilometers
    }
    
    private func estimateTolls(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let distance = calculateDistance(from: from, to: to)
        
        // Simple toll estimation based on distance
        if distance > 50 {
            return 8.50 // Highway tolls
        } else if distance > 20 {
            return 3.20 // City tolls
        }
        
        return 0
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }
    
    // MARK: - Configuration
    
    func updatePricingStructure(_ newPricing: PricingStructure) {
        currentPricing = newPricing
        savePricingStructure()
        
        AnalyticsService.shared.track(.pricingUpdated)
    }
    
    private func loadPricingStructure() {
        if let data = UserDefaults.standard.data(forKey: "pricing_structure"),
           let pricing = try? JSONDecoder().decode(PricingStructure.self, from: data) {
            currentPricing = pricing
        } else {
            // Default pricing structure
            currentPricing = PricingStructure()
        }
    }
    
    private func savePricingStructure() {
        if let encoded = try? JSONEncoder().encode(currentPricing) {
            UserDefaults.standard.set(encoded, forKey: "pricing_structure")
        }
    }
    
    // MARK: - Public Interface
    
    func getFareEstimate(pickup: String, destination: String, vehicleType: VehicleType) -> String {
        // This would typically use actual coordinates
        let estimatedDistance = Double.random(in: 5...50)
        let fare = calculateFare(distance: estimatedDistance, vehicleType: vehicleType.rawValue, duration: nil)
        
        if surgeMultiplier > 1.1 {
            return "€\(String(format: "%.2f", fare)) (Tarifa alta x\(String(format: "%.1f", surgeMultiplier)))"
        }
        
        return "€\(String(format: "%.2f", fare))"
    }
}

// MARK: - Legacy Types (for backward compatibility)

struct PricingResponse: Codable {
    let distance: Double
    let estimatedTime: String
    let basePrice: Double
    let totalPrice: Double
    let priceBreakdown: PriceBreakdown
}

struct PriceBreakdown: Codable {
    let baseRate: Double
    let distanceRate: Double
    let timeRate: Double
    let additionalFees: Double
}

// MARK: - New Types

struct FareBreakdown {
    let baseFare: Double
    let distanceFare: Double
    let timeFare: Double
    let vehicleMultiplier: Double
    let surgeMultiplier: Double
    let surgeAmount: Double
    let bookingFee: Double
    let tollEstimate: Double
    let discount: Double
    let promoCode: String?
    let subtotal: Double
    let total: Double
    let estimatedDistance: Double
    let estimatedDuration: TimeInterval
}

struct PromoCode {
    let code: String
    let discountType: DiscountType
    let discountValue: Double
    let maxDiscount: Double
    
    enum DiscountType {
        case percentage
        case fixed
    }
}

// PricingStructure is already defined in AdminService.swift with Codable conformance