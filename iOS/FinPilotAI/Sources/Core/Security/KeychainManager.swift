import Foundation

final class KeychainManager {
    static let shared = KeychainManager()
    private init() {}
    
    func save(token: String, for account: String) throws {
        UserDefaults.standard.set(token, forKey: "mock_keychain_\(account)")
    }
    
    func getToken(for account: String) throws -> String? {
        return UserDefaults.standard.string(forKey: "mock_keychain_\(account)")
    }
    
    func deleteToken(for account: String) throws {
        UserDefaults.standard.removeObject(forKey: "mock_keychain_\(account)")
    }
}
