import SwiftUI

struct ContentView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoggedIn = false

    var body: some View {
        NavigationStack {
            if isLoggedIn {
                Text("Welcome!")
                    .accessibilityIdentifier("welcome_label")
            } else {
                VStack(spacing: 20) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                        .accessibilityIdentifier("email")

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                        .accessibilityIdentifier("password")

                    Button("Log In") {
                        isLoggedIn = !email.isEmpty && !password.isEmpty
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("login")
                }
                .padding()
                .navigationTitle("Sign In")
            }
        }
    }
}
