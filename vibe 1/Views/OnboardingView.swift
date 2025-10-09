import SwiftUI
import FirebaseAuth

struct OnboardingView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var isSignUp = true
    @State private var errorText: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 18) {
                Text(isSignUp ? "Create Account" : "Welcome Back")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 24)

                if isSignUp {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }

                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .keyboardType(.emailAddress)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                SecureField("Password", text: $password)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                if let errorText {
                    Text(errorText)
                        .foregroundColor(.red)
                        .font(.system(size: 13))
                }

                Button(isSignUp ? "Create Account" : "Sign In") {
                    Task { await submit() }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(12)

                Button(isSignUp ? "Already have an account? Sign in" : "Need an account? Create one") {
                    isSignUp.toggle()
                    errorText = nil
                }
                .font(.system(size: 14, weight: .semibold))
                .padding(.top, 4)

                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationBarHidden(true)
        }
    }

    private func submit() async {
        errorText = nil
        do {
            if isSignUp {
                try await AuthService().signUp(email: email, password: password, username: username)
            } else {
                try await AuthService().signIn(email: email, password: password)
            }
        } catch {
            errorText = error.localizedDescription
        }
    }
}

#Preview { OnboardingView() }



