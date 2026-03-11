import Foundation
import SwiftUI
import Observation

@Observable
class AuthViewModel {
    var isLoggedIn = false
    var currentUser: APIClient.UserDTO?
    var isLoading = false
    var errorMessage: String?

    init() {
        isLoggedIn = TokenManager.shared.isLoggedIn
    }

    @MainActor
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await APIClient.shared.login(email: email, password: password)
            TokenManager.shared.accessToken = response.accessToken
            TokenManager.shared.refreshToken = response.refreshToken
            currentUser = response.user
            isLoggedIn = true
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    func register(email: String, username: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await APIClient.shared.register(
                email: email, username: username, password: password
            )
            TokenManager.shared.accessToken = response.accessToken
            TokenManager.shared.refreshToken = response.refreshToken
            currentUser = response.user
            isLoggedIn = true
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func logout() {
        TokenManager.shared.clear()
        currentUser = nil
        isLoggedIn = false
    }
}
