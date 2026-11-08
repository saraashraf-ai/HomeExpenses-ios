import SwiftUI
import SwiftData
import Charts

struct ReportsView: View {
    @Query(sort: \Expense.date) private var all: [Expense]
    @AppStorage("budgetAmount") private var budget: Double = 0
    @AppStorage("budgetPeriod") private var budgetPeriod: Period = .monthly
    @State private var period: Period = .monthly
    @State private var anchor = Date.now
    @State private var pdfURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Report", selection: $period) {
                        ForEach(Period.allCases) { Text($0.title).tag($0) }
                    }.pickerStyle(.segmented)
                    HStack {
                        Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                        Spacer(); Text(period.label(for: anchor)).font(.headline); Spacer()
                        Button { shift(1) } label: { Image(systemName: "chevron.right") }
                    }
                    ReportContent(items: all.inPeriod(period, of: anchor), period: period, anchor: anchor,
                                  budget: comparableBudget)
                }
                .padding()
            }
            .navigationTitle("Reports")
            .toolbar {
                if let pdfURL {
                    ShareLink(item: pdfURL) { Label("Export PDF", systemImage: "square.and.arrow.up") }
                }
            }
            .onAppear(perform: makePDF)
            .onChange(of: period) { makePDF() }
            .onChange(of: anchor) { makePDF() }
            .onChange(of: all.count) { makePDF() }
        }
    }

    /// Converts the user's budget into the report's period length (approximate: 7 days/week, 30 days/month).
    private var comparableBudget: Double {
        let days: [Period: Double] = [.daily: 1, .weekly: 7, .monthly: 30]
        return budget / days[budgetPeriod]! * days[period]!
    }

    private func shift(_ n: Int) {
        anchor = Calendar.current.date(byAdding: period.component, value: n, to: anchor) ?? anchor
    }

    @MainActor private func makePDF() {
        let content = VStack(alignment: .leading, spacing: 12) {
            Text("Home Expenses – \(period.title) Report").font(.title2.bold())
            Text(period.label(for: anchor)).foregroundStyle(.secondary)
            ReportContent(items: all.inPeriod(period, of: anchor), period: period, anchor: anchor,
                          budget: comparableBudget, showItems: true)
        }
        .padding(24).frame(width: 595)
        let renderer = ImageRenderer(content: content)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Expenses-\(period.title)-Report.pdf")
        renderer.render { size, draw in
            var box = CGRect(origin: .zero, size: size)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            pdf.beginPDFPage(nil); draw(pdf); pdf.endPDFPage(); pdf.closePDF()
        }
        pdfURL = url
    }
}

struct ReportContent: View {
    let items: [Expense]
    let period: Period
    let anchor: Date
    let budget: Double
    var showItems = false

    var body: some View {
        let cats = items.byCategory()
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                stat("Spent", Money.format(items.total), .red)
                stat("Budget", Money.format(budget), .blue)
                stat(budget - items.total >= 0 ? "Saved" : "Over", Money.format(abs(budget - items.total)),
                     budget - items.total >= 0 ? .green : .orange)
            }
            HStack {
                stat("Purchases", "\(items.count)", .primary)
                stat("Biggest", items.max(by: { $0.amount < $1.amount }).map { Money.format($0.amount) } ?? "–", .primary)
            }
            if items.isEmpty {
                Text("No expenses in this period.").foregroundStyle(.secondary).frame(maxWidth: .infinity).padding()
            } else {
                Text("By category").font(.headline)
                Chart(cats, id: \.name) { c in
                    SectorMark(angle: .value("Total", c.total), innerRadius: .ratio(0.55), angularInset: 1.5)
                        .foregroundStyle(c.color)
                }
                .frame(height: 200)
                ForEach(cats, id: \.name) { c in
                    HStack {
                        Image(systemName: c.icon).foregroundStyle(c.color).frame(width: 24)
                        Text(c.name)
                        Spacer()
                        Text("\(Int((c.total / max(items.total, 1)) * 100))%").foregroundStyle(.secondary)
                        Text(Money.format(c.total)).monospacedDigit()
                    }.font(.subheadline)
                }
                if period != .daily {
                    Text("Spending per day").font(.headline)
                    Chart(perDay, id: \.0) { d in
                        BarMark(x: .value("Day", d.0, unit: .day), y: .value("Amount", d.1))
                            .foregroundStyle(.orange.gradient)
                    }
                    .frame(height: 160)
                }
                if showItems {
                    Text("All items").font(.headline)
                    ForEach(items) { e in
                        HStack {
                            Text(e.date.formatted(.dateTime.day().month())).foregroundStyle(.secondary).frame(width: 60, alignment: .leading)
                            Text(e.name); Text("(\(e.category?.name ?? "-"))").foregroundStyle(.secondary)
                            Spacer(); Text(Money.format(e.amount))
                        }.font(.caption)
                    }
                }
            }
        }
    }

    private var perDay: [(Date, Double)] {
        Dictionary(grouping: items) { Calendar.current.startOfDay(for: $0.date) }
            .map { ($0.key, $0.value.total) }.sorted { $0.0 < $1.0 }
    }

    private func stat(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline.monospacedDigit()).foregroundStyle(color).minimumScaleFactor(0.6).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }
}
