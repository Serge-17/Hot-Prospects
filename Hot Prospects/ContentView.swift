//
//  ContentView.swift
//  Hot Prospects
//
//  Created by Serge Eliseev on 21.01.2026.
//

import SwiftUI
import SwiftData


struct ContentView: View {
    var body: some View {
        TabView {
            ProspectsView(filter: .none)
                .tabItem {
                    Label("Everyone", systemImage: "person.3")
                }
            ProspectsView(filter: .contacted)
                .tabItem {
                    Label("Contacted", systemImage: "checkmark.circle")
                }
            ProspectsView(filter: .uncontacted)
                .tabItem {
                    Label("Uncontacted", systemImage: "questionmark.diamond")
                }
            MeView()
                .tabItem {
                    Label("Me", systemImage: "person.crop.square")
                }
        }
    }
}

struct PreviewContentView: View {
    var body: some View {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Prospect.self, configurations: configuration)
        let context = container.mainContext
        let testProspects = [
            Prospect(name: "Иван Иванов", emailAddress: "ivanov@site.ru", isContacted: true),
            Prospect(name: "Мария Петрова", emailAddress: "petrova@site.ru", isContacted: false),
            Prospect(name: "Джон Смит", emailAddress: "john@smith.com", isContacted: false)
        ]
        testProspects.forEach { context.insert($0) }
        return ContentView()
            .modelContainer(container)
    }
}

#Preview {
    PreviewContentView()
}
