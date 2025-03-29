import SwiftUI
import FirebaseAuth

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isSignedIn = false

    var body: some View {
        
        ZStack {
            Color.triviaBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300) // Feel free to adjust
                        .padding(.top, 40)

                    Text("Gauntlet Trivia")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color.triviaText)

                    VStack(spacing: 12) {
                        TextField("Email", text: $email)
                            .padding()
                            .background(Color(.systemGray6).opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(10)

                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color(.systemGray6).opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    if let message = errorMessage, !message.isEmpty {
                        Text(message)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }

                    Button(action: signInOrRegister) {
                        Text("Sign In / Register")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                }
                .padding()
                .frame(maxWidth: 400) // Prevent overly wide fields on iPad/simulator
                .padding(.bottom, 40)
            }
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
