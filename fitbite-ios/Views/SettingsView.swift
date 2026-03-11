import SwiftUI

struct SettingsView: View {
    @Environment(AuthViewModel.self) var authVM
    @State private var calories = "2000"
    @State private var protein = "150"
    @State private var carbs = "250"
    @State private var fat = "65"
    @State private var isLoading = false
    @State private var showSaved = false
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    goalField(label: "Calories", value: $calories, unit: "kcal", icon: "flame.fill", color: .blue)
                    goalField(label: "Protein", value: $protein, unit: "g", icon: "fish.fill", color: .red)
                    goalField(label: "Carbs", value: $carbs, unit: "g", icon: "leaf.fill", color: .orange)
                    goalField(label: "Fat", value: $fat, unit: "g", icon: "drop.fill", color: .blue)
                } header: {
                    Text("Daily Goals")
                } footer: {
                    Text("Set your daily nutrition targets. These are used to calculate your progress.")
                }

                Section {
                    Button {
                        Task { await saveGoals() }
                    } label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                            } else if showSaved {
                                Label("Saved!", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Text("Save Goals")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showLogoutConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Log Out")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Log out?", isPresented: $showLogoutConfirm) {
                Button("Log Out", role: .destructive) { authVM.logout() }
                Button("Cancel", role: .cancel) {}
            }
            .task {
                await loadGoals()
            }
        }
    }

    private func goalField(label: String, value: Binding<String>, unit: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label)
            Spacer()
            TextField("0", text: value)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text(unit)
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }

    private func loadGoals() async {
        do {
            let response = try await APIClient.shared.getGoals()
            calories = "\(response.goals.calories)"
            protein = "\(response.goals.protein)"
            carbs = "\(response.goals.carbs)"
            fat = "\(response.goals.fat)"
        } catch {
            print("Failed to load goals: \(error)")
        }
    }

    private func saveGoals() async {
        isLoading = true
        do {
            _ = try await APIClient.shared.updateGoals(
                calories: Int(calories) ?? 2000,
                protein: Int(protein) ?? 150,
                carbs: Int(carbs) ?? 250,
                fat: Int(fat) ?? 65
            )
            showSaved = true
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showSaved = false
        } catch {
            print("Failed to save goals: \(error)")
        }
        isLoading = false
    }
}
