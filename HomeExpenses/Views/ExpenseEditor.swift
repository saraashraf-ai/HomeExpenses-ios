import SwiftUI
import SwiftData

/// Create (expense == nil) or update an expense.
struct ExpenseEditor: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.name) private var categories: [Category]
    let expense: Expense?
    var defaultDate: Date = .now

    @State private var name = ""
    @State private var amount: Double?
    @State private var date = Date.now
    @State private var note = ""
    @State private var category: Category?

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("What did you buy?", text: $name)
                    TextField("Price", value: $amount, format: .number).keyboardType(.decimalPad)
                    DatePicker("Date", selection: $date)
                }
                Section("Category") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                        ForEach(categories) { c in
                            VStack(spacing: 4) {
                                Image(systemName: c.icon).font(.title3).foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(c.color, in: Circle())
                                    .overlay(Circle().stroke(Color.primary, lineWidth: category == c ? 3 : 0))
                                Text(c.name).font(.caption2).lineLimit(1)
                            }
                            .onTapGesture { category = c }
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("Note") { TextField("Optional", text: $note, axis: .vertical) }
                if let expense {
                    Section {
                        Button("Delete item", role: .destructive) { ctx.delete(expense); dismiss() }
                    }
                }
            }
            .navigationTitle(expense == nil ? "Add Purchase" : "Edit Purchase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || (amount ?? 0) <= 0)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if let e = expense {
            name = e.name; amount = e.amount; date = e.date; note = e.note; category = e.category
        } else {
            date = defaultDate
            category = categories.first { $0.name == "Other" } ?? categories.first
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let e = expense {
            e.name = trimmed; e.amount = amount ?? 0; e.date = date; e.note = note; e.category = category
        } else {
            ctx.insert(Expense(name: trimmed, amount: amount ?? 0, date: date, note: note, category: category))
        }
        dismiss()
    }
}
