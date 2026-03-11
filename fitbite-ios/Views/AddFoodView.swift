import SwiftUI

struct AddFoodView: View {
    let mealType: String
    let onAdd: (String, Double, Double, Double, Double, Double, Int?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var tab: AddFoodTab = .search
    @State private var searchText = ""
    @State private var searchResults: [APIClient.FoodDTO] = []
    @State private var customResults: [APIClient.FoodDTO] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    // Custom entry fields
    @State private var customName = ""
    @State private var customCalories = ""
    @State private var customProtein = ""
    @State private var customCarbs = ""
    @State private var customFat = ""

    enum AddFoodTab {
        case search, custom
    }

    var mealLabel: String {
        mealTypes.first(where: { $0.id == mealType })?.label ?? mealType.capitalized
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $tab) {
                    Text("Search Foods").tag(AddFoodTab.search)
                    Text("Custom Entry").tag(AddFoodTab.custom)
                }
                .pickerStyle(.segmented)
                .padding()

                if tab == .search {
                    searchView
                } else {
                    customView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add to \(mealLabel)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Search View

    private var searchView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search foods...", text: $searchText)
                    .autocapitalization(.none)
                    .onChange(of: searchText) { _, newValue in
                        performSearch(query: newValue)
                    }
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(.white)
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom, 8)

            ScrollView {
                LazyVStack(spacing: 0) {
                    if !customResults.isEmpty {
                        sectionHeader("Your Foods")
                        ForEach(customResults) { food in
                            foodRow(food)
                        }
                    }

                    if !searchResults.isEmpty {
                        sectionHeader("Database")
                        ForEach(searchResults) { food in
                            foodRow(food)
                        }
                    }

                    if searchResults.isEmpty && customResults.isEmpty && !searchText.isEmpty && !isSearching {
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("No foods found")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Try a different search or add a custom entry")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.top, 40)
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 6)
    }

    private func foodRow(_ food: APIClient.FoodDTO) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(food.name)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    if let serving = food.servingDescription {
                        Text(serving)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("·")
                            .foregroundStyle(.secondary)
                    }
                    Text("\(Int(food.calories)) cal · \(Int(food.protein))p · \(Int(food.carbs))c · \(Int(food.fat))f")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                onAdd(food.name, food.calories, food.protein, food.carbs, food.fat, 1.0, food.id)
                dismiss()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.white)
    }

    // MARK: - Custom View

    private var customView: some View {
        ScrollView {
            VStack(spacing: 16) {
                customField("Food Name", text: $customName, keyboard: .default)

                HStack(spacing: 12) {
                    customNumberField("Calories", text: $customCalories)
                    customNumberField("Protein (g)", text: $customProtein)
                }
                HStack(spacing: 12) {
                    customNumberField("Carbs (g)", text: $customCarbs)
                    customNumberField("Fat (g)", text: $customFat)
                }

                Button {
                    let cal = Double(customCalories) ?? 0
                    let pro = Double(customProtein) ?? 0
                    let carb = Double(customCarbs) ?? 0
                    let fat = Double(customFat) ?? 0
                    onAdd(customName, cal, pro, carb, fat, 1.0, nil)
                    dismiss()
                } label: {
                    Text("Add Food")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(customIsValid ? .blue : .gray.opacity(0.3))
                        .foregroundStyle(customIsValid ? .white : .secondary)
                        .cornerRadius(14)
                }
                .disabled(!customIsValid)
            }
            .padding()
        }
    }

    private var customIsValid: Bool {
        !customName.isEmpty && !(customCalories.isEmpty)
    }

    private func customField(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboard)
            .padding()
            .background(.white)
            .cornerRadius(12)
    }

    private func customNumberField(_ placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(placeholder)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .padding()
                .background(.white)
                .cornerRadius(12)
        }
    }

    // MARK: - Search Logic

    private func performSearch(query: String) {
        searchTask?.cancel()
        guard query.count >= 2 else {
            searchResults = []
            customResults = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            isSearching = true
            do {
                let response = try await APIClient.shared.searchFoods(query: query)
                if !Task.isCancelled {
                    searchResults = response.foods
                    customResults = response.customFoods
                }
            } catch {
                print("Search error: \(error)")
            }
            isSearching = false
        }
    }
}
