import SwiftUI

struct EditProspectView: View {
    @Binding var prospect: Prospect
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("Имя", text: $prospect.name)
                TextField("Email", text: $prospect.emailAddress)
            }
            .navigationTitle("Редактировать")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    // Предпросмотр с моковыми данными
    EditProspectView(prospect: .constant(Prospect(name: "Имя", emailAddress: "test@email.ru", isContacted: false)))
}
