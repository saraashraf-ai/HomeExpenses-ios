import SwiftUI
import SwiftData

@main
struct HomeExpensesApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(for: [Expense.self, Category.self])
    }
}

struct RootView: View {
    @AppStorage("budgetAmount") private var budget: Double = 0
    @AppStorage("didSetup") private var didSetup = false

    var body: some View {
        if didSetup {
            TabView {
                HomeView().tabItem { Label("Expenses", systemImage: "list.bullet.rectangle") }
                HistoryView().tabItem { Label("Calendar", systemImage: "calendar") }
                ReportsView().tabItem { Label("Reports", systemImage: "chart.pie") }
                SettingsView().tabItem { Label("Settings", systemImage: "gearshape") }
            }
        } else {
            SetupView()
        }
    }
}
