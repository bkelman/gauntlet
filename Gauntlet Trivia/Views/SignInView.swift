import SwiftUI
import FirebaseAuth

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isSignedIn = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Gauntlet Trivia")
                .font(.largeTitle)
                .bold()

            TextField("Email", text: $email)
                .autocapitalization(.none)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            Button("Sign In / Register") {
                signInOrRegister()
            }
            .padding()
            .background(Color.blue.opacity(0.7))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .fullScreenCover(isPresented: $isSignedIn) {
            ContentView() // show main game screen once signed in
        }
    }

    func signInOrRegister() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if result != nil {
                self.isSignedIn = true
            } else {
                // Sign-in failed – try registering instead
                Auth.auth().createUser(withEmail: email, password: password) { result, error in
                    if result != nil {
                        self.isSignedIn = true
                    } else {
                        self.errorMessage = "Auth failed: \(error?.localizedDescription ?? "Unknown error")"
                    }
                }
            }
        }
    }

}
