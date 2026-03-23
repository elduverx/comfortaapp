//
//  comfortaappApp.swift
//  comfortaapp
//
//  Created by duverney muriel on 13/12/25.
//

import SwiftUI

@main
struct comfortaappApp: App {
    // Conectar el AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
