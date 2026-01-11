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
            if let tripId = notification.userInfo?["trip_id"] as? String,
               let trip = TripBookingService.shared.getTrip(by: tripId) {
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
        if let userId = userManager.currentUser?.id {
            Task {
                let isValid = await userManager.validateExistingSession(userId: userId)
                    .values.first(where: { _ in true })
                if isValid == false {
                    userManager.signOut()
                }
            }
        }
    }
    
    private func refreshUserSession() {
        if let userId = userManager.currentUser?.id {
            Task {
                _ = await userManager.validateExistingSession(userId: userId)
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

    private var modernSignInView: some View {
        ZStack {
            // Animated Background
            LinearGradient(
                colors: [
                    .black,
                    ComfortaDesign.Colors.background,
                    ComfortaDesign.Colors.primaryGreen.opacity(0.12),
                    ComfortaDesign.Colors.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: ComfortaDesign.Spacing.xxl) {
                Spacer()
                
                // Logo and Title
                VStack(spacing: ComfortaDesign.Spacing.lg) {
                    // Logo placeholder
                    Image("AppIcon")
                        .font(.system(size: 80, weight: .light))
                        .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                    
                    VStack(spacing: ComfortaDesign.Spacing.sm) {
                        Text("Comforta")
                            .font(ComfortaDesign.Typography.hero)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        
                        Text("Viaje a larga distancia al precio verdadero")
                            .font(ComfortaDesign.Typography.body1)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Sign In Card
                ModernCard(style: .glass) {
                    VStack(spacing: ComfortaDesign.Spacing.lg) {
                        Text("Bienvenido")
                            .font(ComfortaDesign.Typography.title3)
                            .foregroundColor(ComfortaDesign.Colors.textPrimary)
                        
                        Text("Conecta para unirte a los viajes premium")
                            .font(ComfortaDesign.Typography.body2)
                            .foregroundColor(ComfortaDesign.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        // Apple Sign In Button
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            handleAuthorization(result: result)
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 52)
                        .cornerRadius(ComfortaDesign.Radius.md)
                        
                        // Admin Login Button
                        Button {
                            handleAdminLogin()
                        } label: {
                            HStack {
                                Image(systemName: "person.badge.key.fill")
                                Text("Iniciar como administrador")
                            }
                            .font(ComfortaDesign.Typography.body2)
                            .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                            .frame(height: 52)
                            .frame(maxWidth: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: ComfortaDesign.Radius.md)
                                    .stroke(ComfortaDesign.Colors.primaryGreen, lineWidth: 2)
                            )
                        }
                        
                        if let authError = userManager.authenticationError {
                            Text(authError)
                                .foregroundColor(ComfortaDesign.Colors.error)
                                .font(ComfortaDesign.Typography.caption1)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(.horizontal, ComfortaDesign.Spacing.xl)
                
                Spacer()
                
                // Footer
                VStack(spacing: ComfortaDesign.Spacing.xs) {
                    Text("Al continuar, aceptas nuestros")
                        .font(ComfortaDesign.Typography.caption2)
                        .foregroundColor(ComfortaDesign.Colors.textTertiary)
                    
                    HStack(spacing: ComfortaDesign.Spacing.xs) {
                        Button("Términos de servicio") {}
                        Text("y")
                        Button("Política de privacidad") {}
                    }
                    .font(ComfortaDesign.Typography.caption2)
                    .foregroundColor(ComfortaDesign.Colors.primaryGreen)
                }
                .padding(.bottom, ComfortaDesign.Spacing.xl)
            }
        }
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
