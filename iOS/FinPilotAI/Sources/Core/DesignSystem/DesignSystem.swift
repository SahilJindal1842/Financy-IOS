import SwiftUI

// MARK: - Network Configuration
enum NetworkConfig {
    #if targetEnvironment(simulator)
    static let baseURLString = "http://127.0.0.1:3000/api"
    #else
    static let baseURLString = "http://192.168.1.4:3000/api"
    #endif
    
    static var baseURL: URL {
        return URL(string: baseURLString)!
    }
    
    static var authBaseURL: String {
        return "\(baseURLString)/auth"
    }
}

// MARK: - App Notifications
extension Notification.Name {
    static let transactionUpdated = Notification.Name("FinPilotTransactionUpdated")
    static let userLoggedOut = Notification.Name("FinPilotUserLoggedOut")
}

// MARK: - App JSON Decoder
extension JSONDecoder {
    static var appDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { d in
            let container = try d.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            let isoWithFraction = ISO8601DateFormatter()
            isoWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoWithFraction.date(from: dateStr) {
                return date
            }
            
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: dateStr) {
                return date
            }
            
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = TimeZone(secondsFromGMT: 0)
            
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd'T'HH:mm:ss",
                "yyyy-MM-dd"
            ]
            for format in formats {
                df.dateFormat = format
                if let date = df.date(from: dateStr) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateStr)")
        }
        return decoder
    }
}

enum FinPilotColors {
    // Primary green brand color
    static let primary = Color(hex: "#0F9D58")
    static let primaryLight = Color(hex: "#5cb85c")
    static let primaryDark = Color(hex: "#0B7A44")
    
    // Backgrounds
    static let background = Color(hex: "#F8F9FA")
    static let surface = Color.white
    static let secondary = Color.gray
    
    // Text
    static let textPrimary = Color.black
    static let textSecondary = Color.gray
    
    // Status
    static let success = Color(hex: "#0F9D58")
    static let error = Color(hex: "#EA4335")
    static let warning = Color(hex: "#FBBC05")
    static let critical = Color(hex: "#FD7E14")
    
    // Custom Gradients
    static let budgetCardGradient = LinearGradient(
        gradient: Gradient(colors: [primaryLight, primary]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum FinPilotTypography {
    static let largeTitle = Font.system(.largeTitle, design: .rounded).bold()
    static let title1 = Font.system(.title, design: .rounded).bold()
    static let title2 = Font.system(.title2, design: .rounded).bold()
    static let title3 = Font.system(.title3, design: .rounded).weight(.semibold)
    static let headline = Font.system(.headline, design: .rounded).bold()
    static let body = Font.system(.body, design: .rounded)
    static let callout = Font.system(.callout, design: .rounded)
    static let subheadline = Font.system(.subheadline, design: .rounded)
    static let caption = Font.system(.caption, design: .rounded)
}

// Helper for Hex Colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Loading Views & Modifiers
struct AppLoadingView: View {
    var message: String = "Loading..."
    var isFullScreen: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(FinPilotColors.primary.opacity(0.15), lineWidth: 4)
                    .frame(width: 48, height: 48)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: FinPilotColors.primary))
                    .scaleEffect(1.2)
            }
            
            if !message.isEmpty {
                Text(message)
                    .font(FinPilotTypography.subheadline)
                    .foregroundColor(FinPilotColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: isFullScreen ? .infinity : nil)
        .padding(isFullScreen ? 0 : 32)
    }
}

struct LoadingOverlayModifier: ViewModifier {
    let isLoading: Bool
    var message: String = "Loading..."
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
            
            if isLoading {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(FinPilotColors.primary.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "indianrupeesign.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(FinPilotColors.primary)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: FinPilotColors.primary))
                            .scaleEffect(2.0)
                    }
                    .frame(height: 70)
                    
                    if !message.isEmpty {
                        Text(message)
                            .font(FinPilotTypography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(FinPilotColors.textPrimary)
                    }
                }
                .padding(24)
                .background(FinPilotColors.surface)
                .cornerRadius(16)
                .shadow(color: FinPilotColors.primary.opacity(0.15), radius: 15, x: 0, y: 5)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

extension View {
    func loadingOverlay(isLoading: Bool, message: String = "Loading...") -> some View {
        self.modifier(LoadingOverlayModifier(isLoading: isLoading, message: message))
    }
}

