import Foundation
import SwiftUI
import Observation

@Observable
class DiaryViewModel {
    var selectedDate = Date()
    var meals: APIClient.MealsDTO?
    var totals = APIClient.MacrosDTO(calories: 0, protein: 0, carbs: 0, fat: 0)
    var goals = APIClient.GoalsDTO(calories: 2000, protein: 150, carbs: 250, fat: 65)
    var isLoading = false
    var errorMessage: String?

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var dateString: String {
        dateFormatter.string(from: selectedDate)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var formattedDate: String {
        if isToday { return "Today" }
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: selectedDate)
    }

    var caloriesRemaining: Double {
        Double(goals.calories) - totals.calories
    }

    var calorieProgress: Double {
        goals.calories > 0 ? totals.calories / Double(goals.calories) : 0
    }

    // MARK: - Load Data

    @MainActor
    func loadDiary() async {
        isLoading = true
        do {
            async let diaryTask = APIClient.shared.getDiaryEntries(date: dateString)
            async let goalsTask = APIClient.shared.getGoals()

            let diary = try await diaryTask
            let goalsResponse = try await goalsTask

            meals = diary.meals
            totals = diary.totals
            goals = goalsResponse.goals
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func shiftDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
            Task { await loadDiary() }
        }
    }

    // MARK: - Add / Delete

    @MainActor
    func addEntry(
        mealType: String, foodName: String,
        calories: Double, protein: Double, carbs: Double, fat: Double,
        quantity: Double = 1.0, foodId: Int? = nil
    ) async {
        do {
            _ = try await APIClient.shared.addFoodEntry(
                date: dateString, mealType: mealType, foodName: foodName,
                calories: calories, protein: protein, carbs: carbs, fat: fat,
                quantity: quantity, foodId: foodId
            )
            await loadDiary()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func deleteEntry(id: Int) async {
        do {
            try await APIClient.shared.deleteFoodEntry(id: id)
            await loadDiary()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    func entries(for mealType: String) -> [APIClient.FoodEntryDTO] {
        guard let meals = meals else { return [] }
        switch mealType {
        case "breakfast": return meals.breakfast
        case "lunch": return meals.lunch
        case "dinner": return meals.dinner
        case "snacks": return meals.snacks
        default: return []
        }
    }

    func mealCalories(for mealType: String) -> Double {
        entries(for: mealType).reduce(0) { $0 + $1.calories }
    }
}
