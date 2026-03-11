import Foundation
import Observation

@Observable
class AnalyticsViewModel {
    var summary: APIClient.SummaryResponse?
    var isLoading = false
    var streak = 0

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    @MainActor
    func loadSummary() async {
        isLoading = true
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -6, to: end)!

        do {
            summary = try await APIClient.shared.getSummary(
                start: dateFormatter.string(from: start),
                end: dateFormatter.string(from: end)
            )
            streak = summary?.streak ?? 0
        } catch {
            print("Analytics error: \(error)")
        }
        isLoading = false
    }

    var averageCalories: Int {
        Int(summary?.averages.calories ?? 0)
    }

    var averageProtein: Int {
        Int(summary?.averages.protein ?? 0)
    }

    var dailyData: [(label: String, calories: Double, protein: Double, carbs: Double, fat: Double)] {
        guard let days = summary?.days else { return [] }
        let shortFormatter = DateFormatter()
        shortFormatter.dateFormat = "yyyy-MM-dd"
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "EEE"

        return days.compactMap { day in
            guard let date = shortFormatter.date(from: day.date) else { return nil }
            return (
                label: displayFormatter.string(from: date),
                calories: day.calories,
                protein: day.protein,
                carbs: day.carbs,
                fat: day.fat
            )
        }
    }
}
