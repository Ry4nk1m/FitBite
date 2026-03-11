import SwiftUI

struct MealType: Identifiable {
    let id: String
    let label: String
    let icon: String
    let color: Color
}

let mealTypes: [MealType] = [
    MealType(id: "breakfast", label: "Breakfast", icon: "cup.and.saucer.fill", color: .orange),
    MealType(id: "lunch", label: "Lunch", icon: "sun.max.fill", color: .blue),
    MealType(id: "dinner", label: "Dinner", icon: "moon.fill", color: .purple),
    MealType(id: "snacks", label: "Snacks", icon: "leaf.fill", color: .green),
]

struct DiaryView: View {
    @State private var vm = DiaryViewModel()
    @State private var showAddFood = false
    @State private var selectedMealType: String = "breakfast"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    dateSelector
                    calorieCard
                    remainingLabel

                    ForEach(mealTypes) { meal in
                        mealCard(meal)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("FitBite")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await vm.loadDiary()
            }
            .task {
                await vm.loadDiary()
            }
            .sheet(isPresented: $showAddFood) {
                AddFoodView(mealType: selectedMealType) { name, cal, pro, carb, fat, qty, foodId in
                    Task {
                        await vm.addEntry(
                            mealType: selectedMealType, foodName: name,
                            calories: cal, protein: pro, carbs: carb, fat: fat,
                            quantity: qty, foodId: foodId
                        )
                    }
                }
            }
        }
    }

    // MARK: - Date Selector

    private var dateSelector: some View {
        HStack {
            Button { vm.shiftDate(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 32, height: 32)
                    .background(.gray.opacity(0.1))
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text(vm.formattedDate)
                    .font(.system(size: 15, weight: .semibold))
                if !vm.isToday {
                    Text(vm.dateString)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button { vm.shiftDate(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 32, height: 32)
                    .background(.gray.opacity(0.1))
                    .clipShape(Circle())
            }
            .disabled(vm.isToday)
            .opacity(vm.isToday ? 0.3 : 1)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Calorie Card

    private var calorieCard: some View {
        HStack(spacing: 20) {
            CalorieRing(
                progress: vm.calorieProgress,
                current: Int(vm.totals.calories),
                goal: vm.goals.calories,
                color: vm.calorieProgress > 1 ? .red : .blue
            )
            .frame(width: 110, height: 110)

            VStack(spacing: 14) {
                MacroRow(label: "Protein", current: vm.totals.protein, goal: Double(vm.goals.protein), color: .red, icon: "fish.fill")
                MacroRow(label: "Carbs", current: vm.totals.carbs, goal: Double(vm.goals.carbs), color: .orange, icon: "leaf.fill")
                MacroRow(label: "Fat", current: vm.totals.fat, goal: Double(vm.goals.fat), color: .blue, icon: "drop.fill")
            }
        }
        .padding(20)
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
    }

    // MARK: - Remaining

    private var remainingLabel: some View {
        Text(vm.caloriesRemaining >= 0
             ? "\(Int(vm.caloriesRemaining)) kcal remaining"
             : "\(Int(abs(vm.caloriesRemaining))) kcal over goal")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(vm.caloriesRemaining >= 0 ? .green : .red)
    }

    // MARK: - Meal Card

    private func mealCard(_ meal: MealType) -> some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: meal.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(meal.color)
                        .frame(width: 36, height: 36)
                        .background(meal.color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(meal.label)
                            .font(.system(size: 15, weight: .semibold))
                        let cals = vm.mealCalories(for: meal.id)
                        if cals > 0 {
                            Text("\(Int(cals)) kcal")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                Button {
                    selectedMealType = meal.id
                    showAddFood = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(meal.color)
                        .frame(width: 30, height: 30)
                        .background(meal.color.opacity(0.12))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            let entries = vm.entries(for: meal.id)
            ForEach(entries) { entry in
                Divider().padding(.leading, 16)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.foodName)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)
                        Text("\(Int(entry.calories)) cal · \(Int(entry.protein))p · \(Int(entry.carbs))c · \(Int(entry.fat))f")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        Task { await vm.deleteEntry(id: entry.id) }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(.red.opacity(0.5))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
    }
}

// MARK: - Calorie Ring Component

struct CalorieRing: View {
    let progress: Double
    let current: Int
    let goal: Int
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(.gray.opacity(0.12), lineWidth: 10)

            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: progress)

            VStack(spacing: 2) {
                Text("\(current)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("of \(goal)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Macro Row Component

struct MacroRow: View {
    let label: String
    let current: Double
    let goal: Double
    let color: Color
    let icon: String

    var progress: Double {
        goal > 0 ? min(current / goal, 1) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(current))")
                    .font(.system(size: 16, weight: .semibold))
                Text("/\(Int(goal))g")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.gray.opacity(0.12))
                    Capsule().fill(color)
                        .frame(width: geo.size.width * progress)
                        .animation(.easeOut(duration: 0.4), value: progress)
                }
            }
            .frame(height: 4)
        }
    }
}
