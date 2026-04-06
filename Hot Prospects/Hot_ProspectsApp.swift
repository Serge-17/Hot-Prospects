//
//  Hot_ProspectsApp.swift
//  Hot Prospects
//
//  Created by Serge Eliseev on 21.01.2026.
//

import SwiftUI
import SwiftData

@main
struct Hot_ProspectsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Prospect.self)
    }
}
