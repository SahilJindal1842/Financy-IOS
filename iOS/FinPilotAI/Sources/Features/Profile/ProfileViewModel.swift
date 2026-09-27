import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: User?
    
    func loadProfile() {
        self.user = User(id: "1", email: "user@finpilot.ai", name: "John Doe", createdAt: nil, updatedAt: nil)
    }
}
