//
//  Laurier_ConnectApp.swift
//  Laurier Connect
//
//  Created by Chukwuka Okwusiuno on 2024-12-25.
//

import SwiftUI

struct Laurier_ConnectApp: App {
    @StateObject private var userSettings = UserSettings()
    @StateObject private var feedViewModel = FeedViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSettings)
                .environmentObject(feedViewModel)
        }
    }
}
