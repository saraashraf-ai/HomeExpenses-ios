import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \Expense.date, order: .reverse) private var all: [Expense]
    @AppStorage("budgetAmount") private var budget: Double = 0
    @AppStorage("budgetPeriod") private var period: Period = .monthly
    @AppStorage("currency") private var currency = "EGP"
    @State private var showAdd = false
    @State private var editing: Expense?

    private var current: [Expense] { all.inPeriod(period, of: .now) }
    private var spent: Double { current.total }
    private var remaining: Double { budget - spent }

    var body: some View {
        NavigationStack {
            List {
                Section { summaryCard }
                    .listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
                Section("This \(period == .daily ? "day" : period == .weekly ? "week" : "month")") {
                    if current.isEmpty {
                        ContentUnavailableView("No purchases yet", systemImage: "cart",
                                               description: Text("Tap + to add what you bought."))
                    }
                    ForEach(current) { e in
                        ExpenseRow(expense: e)
                            .contentShape(Rectangle())
                            .onTapGesture { editing = e }
                            .swipeActions {
                                Button(role: .destructive) { ctx.delete(e) } label: { Label("Delete", systemImage: "trash") }
                                Button { editing = e } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
                            }
                    }
                }
            }
            .navigationTitle("Home Expenses")
            .toolbar {
                Button { showAdd = true } label: { Image(systemName: "plus.circle.fill").font(.title2) }
            }
            .sheet(isPresented: $showAdd) { ExpenseEditor(expense: nil) }
            .sheet(item: $editing) { ExpenseEditor(expense: $0) }
        }
    }

    private var summaryCard: some View {
        let ratio = budget > 0 ? min(max(spent / budget, 0), 1) : 0
        return VStack(alignment: .leading, spacing: 10) {
            Text("\(period.title) budget · \(period.label(for: .now))").font(.caption).foregroundStyle(.secondary)
            Text(Money.format(remaining))
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(remaining < 0 ? .red : .primary)
            Text(remaining < 0 ? "Over budget" : "Remaining").font(.subheadline).foregroundStyle(.secondary)
            ProgressView(value: ratio).tint(ratio > 0.9 ? .red : ratio > 0.7 ? .orange : .green)
            HStack {
                Label("Spent \(Money.format(spent))", systemImage: "arrow.down.circle")
                Spacer()
                Label("Budget \(Money.format(budget))", systemImage: "wallet.pass")
            }
            .font(.caption)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .id(currency)
    }
}

struct ExpenseRow: View {
    let expense: Expense
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: expense.category?.icon ?? "questionmark.circle")
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(expense.category?.color ?? .gray, in: Circle())
            VStack(alignment: .leading) {
                Text(expense.name).font(.body.weight(.medium))
                Text("\(expense.category?.name ?? "Uncategorized") · \(expense.date.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("-" + Money.format(expense.amount)).font(.body.monospacedDigit()).foregroundStyle(.red)
        }
    }
}
