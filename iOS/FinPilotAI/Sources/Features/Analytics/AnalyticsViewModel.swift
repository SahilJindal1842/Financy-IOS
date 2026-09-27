import SwiftUI

@MainActor
final class AnalyticsViewModel: ObservableObject {
    @Published var data: [Double] = [10, 20, 15, 30, 25, 40, 35]
}
