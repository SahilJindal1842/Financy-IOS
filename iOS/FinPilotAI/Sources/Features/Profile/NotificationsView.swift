import SwiftUI

struct AppNotification: Codable, Identifiable {
    let id: String
    let userId: String
    let title: String
    let message: String
    let type: String
    let isRead: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case message
        case type
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false
    @Published var error: String?
    
    func fetchNotifications() async {
        isLoading = true
        do {
            let fetched: [AppNotification] = try await APIManager.shared.request(endpoint: "/notifications")
            self.notifications = fetched
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    func markAsRead(id: String) async {
        do {
            struct EmptyResponse: Codable {}
            let _: EmptyResponse = try await APIManager.shared.request(endpoint: "/notifications/\(id)/read", method: "PATCH")
            if let index = notifications.firstIndex(where: { $0.id == id }) {
                let old = notifications[index]
                notifications[index] = AppNotification(id: old.id, userId: old.userId, title: old.title, message: old.message, type: old.type, isRead: true, createdAt: old.createdAt)
            }
        } catch {
            print("Failed to mark read: \(error)")
        }
    }
    
    func deleteNotification(id: String) async {
        do {
            struct EmptyResponse: Codable {}
            let _: EmptyResponse = try await APIManager.shared.request(endpoint: "/notifications/\(id)", method: "DELETE")
            notifications.removeAll { $0.id == id }
        } catch {
            print("Failed to delete notification: \(error)")
        }
    }
}

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    
    var body: some View {
        List {
            if viewModel.isLoading && viewModel.notifications.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } else if viewModel.notifications.isEmpty {
                Text("No notifications yet.")
                    .foregroundColor(FinPilotColors.textSecondary)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.notifications) { notification in
                    HStack(alignment: .top, spacing: 16) {
                        Circle()
                            .fill(notification.isRead ? Color.clear : FinPilotColors.primary)
                            .frame(width: 10, height: 10)
                            .padding(.top, 6)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(notification.title)
                                .font(FinPilotTypography.headline)
                                .foregroundColor(FinPilotColors.textPrimary)
                            
                            Text(notification.message)
                                .font(FinPilotTypography.body)
                                .foregroundColor(FinPilotColors.textSecondary)
                            
                            Text(timeAgo(from: notification.createdAt))
                                .font(FinPilotTypography.caption)
                                .foregroundColor(FinPilotColors.textSecondary)
                        }
                    }
                    .padding(.vertical, 8)
                    .onAppear {
                        if !notification.isRead {
                            Task {
                                await viewModel.markAsRead(id: notification.id)
                            }
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            Task {
                                await viewModel.deleteNotification(id: notification.id)
                            }
                        } label: {
                            Label("Clear", systemImage: "xmark.circle")
                        }
                        .tint(.gray)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchNotifications()
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
