import SwiftUI
import SwiftData

struct BudgetForm: View {
    @Binding var amount: Double
    @Binding var period: Period
    @Binding var currency: String
    var body: some View {
        Section("Budget") {
            TextField("Budget amount", value: $amount, format: .number)
                .keyboardType(.decimalPad)
            Picker("Duration", selection: $period) {
                ForEach(Period.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            TextField("Currency code (e.g. EGP, USD)", text: $currency)
                .textInputAutocapitalization(.characters)
        }
    }
}

struct SetupView: View {
    @Environment(\.modelContext) private var ctx
    @AppStorage("budgetAmount") private var budget: Double = 0
    @AppStorage("budgetPeriod") private var period: Period = .monthly
    @AppStorage("currency") private var currency = "EGP"
    @AppStorage("didSetup") private var didSetup = false
    @State private var amount: Double = 0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Enter your home budget and how often it resets. Every purchase you add is deducted from it.")
                        .foregroundStyle(.secondary)
                }
                BudgetForm(amount: $amount, period: $period, currency: $currency)
                Button("Start") {
                    budget = amount
                    seedCategories(ctx)
                    didSetup = true
                }
                .disabled(amount <= 0)
            }
            .navigationTitle("Welcome")
        }
    }
}

func seedCategories(_ ctx: ModelContext) {
    let existing = (try? ctx.fetchCount(FetchDescriptor<Category>())) ?? 0
    guard existing == 0 else { return }
    for (n, i, c) in Category.defaults { ctx.insert(Category(name: n, icon: i, colorHex: c)) }
}
