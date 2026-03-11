import Foundation

// MARK: - API Configuration

enum APIConfig {
    // Change this to your server URL
    static let baseURL = "http://localhost:5000/api"
}

// MARK: - API Error

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(String)
    case decodingError
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .unauthorized: return "Session expired. Please log in again."
        case .serverError(let msg): return msg
        case .decodingError: return "Failed to process server response"
        case .networkError(let err): return err.localizedDescription
        }
    }
}

// MARK: - Token Storage

class TokenManager {
    static let shared = TokenManager()
    private let accessKey = "fitbite_access_token"
    private let refreshKey = "fitbite_refresh_token"

    var accessToken: String? {
        get { UserDefaults.standard.string(forKey: accessKey) }
        set { UserDefaults.standard.set(newValue, forKey: accessKey) }
    }

    var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: refreshKey) }
        set { UserDefaults.standard.set(newValue, forKey: refreshKey) }
    }

    var isLoggedIn: Bool { accessToken != nil }

    func clear() {
        accessToken = nil
        refreshToken = nil
    }
}

// MARK: - API Client

class APIClient {
    static let shared = APIClient()
    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - Generic Request

    private func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        authenticated: Bool = true
    ) async throws -> T {
        guard let url = URL(string: "\(APIConfig.baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if authenticated, let token = TokenManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        if httpResponse.statusCode >= 400 {
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorResponse["error"] as? String {
                throw APIError.serverError(message)
            }
            throw APIError.serverError("Server error (\(httpResponse.statusCode))")
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }

    // MARK: - Auth

    struct AuthResponse: Decodable {
        let user: UserDTO
        let accessToken: String
        let refreshToken: String
        let message: String?
    }

    struct UserDTO: Decodable {
        let id: Int
        let email: String
        let username: String
        let createdAt: String
    }

    func register(email: String, username: String, password: String) async throws -> AuthResponse {
        return try await request(
            endpoint: "/auth/register",
            method: "POST",
            body: ["email": email, "username": username, "password": password],
            authenticated: false
        )
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        return try await request(
            endpoint: "/auth/login",
            method: "POST",
            body: ["email": email, "password": password],
            authenticated: false
        )
    }

    func refreshAccessToken() async throws {
        guard let refreshToken = TokenManager.shared.refreshToken else {
            throw APIError.unauthorized
        }

        guard let url = URL(string: "\(APIConfig.baseURL)/auth/refresh") else {
            throw APIError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await session.data(for: req)
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let newToken = json["access_token"] as? String {
            TokenManager.shared.accessToken = newToken
        }
    }

    // MARK: - Diary

    struct DiaryResponse: Decodable {
        let date: String
        let meals: MealsDTO
        let totals: MacrosDTO
        let entryCount: Int
    }

    struct MealsDTO: Decodable {
        let breakfast: [FoodEntryDTO]
        let lunch: [FoodEntryDTO]
        let dinner: [FoodEntryDTO]
        let snacks: [FoodEntryDTO]
    }

    struct FoodEntryDTO: Decodable, Identifiable {
        let id: Int
        let date: String
        let mealType: String
        let foodName: String
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
        let quantity: Double
        let loggedAt: String
        let foodId: Int?
    }

    struct MacrosDTO: Decodable {
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
    }

    struct EntryResponse: Decodable {
        let entry: FoodEntryDTO
    }

    func getDiaryEntries(date: String) async throws -> DiaryResponse {
        return try await request(endpoint: "/diary/entries?date=\(date)")
    }

    func addFoodEntry(
        date: String, mealType: String, foodName: String,
        calories: Double, protein: Double, carbs: Double, fat: Double,
        quantity: Double = 1.0, foodId: Int? = nil
    ) async throws -> EntryResponse {
        var body: [String: Any] = [
            "date": date, "meal_type": mealType, "food_name": foodName,
            "calories": calories, "protein": protein, "carbs": carbs,
            "fat": fat, "quantity": quantity
        ]
        if let foodId = foodId { body["food_id"] = foodId }
        return try await request(endpoint: "/diary/entries", method: "POST", body: body)
    }

    func deleteFoodEntry(id: Int) async throws {
        let _: [String: String] = try await request(endpoint: "/diary/entries/\(id)", method: "DELETE")
    }

    // MARK: - Summary

    struct SummaryResponse: Decodable {
        let start: String
        let end: String
        let days: [DaySummaryDTO]
        let averages: MacrosDTO
        let streak: Int
    }

    struct DaySummaryDTO: Decodable {
        let date: String
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
        let entryCount: Int
    }

    func getSummary(start: String, end: String) async throws -> SummaryResponse {
        return try await request(endpoint: "/diary/summary?start=\(start)&end=\(end)")
    }

    // MARK: - Goals

    struct GoalsResponse: Decodable {
        let goals: GoalsDTO
    }

    struct GoalsDTO: Decodable {
        let calories: Int
        let protein: Int
        let carbs: Int
        let fat: Int
    }

    func getGoals() async throws -> GoalsResponse {
        return try await request(endpoint: "/goals")
    }

    func updateGoals(calories: Int, protein: Int, carbs: Int, fat: Int) async throws -> GoalsResponse {
        return try await request(
            endpoint: "/goals", method: "PUT",
            body: ["calories": calories, "protein": protein, "carbs": carbs, "fat": fat]
        )
    }

    // MARK: - Food Search

    struct FoodSearchResponse: Decodable {
        let foods: [FoodDTO]
        let customFoods: [FoodDTO]
    }

    struct FoodDTO: Decodable, Identifiable {
        let id: Int
        let name: String
        let servingDescription: String?
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
        let category: String?
    }

    func searchFoods(query: String) async throws -> FoodSearchResponse {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return try await request(endpoint: "/foods/search?q=\(encoded)&limit=30")
    }

    func createCustomFood(
        name: String, calories: Double, protein: Double, carbs: Double, fat: Double,
        servingDescription: String? = nil
    ) async throws {
        let body: [String: Any] = [
            "name": name, "calories": calories, "protein": protein,
            "carbs": carbs, "fat": fat,
            "serving_description": servingDescription ?? ""
        ]
        let _: [String: String] = try await request(endpoint: "/foods/custom", method: "POST", body: body)
    }
}
