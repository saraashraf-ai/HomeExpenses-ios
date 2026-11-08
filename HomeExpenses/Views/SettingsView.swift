import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \Category.name) private var categories: [Category]
    @AppStorage("budgetAmount") private var budget: Double = 0
    @AppStorage("budgetPeriod") private var period: Period = .monthly
    @AppStorage("currency") private var currency = "EGP"
    @State private var editingCat: Category?
    @State private var newCat = false
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Form {
                BudgetForm(amount: $budget, period: $period, currency: $currency)
                Section("Categories") {
                    ForEach(categories) { c in
                        Label { Text(c.name) } icon: { Image(systemName: c.icon).foregroundStyle(c.color) }
                            .contentShape(Rectangle())
                            .onTapGesture { editingCat = c }
                    }
                    .onDelete { idx in idx.forEach { ctx.delete(categories[$0]) } }
                    Button { newCat = true } label: { Label("Add category", systemImage: "plus") }
                }
                Section {
                    Button("Delete all expenses", role: .destructive) { confirmReset = true }
                }
            }
            .navigationTitle("Settings")
            .sheet(item: $editingCat) { CategoryEditor(category: $0) }
            .sheet(isPresented: $newCat) { CategoryEditor(category: nil) }
            .confirmationDialog("Delete every expense?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Delete all", role: .destructive) { try? ctx.delete(model: Expense.self) }
            }
        }
    }
}

struct CategoryEditor: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    let category: Category?
    @State private var name = ""
    @State private var icon = "tag.fill"
    @State private var color = Color.blue

    private let icons = ["tag.fill", "cart.fill", "house.fill", "bolt.fill", "drop.fill", "flame.fill", "car.fill",
                         "fork.knife", "cross.case.fill", "book.fill", "tshirt.fill", "gift.fill", "pawprint.fill",
                         "wifi", "phone.fill", "sparkles", "wrench.and.screwdriver.fill", "figure.and.child.holdinghands"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                ColorPicker("Color", selection: $color, supportsOpacity: false)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))]) {
                    ForEach(icons, id: \.self) { i in
                        Image(systemName: i).frame(width: 40, height: 40)
                            .background(i == icon ? color.opacity(0.3) : .clear, in: Circle())
                            .onTapGesture { icon = i }
                    }
                }
            }
            .navigationTitle(category == nil ? "New Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let hex = color.hexString
                        if let c = category { c.name = name; c.icon = icon; c.colorHex = hex }
                        else { ctx.insert(Category(name: name, icon: icon, colorHex: hex)) }
                        dismiss()
                    }.disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let c = category { name = c.name; icon = c.icon; color = c.color }
            }
        }
    }
}

extension Color {
    var hexString: String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(max(0, min(1, r)) * 255), Int(max(0, min(1, g)) * 255), Int(max(0, min(1, b)) * 255))
    }
}
