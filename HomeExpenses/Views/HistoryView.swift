import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \Expense.date, order: .reverse) private var all: [Expense]
    @State private var month = Date.now
    @State private var selected = Date.now
    @State private var editing: Expense?
    @State private var showAdd = false

    private let cal = Calendar.current
    private var dayItems: [Expense] { all.inPeriod(.daily, of: selected) }

    var body: some View {
        NavigationStack {
            List {
                Section { monthGrid }
                Section {
                    if dayItems.isEmpty {
                        Text("No purchases on this day").foregroundStyle(.secondary)
                    }
                    ForEach(dayItems) { e in
                        ExpenseRow(expense: e).contentShape(Rectangle()).onTapGesture { editing = e }
                            .swipeActions { Button(role: .destructive) { ctx.delete(e) } label: { Label("Delete", systemImage: "trash") } }
                    }
                } header: {
                    HStack {
                        Text(selected.formatted(date: .complete, time: .omitted))
                        Spacer()
                        Text(Money.format(dayItems.total))
                    }
                }
            }
            .navigationTitle("History")
            .toolbar { Button { showAdd = true } label: { Image(systemName: "plus") } }
            .sheet(item: $editing) { ExpenseEditor(expense: $0) }
            .sheet(isPresented: $showAdd) { ExpenseEditor(expense: nil, defaultDate: selected) }
        }
    }

    private var monthGrid: some View {
        let interval = cal.dateInterval(of: .month, for: month)!
        let firstWeekday = cal.component(.weekday, from: interval.start)
        let offset = (firstWeekday - cal.firstWeekday + 7) % 7
        let days = cal.range(of: .day, in: .month, for: month)!.count
        let monthItems = all.inPeriod(.monthly, of: month)
        let totals = Dictionary(grouping: monthItems) { cal.component(.day, from: $0.date) }.mapValues { $0.total }
        let maxDay = totals.values.max() ?? 1
        let symbols = cal.veryShortWeekdaySymbols
        let ordered = Array(symbols[(cal.firstWeekday - 1)...] + symbols[..<(cal.firstWeekday - 1)])

        return VStack(spacing: 10) {
            HStack {
                Button { month = cal.date(byAdding: .month, value: -1, to: month)! } label: { Image(systemName: "chevron.left") }
                Spacer()
                VStack {
                    Text(month.formatted(.dateTime.month(.wide).year())).font(.headline)
                    Text("Total \(Money.format(monthItems.total))").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button { month = cal.date(byAdding: .month, value: 1, to: month)! } label: { Image(systemName: "chevron.right") }
            }
            .buttonStyle(.borderless)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                ForEach(ordered.indices, id: \.self) { Text(ordered[$0]).font(.caption2).foregroundStyle(.secondary) }
                ForEach(0..<offset, id: \.self) { _ in Color.clear.frame(height: 40) }
                ForEach(1...days, id: \.self) { d in
                    let date = cal.date(byAdding: .day, value: d - 1, to: interval.start)!
                    let isSel = cal.isDate(date, inSameDayAs: selected)
                    let t = totals[d] ?? 0
                    VStack(spacing: 3) {
                        Text("\(d)").font(.callout.weight(cal.isDateInToday(date) ? .bold : .regular))
                            .foregroundStyle(isSel ? .white : .primary)
                        Circle().fill(t > 0 ? Color.orange.opacity(0.35 + 0.65 * t / maxDay) : .clear)
                            .frame(width: 6, height: 6)
                    }
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(isSel ? Color.accentColor : .clear, in: RoundedRectangle(cornerRadius: 8))
                    .onTapGesture { selected = date }
                }
            }
        }
    }
}
