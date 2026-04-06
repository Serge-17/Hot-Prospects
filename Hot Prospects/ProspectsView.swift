//
//  ProspectsView.swift
//  Hot Prospects
//
//  Created by Serge Eliseev on 04.02.2026.
//

import SwiftUI
import SwiftData
import CodeScanner
internal import AVFoundation
import UserNotificationsUI

struct ProspectsView: View {
    enum FilterType {
        case none, contacted, uncontacted
    }
    
    enum SortType: String, CaseIterable, Identifiable {
        case name = "Name"
        case lastContacted = "Last Contacted"
        var id: String { rawValue }
    }
    
    @Environment(\.modelContext) var modelContext
    
    let filter: FilterType
    
    @State private var sortType: SortType = .name
    @State private var sortedProspects: [Prospect] = []
    @State private var isShowingScanner = false
    @State private var selectedProspects = Set<Prospect>()
    @State private var editingProspect: Prospect? = nil
    
    var title: String {
        switch filter {
        case .none:
            return "Everyone"
        case .contacted:
            return "Contacted people"
        case .uncontacted:
            return "Uncontacted people"
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Sort by", selection: $sortType) {
                    ForEach(SortType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: sortType) { _ in
                    fetchProspects()
                }
                
                List(selection: $selectedProspects) {
                    ForEach(sortedProspects) { prospect in
                        Button {
                            editingProspect = prospect
                        } label: {
                            HStack {
                                if filter == .none {
                                    if prospect.isContacted {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    } else {
                                        Image(systemName: "xmark.circle")
                                            .foregroundColor(.gray)
                                    }
                                }
                                VStack(alignment: .leading) {
                                    Text(prospect.name)
                                        .font(.headline)
                                    Text(prospect.emailAddress)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                modelContext.delete(prospect)
                                fetchProspects()
                            }
                            
                            if prospect.isContacted {
                                Button("Mark Uncontacted", systemImage: "person.crop.circle.badge.xmark") {
                                    prospect.isContacted = false
                                    prospect.lastContacted = nil
                                    try? modelContext.save()
                                    fetchProspects()
                                }
                                .tint(.blue)
                            } else {
                                Button("Mark Contacted", systemImage: "person.crop.circle.fill.badge.checkmark") {
                                    prospect.isContacted = true
                                    prospect.lastContacted = Date()
                                    try? modelContext.save()
                                    fetchProspects()
                                }
                                .tint(.green)
                                
                                Button("Remind Me", systemImage: "bell") {
                                    addNotification(for: prospect)
                                }
                                .tint(.orange)
                            }
                        }
                    }
                }
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing){
                        Button("Scan", systemImage: "qrcode.viewfinder") {
                            isShowingScanner = true
                        }
                    }
                    
                    ToolbarItem(placement: .topBarLeading){
                        EditButton()
                    }
                    
                    if selectedProspects.isEmpty == false {
                        ToolbarItem(placement: .bottomBar) {
                            Button("Delete Selected", action: delete)
                        }
                    }
                }
                .sheet(isPresented: $isShowingScanner) {
                    CodeScannerView(codeTypes: [.qr], simulatedData: "Paul Hudson\npaul@hackingwithswift.com", completion: handleScan)
                }
                .sheet(item: $editingProspect) { prospect in
                    EditProspectView(prospect: binding(for: prospect))
                }
            }
            .onAppear(perform: fetchProspects)
        }
    }
    
    init(filter: FilterType) {
        self.filter = filter
    }
    
    private func fetchProspects() {
        let predicate: Predicate<Prospect>?
        switch filter {
        case .none:
            predicate = nil
        case .contacted:
            predicate = #Predicate { $0.isContacted == true }
        case .uncontacted:
            predicate = #Predicate { $0.isContacted == false }
        }
        
        let sortDescriptor: SortDescriptor<Prospect>
        switch sortType {
        case .name:
            sortDescriptor = SortDescriptor(\.name)
        case .lastContacted:
            // Sort descending by lastContacted, then by name ascending
            sortDescriptor = SortDescriptor(\.lastContacted, order: .reverse)
        }
        
        let fetchRequest: FetchDescriptor<Prospect>
        if let predicate {
            fetchRequest = FetchDescriptor(predicate: predicate, sortBy: [sortDescriptor])
        } else {
            fetchRequest = FetchDescriptor(sortBy: [sortDescriptor])
        }
        
        do {
            sortedProspects = try modelContext.fetch(fetchRequest)
        } catch {
            print("Fetch failed: \(error.localizedDescription)")
            sortedProspects = []
        }
    }
    
    private func binding(for prospect: Prospect) -> Binding<Prospect> {
        guard let index = sortedProspects.firstIndex(where: { $0.id == prospect.id }) else {
            fatalError("Prospect not found")
        }
        return $sortedProspects[index]
    }
    
    func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        
        switch result {
        case .success(let result):
            let details = result.string.components(separatedBy: "\n")
            guard details.count == 2 else { return }

            let person = Prospect(name: details[0], emailAddress: details[1], isContacted: false)

            modelContext.insert(person)
            do {
                try modelContext.save()
            } catch {
                print("Failed to save after scan: \(error.localizedDescription)")
            }
            fetchProspects()
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
    
    func delete() {
        for prospect in selectedProspects {
            modelContext.delete(prospect)
        }
        do {
            try modelContext.save()
        } catch {
            print("Failed to save after delete: \(error.localizedDescription)")
        }
        selectedProspects.removeAll()
        fetchProspects()
    }
    
    func addNotification(for prospect: Prospect) {
        let center = UNUserNotificationCenter.current()

        let addRequest = {
            let content = UNMutableNotificationContent()
            content.title = "Contact \(prospect.name)"
            content.subtitle = prospect.emailAddress
            content.sound = UNNotificationSound.default

//            var dateComponents = DateComponents()
//            dateComponents.hour = 9
//            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
        }

        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                addRequest()
            } else {
                center.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        addRequest()
                    } else if let error {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}


#Preview {
    ProspectsView(filter: .none)
        .modelContainer(for: Prospect.self)
}

