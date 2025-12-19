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
    @AppStorage("isSignedIn") private var isSignedIn: Bool = false
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userId") private var userId: String = ""
    @State private var authError: String?

    var body: some View {
        Group {
            if isSignedIn {
                SimpleRideView(
                    userName: userName,
                    onLogout: signOut
                )
            } else {
                signInView
            }
        }
        .animation(.easeInOut, value: isSignedIn)
    }

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

            if let authError {
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
            let name = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")

            userId = credential.user
            if !name.isEmpty { userName = name }
            authError = nil
            withAnimation { isSignedIn = true }
        case .failure(let error):
            authError = error.localizedDescription
        }
    }

    private func signOut() {
        userName = ""
        userId = ""
        withAnimation { isSignedIn = false }
    }

}

#Preview {
    ContentView()
}
