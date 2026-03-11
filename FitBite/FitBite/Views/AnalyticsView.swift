import SwiftUI
import Charts

struct AnalyticsView: View {
    @State private var vm = AnalyticsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        summaryCard(title: "Avg. Calories", value: "\(vm.averageCalories)", unit: "kcal/day", color: .blue)
                        summaryCard(title: "Avg. Protein", value: "\(vm.averageProtein)", unit: "g/day", color: .red)
                    }

                    if vm.streak > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            Text("\(vm.streak) day logging streak")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.orange)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(.orange.opacity(0.08))
                        .cornerRadius(12)
                    }

                    calorieChart
                    macroChart
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Analytics")
            .task {
                await vm.loadSummary()
            }
            .refreshable {
                await vm.loadSummary()
            }
        }
    }

    private func summaryCard(title: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
    }

    private var calorieChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weekly Calories")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.blue)
            }

            Chart(vm.dailyData, id: \.label) { day in
                BarMark(
                    x: .value("Day", day.label),
                    y: .value("Calories", day.calories)
                )
                .foregroundStyle(.blue.opacity(0.8))
                .cornerRadius(6)
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding(20)
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
    }

    private var macroChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Macro Trends")
                .font(.system(size: 16, weight: .bold))

            HStack(spacing: 16) {
                legendDot(color: .red, label: "Protein")
                legendDot(color: .orange, label: "Carbs")
                legendDot(color: .blue, label: "Fat")
            }
            .font(.caption)

            Chart {
                ForEach(vm.dailyData, id: \.label) { day in
                    LineMark(x: .value("Day", day.label), y: .value("g", day.protein))
                        .foregroundStyle(.red)
                    LineMark(x: .value("Day", day.label), y: .value("g", day.carbs))
                        .foregroundStyle(.orange)
                    LineMark(x: .value("Day", day.label), y: .value("g", day.fat))
                        .foregroundStyle(.blue)
                }
            }
            .frame(height: 160)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding(20)
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).foregroundStyle(.secondary)
        }
    }
}
