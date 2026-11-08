import Foundation
import SwiftData
import SwiftUI

enum Period: String, CaseIterable, Identifiable, Codable {
    case daily, weekly, monthly
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var component: Calendar.Component {
        switch self { case .daily: .day; case .weekly: .weekOfYear; case .monthly: .month }
    }
    /// Start/end of the period that contains `date`.
    func interval(containing date: Date) -> DateInterval {
        Calendar.current.dateInterval(of: component, for: date)
            ?? DateInterval(start: date, duration: 86_400)
    }
    func label(for date: Date) -> String {
        let i = interval(containing: date)
        switch self {
        case .daily: return date.formatted(date: .complete, time: .omitted)
        case .weekly:
            let end = i.end.addingTimeInterval(-1)
            return "\(i.start.formatted(.dateTime.day().month())) – \(end.formatted(.dateTime.day().month().year()))"
        case .monthly: return date.formatted(.dateTime.month(.wide).year())
        }
    }
}

@Model
final class Category {
    var name: String
    var icon: String
    var colorHex: String
    @Relationship(deleteRule: .nullify, inverse: \Expense.category) var expenses: [Expense]? = []

    init(name: String, icon: String, colorHex: String) {
        self.name = name; self.icon = icon; self.colorHex = colorHex
    }
    var color: Color { Color(hex: colorHex) }

    static let defaults: [(String, String, String)] = [
        ("Groceries", "cart.fill", "#34C759"),
        ("Bills & Utilities", "bolt.fill", "#FF9500"),
        ("Rent", "house.fill", "#5856D6"),
        ("Transport", "car.fill", "#007AFF"),
        ("Health", "cross.case.fill", "#FF3B30"),
        ("Education", "book.fill", "#AF52DE"),
        ("Cleaning", "sparkles", "#5AC8FA"),
        ("Other", "ellipsis.circle.fill", "#8E8E93")
    ]
}

@Model
final class Expense {
    var name: String
    var amount: Double
    var date: Date
    var note: String
    var category: Category?

    init(name: String, amount: Double, date: Date = .now, note: String = "", category: Category? = nil) {
        self.name = name; self.amount = amount; self.date = date; self.note = note; self.category = category
    }
}

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }
}

enum Money {
    static var currency: String { UserDefaults.standard.string(forKey: "currency") ?? "EGP" }
    static func format(_ v: Double) -> String { v.formatted(.currency(code: currency)) }
}

extension Array where Element == Expense {
    var total: Double { reduce(0) { $0 + $1.amount } }
    func inPeriod(_ p: Period, of date: Date) -> [Expense] {
        let i = p.interval(containing: date)
        return filter { $0.date >= i.start && $0.date < i.end }
    }
    /// Totals by category name, largest first.
    func byCategory() -> [(name: String, color: Color, icon: String, total: Double)] {
        Dictionary(grouping: self) { $0.category?.name ?? "Uncategorized" }
            .map { key, items in
                let c = items.first?.category
                return (key, c?.color ?? .gray, c?.icon ?? "questionmark.circle", items.total)
            }
            .sorted { $0.total > $1.total }
    }
}
