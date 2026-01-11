import Foundation
import PassKit
import Combine

class PaymentService: NSObject, ObservableObject {
    static let shared = PaymentService()
    
    @Published var isProcessingPayment = false
    @Published var paymentError: String?
    @Published var lastPaymentResult: PaymentResult?
    
    private let paymentsEnabled = false
    private var paymentCompletion: ((PaymentResult) -> Void)?
    private var cancellables = Set<AnyCancellable>()
    private var currentPaymentAmount: Double = 0.0
    
    override init() {
        super.init()
    }
    
    // MARK: - Apple Pay Setup
    
    func canMakeApplePayPayments() -> Bool {
        return PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks)
    }
    
    private var supportedNetworks: [PKPaymentNetwork] {
        return [
            .visa,
            .masterCard,
            .amex,
            .discover,
            .maestro
        ]
    }
    
    // MARK: - Payment Processing
    
    func processPayment(
        for trip: Trip,
        amount: Double,
        tip: Double = 0.0,
        completion: @escaping (PaymentResult) -> Void
    ) {
        guard paymentsEnabled else {
            paymentError = "Los pagos están deshabilitados temporalmente"
            completion(.failure(.paymentsDisabled))
            return
        }

        paymentCompletion = completion
        
        switch trip.paymentMethod.type {
        case .applePay:
            processApplePayPayment(trip: trip, amount: amount, tip: tip)
        case .creditCard:
            processCreditCardPayment(trip: trip, amount: amount, tip: tip)
        case .cash:
            processCashPayment(trip: trip, amount: amount, tip: tip)
        }
    }
    
    // MARK: - Apple Pay
    
    private func processApplePayPayment(trip: Trip, amount: Double, tip: Double) {
        guard canMakeApplePayPayments() else {
            paymentError = "Apple Pay no está configurado en este dispositivo"
            paymentCompletion?(.failure(.applePayNotAvailable))
            return
        }
        
        currentPaymentAmount = amount + tip
        let request = createApplePayRequest(trip: trip, amount: amount, tip: tip)
        
        let authController = PKPaymentAuthorizationController(paymentRequest: request)
        
        authController.delegate = self
        isProcessingPayment = true
        authController.present { [weak self] success in
            if !success {
                self?.isProcessingPayment = false
                self?.paymentError = "No se pudo presentar Apple Pay"
                self?.paymentCompletion?(.failure(.userCancelled))
            }
        }
        
        AnalyticsService.shared.track(.paymentInitiated, metadata: [
            "method": "apple_pay",
            "amount": String(amount),
            "trip_id": trip.id
        ])
    }
    
    private func createApplePayRequest(trip: Trip, amount: Double, tip: Double) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.com.comforta.app" // Replace with your merchant ID
        request.supportedNetworks = supportedNetworks
        request.merchantCapabilities = .capability3DS
        request.countryCode = "ES"
        request.currencyCode = "EUR"
        
        var paymentItems: [PKPaymentSummaryItem] = []
        
        // Trip fare
        paymentItems.append(PKPaymentSummaryItem(
            label: "Viaje Comforta",
            amount: NSDecimalNumber(value: amount)
        ))
        
        // Tip if provided
        if tip > 0 {
            paymentItems.append(PKPaymentSummaryItem(
                label: "Propina",
                amount: NSDecimalNumber(value: tip)
            ))
        }
        
        // Total
        let total = amount + tip
        paymentItems.append(PKPaymentSummaryItem(
            label: "Comforta",
            amount: NSDecimalNumber(value: total),
            type: .final
        ))
        
        request.paymentSummaryItems = paymentItems
        
        // Shipping contact (pickup location)
        if #available(iOS 15.0, *) {
            request.shippingType = .servicePickup
        }
        
        return request
    }
    
    // MARK: - Credit Card
    
    private func processCreditCardPayment(trip: Trip, amount: Double, tip: Double) {
        isProcessingPayment = true
        
        // Simulate credit card processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            let success = Bool.random() // Simulate success/failure
            
            if success {
                let result = PaymentResult.success(PaymentDetails(
                    transactionId: UUID().uuidString,
                    amount: amount + tip,
                    currency: "EUR",
                    method: .creditCard,
                    processorResponse: "Credit card payment successful"
                ))
                self?.lastPaymentResult = result
                self?.paymentCompletion?(result)
            } else {
                let error = PaymentError.processingFailed
                self?.paymentError = error.localizedDescription
                self?.paymentCompletion?(.failure(error))
            }
            
            self?.isProcessingPayment = false
        }
        
        AnalyticsService.shared.track(.paymentInitiated, metadata: [
            "method": "credit_card",
            "amount": String(amount),
            "trip_id": trip.id
        ])
    }
    
    // MARK: - Cash
    
    private func processCashPayment(trip: Trip, amount: Double, tip: Double) {
        // Cash payments are handled at trip completion
        let result = PaymentResult.success(PaymentDetails(
            transactionId: UUID().uuidString,
            amount: amount + tip,
            currency: "EUR",
            method: .cash,
            processorResponse: "Cash payment to be collected"
        ))
        
        lastPaymentResult = result
        paymentCompletion?(result)
        
        AnalyticsService.shared.track(.paymentInitiated, metadata: [
            "method": "cash",
            "amount": String(amount),
            "trip_id": trip.id
        ])
    }
    
    // MARK: - Payment History
    
    func getPaymentHistory() -> [PaymentRecord] {
        guard let data = UserDefaults.standard.data(forKey: "payment_history"),
              let history = try? JSONDecoder().decode([PaymentRecord].self, from: data) else {
            return []
        }
        return history.sorted { $0.processedAt > $1.processedAt }
    }
    
    private func savePaymentRecord(_ record: PaymentRecord) {
        var history = getPaymentHistory()
        history.append(record)
        
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: "payment_history")
        }
    }
}

// MARK: - PKPaymentAuthorizationControllerDelegate

extension PaymentService: PKPaymentAuthorizationControllerDelegate {
    
    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        // Process the payment with your payment processor
        processApplePayToken(payment.token) { [weak self] success, transactionId, error in
            if success, let transactionId = transactionId {
                let paymentDetails = PaymentDetails(
                    transactionId: transactionId,
                    amount: self?.currentPaymentAmount ?? 0.0,
                    currency: "EUR",
                    method: .applePay,
                    processorResponse: "Apple Pay payment successful"
                )
                
                let result = PaymentResult.success(paymentDetails)
                self?.lastPaymentResult = result
                self?.paymentCompletion?(result)
                
                // Save payment record
                let record = PaymentRecord(
                    tripId: "current_trip",
                    userId: UserManager.shared.currentUser?.id ?? "",
                    amount: self?.currentPaymentAmount ?? 0.0,
                    method: .applePay,
                    transactionId: transactionId
                )
                self?.savePaymentRecord(record)
                
                completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
                
                AnalyticsService.shared.track(.paymentCompleted, metadata: [
                    "method": "apple_pay",
                    "transaction_id": transactionId
                ])
            } else {
                self?.paymentError = error ?? "Payment processing failed"
                self?.paymentCompletion?(.failure(.processingFailed))
                completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
                
                AnalyticsService.shared.track(.paymentFailed, metadata: [
                    "method": "apple_pay",
                    "error": error ?? "unknown"
                ])
            }
        }
    }
    
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss {
            self.isProcessingPayment = false
        }
    }
    
    private func processApplePayToken(
        _ token: PKPaymentToken,
        completion: @escaping (Bool, String?, String?) -> Void
    ) {
        // In a real app, you would send the payment token to your server
        // and process it with your payment processor (Stripe, Square, etc.)
        
        // Simulate processing time
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Simulate success (90% success rate)
            let success = Int.random(in: 1...10) <= 9
            
            if success {
                let transactionId = "txn_" + UUID().uuidString.prefix(12)
                completion(true, String(transactionId), nil)
            } else {
                completion(false, nil, "Payment was declined by your bank")
            }
        }
    }
}

// MARK: - Payment Models

enum PaymentResult {
    case success(PaymentDetails)
    case failure(PaymentError)
}

struct PaymentDetails {
    let transactionId: String
    let amount: Double
    let currency: String
    let method: PaymentType
    let processorResponse: String
    let timestamp: Date
    
    init(transactionId: String, amount: Double, currency: String, method: PaymentType, processorResponse: String) {
        self.transactionId = transactionId
        self.amount = amount
        self.currency = currency
        self.method = method
        self.processorResponse = processorResponse
        self.timestamp = Date()
    }
}

enum PaymentError: LocalizedError {
    case applePayNotAvailable
    case paymentSetupFailed
    case userCancelled
    case processingFailed
    case networkError
    case invalidAmount
    case paymentsDisabled
    
    var errorDescription: String? {
        switch self {
        case .applePayNotAvailable:
            return "Apple Pay no está disponible en este dispositivo"
        case .paymentSetupFailed:
            return "Error al configurar el pago"
        case .userCancelled:
            return "Pago cancelado por el usuario"
        case .processingFailed:
            return "Error al procesar el pago"
        case .networkError:
            return "Error de conexión durante el pago"
        case .invalidAmount:
            return "Monto de pago inválido"
        case .paymentsDisabled:
            return "Los pagos están deshabilitados temporalmente"
        }
    }
}

