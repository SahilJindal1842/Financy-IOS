import SwiftUI
import Charts

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                Chart {
                    ForEach(Array(viewModel.data.enumerated()), id: \.offset) { index, value in
                        BarMark(
                            x: .value("Day", "D\(index + 1)"),
                            y: .value("Amount", value)
                        )
                        .foregroundStyle(FinPilotColors.primary)
                    }
                }
                .frame(height: 300)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Analytics")
        }
    }
}
