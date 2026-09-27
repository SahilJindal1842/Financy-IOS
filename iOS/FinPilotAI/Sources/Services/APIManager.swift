import Foundation

enum APIManagerError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(Int)
}

final class APIManager {
    static let shared = APIManager()
    
    private let baseURL = NetworkConfig.baseURLString
    
    private init() {}
    
    private func getToken() -> String? {
        return UserDefaults.standard.string(forKey: "mock_keychain_user_token")
    }
    
    func request<T: Decodable>(endpoint: String, method: String = "GET", body: Data? = nil) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIManagerError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIManagerError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIManagerError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder.appDecoder
        
        do {
            let result = try decoder.decode(T.self, from: data)
            return result
        } catch {
            throw APIManagerError.decodingError(error)
        }
    }
}
import Foundation

extension APIManagerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .networkError(let e): return "Network error: \\(e.localizedDescription)"
        case .invalidResponse: return "Invalid response from server"
        case .serverError(let code): return "Server returned code: \\(code)"
        case .decodingError(let e): return "Decoding error: \\(String(describing: e))"
        }
    }
}
