//
//  ContentView.swift
//  comfortaapp
//
//  Created by duverney muriel on 13/12/25.
//

import SwiftUI
import Combine
import AuthenticationServices
import MapKit

struct ContentView: View {
    @StateObject private var userManager = UserManager.shared
    @StateObject private var notificationService = NotificationService.shared
    @State private var showingTripRating = false
    @State private var showingAdminPanel = false
    @State private var activeTrip: Trip?
    @State private var tripToRate: Trip?
    @Environment(\.scenePhase) private var scenePhase
    

    var body: some View {
        Group {
            if userManager.isAuthenticated, let user = userManager.currentUser {
                if user.userType == .admin {
                    AdminDashboardView()
                } else {
                    mainAppView(for: user)
                }
            } else {
                modernSignInView
            }
        }
        .animation(.easeInOut, value: userManager.isAuthenticated)
        .onAppear {
            setupApp()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                refreshUserSession()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showTripRating)) { notification in
            if let trip = notification.userInfo?["trip"] as? Trip {
                tripToRate = trip
                showingTripRating = true
                return
            }

            if let tripId = notification.userInfo?["trip_id"] as? String,
               let trip = resolveTripForRating(tripId: tripId) {
                tripToRate = trip
                showingTripRating = true
            }
        }
        .sheet(isPresented: $showingTripRating) {
            if let trip = tripToRate {
                TripRatingView(
                    trip: trip,
                    onSubmit: { rating, feedback in
                        TripBookingService.shared.rateTrip(trip.id, rating: rating, feedback: feedback)
                        showingTripRating = false
                    },
                    onRequestAnotherTrip: {
                        TripServiceAPI.shared.clearActiveTrip()
                        TripBookingService.shared.activeTrip = nil
                        NotificationCenter.default.post(name: .requestNewTrip, object: nil)
                        showingTripRating = false
                    },
                    onSkip: {
                        showingTripRating = false
                    }
                )
            }
        }
    }
    
    private func mainAppView(for user: User) -> some View {
        MainTabView(
            userName: user.firstName,
            onLogout: {
                userManager.signOut()
            }
        )
        .environmentObject(userManager)
        .onAppear {
            requestNotificationPermission()
        }
    }
    
    private func setupApp() {
        // Request notification permissions
        requestNotificationPermission()
        
        // Validate existing session
        if userManager.isAuthenticated,
           let appleUserId = UserDefaults.standard.string(forKey: "apple_user_id") {
            Task {
                let isValid = await userManager.validateExistingSession(userId: appleUserId)
                    .values.first(where: { _ in true })
                if isValid == false {
                    userManager.signOut()
                }
            }
        }
    }
    
    private func refreshUserSession() {
        if userManager.isAuthenticated,
           let appleUserId = UserDefaults.standard.string(forKey: "apple_user_id") {
            Task {
                _ = await userManager.validateExistingSession(userId: appleUserId)
                    .values.first(where: { _ in true })
            }
        }
    }
    
    private func requestNotificationPermission() {
        Task {
            let granted = await notificationService.requestNotificationPermission()
                .values.first(where: { _ in true }) ?? false
            
            await MainActor.run {
                if granted {
                    AnalyticsService.shared.track(.notificationsEnabled)
                } else {
                    AnalyticsService.shared.track(.notificationsDenied)
                }
            }
        }
    }

    private func resolveTripForRating(tripId: String) -> Trip? {
        if let trip = TripBookingService.shared.getTrip(by: tripId) {
            return trip
        }

        if let apiTrip = TripServiceAPI.shared.getTripById(tripId) {
            return mapAPITripForRating(apiTrip)
        }

        if let adminTrip = AdminService.shared.allTrips.first(where: { $0.id == tripId }) {
            return adminTrip
        }

        return nil
    }

    private func mapAPITripForRating(_ apiTrip: APITrip) -> Trip {
        let pickupAddress = apiTrip.lugarRecogida ?? "Recogida no especificada"
        let pickupLocation = LocationInfo(
            address: pickupAddress,
            coordinate: coordinateFromAPI(lat: apiTrip.pickupLat, lng: apiTrip.pickupLng)
        )
        let destinationLocation = LocationInfo(
            address: apiTrip.destino,
            coordinate: coordinateFromAPI(lat: apiTrip.destinationLat, lng: apiTrip.destinationLng)
        )

        let estimatedDuration = estimateDurationSeconds(distanceKm: apiTrip.distanciaKm)
        let paymentMethod = PaymentMethodInfo(
            type: paymentType(from: apiTrip.paymentMethod),
            displayName: apiTrip.paymentMethod
        )

        return Trip(
            id: apiTrip.id,
            userId: userManager.currentUser?.id ?? "user",
            status: .completed,
            pickupLocation: pickupLocation,
            destinationLocation: destinationLocation,
            estimatedFare: apiTrip.precioTotal ?? 0,
            estimatedDistance: apiTrip.distanciaKm ?? 0,
            estimatedDuration: estimatedDuration,
            vehicleType: "Standard",
            paymentMethod: paymentMethod,
            createdAt: apiTrip.createdAt.toDate() ?? Date(),
            scheduledAt: apiTrip.fechaInicio.toDate()
        )
    }

    private func coordinateFromAPI(lat: Double?, lng: Double?) -> CLLocationCoordinate2D {
        if let lat = lat, let lng = lng {
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
        return CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }

    private func estimateDurationSeconds(distanceKm: Double?) -> Double {
        guard let distanceKm = distanceKm else { return 0 }
        return (distanceKm / 50.0) * 3600.0
    }

    private func paymentType(from method: String?) -> PaymentType {
        switch method?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "APPLE_PAY":
            return .applePay
        case "CASH", "EFECTIVO":
            return .cash
        default:
            return .creditCard
        }
    }

    private var modernSignInView: some View {
        AnimatedSignInView(
            userManager: userManager,
            handleAuthorization: handleAuthorization,
            handleAdminLogin: handleAdminLogin
        )
    }
    
    // Legacy sign in view for fallback
    private var signInView: some View {
        VStack(spacing: 24) {
            Spacer()
            VStack(spacing: 8) {
                Text("Comforta")
                    .font(.largeTitle.bold())
                Text("Tu viaje privado en minutos")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handleAuthorization(result: result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 32)

            if let authError = userManager.authenticationError {
                Text(authError)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .background(
            LinearGradient(
                colors: [.black.opacity(0.9), .black.opacity(0.6), .gray.opacity(0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .foregroundStyle(.white)
    }


    private func handleAuthorization(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
            UserDefaults.standard.set(credential.user, forKey: "apple_user_id")
            userManager.signIn(with: credential)
        case .failure(let error):
            userManager.authenticationError = error.localizedDescription
        }
    }
    
    private func handleAdminLogin() {
        userManager.signInAsAdmin()
    }

}

#Preview {
    ContentView()
}
