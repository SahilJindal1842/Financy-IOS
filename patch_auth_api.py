with open("iOS/FinPilotAI/Sources/Features/Auth/AuthViewModel.swift", "r") as f:
    content = f.read()

old_func = """    func login() async {
        isLoading = true
        error = nil
        
        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 1_000_000_000)
            try KeychainManager.shared.save(token: "dummy_token", for: "user_token")
            isAuthenticated = true
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }"""

new_func = """    func login(email: String, password: String) async {
        isLoading = true
        error = nil
        
        do {
            // 1. Prepare Request
            let url = URL(string: "http://192.168.1.9:3000/api/auth/login")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let payload: [String: String] = [
                "email": email,
                "password": password
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            // 2. Perform Request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            // 3. Parse Response
            if httpResponse.statusCode == 200 {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["token"] as? String {
                    try KeychainManager.shared.save(token: token, for: "user_token")
                    isAuthenticated = true
                } else {
                    self.error = "Invalid response format from server."
                }
            } else {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = json["message"] as? String {
                    self.error = message
                } else {
                    self.error = "Invalid email or password."
                }
            }
            
        } catch {
            self.error = "Network Error: \\(error.localizedDescription)"
        }
        
        isLoading = false
    }"""

content = content.replace(old_func, new_func)

with open("iOS/FinPilotAI/Sources/Features/Auth/AuthViewModel.swift", "w") as f:
    f.write(content)
