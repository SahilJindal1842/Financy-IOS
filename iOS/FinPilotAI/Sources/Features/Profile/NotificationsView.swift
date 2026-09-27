import SwiftUI

struct NotificationItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let date: Date
    let isRead: Bool
}

struct NotificationsView: View {
    @State private var notifications: [NotificationItem] = [
        NotificationItem(title: "Budget Exceeded", message: "You have exceeded your dining out budget by $20.", date: Date().addingTimeInterval(-3600), isRead: false),
        NotificationItem(title: "New Insight Available", message: "Check out your personalized saving tip for this week.", date: Date().addingTimeInterval(-86400), isRead: true),
        NotificationItem(title: "Salary Received", message: "Your salary of $4,000 has been credited to your account.", date: Date().addingTimeInterval(-172800), isRead: true)
    ]
    
    var body: some View {
        List {
            ForEach(notifications) { notification in
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
                        
                        Text(timeAgo(from: notification.date))
                            .font(FinPilotTypography.caption)
                            .foregroundColor(FinPilotColors.textSecondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
