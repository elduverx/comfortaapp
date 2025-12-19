import Foundation

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

class PricingService {
    func calculatePricing(origin: String, destination: String) async throws -> PricingResponse {
        // Simular llamada a API del backend
        // El backend usa Google Distance Matrix API para calcular distancia exacta
        let body = [
            "origin": origin,
            "destination": destination
        ]
        
        // Por ahora, retornar datos simulados
        // En producción, esto sería una llamada real al backend
        return PricingResponse(
            distance: 15.2,
            estimatedTime: "25 min",
            basePrice: 8.50,
            totalPrice: 23.75,
            priceBreakdown: PriceBreakdown(
                baseRate: 8.50,
                distanceRate: 12.80,
                timeRate: 2.45,
                additionalFees: 0.00
            )
        )
    }
}