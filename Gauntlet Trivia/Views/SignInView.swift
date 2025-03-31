import SwiftUI
import FirebaseAuth

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isSignedIn = false
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password
    }

    var body: some View {
        ZStack {
            Color.triviaBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    // 🔤 Styled wordmark like header
                    VStack(spacing: 4) {
                        HStack(spacing: 0) {
                            Text("GAUNTLET")
                                .foregroundColor(Color.primaryColor)
                                .font(.largeTitle.bold())
                            Text(" TRIVIA")
                                .foregroundColor(Color.secondaryColor)
                                .font(.largeTitle.bold())
                        }
                        .multilineTextAlignment(.center)

                        Text("Sign in to play today’s game")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    VStack(spacing: 14) {
                        TextField("Email", text: $email)
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.primaryColor.opacity(0.6))
                            )
                            .cornerRadius(8)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .email)

                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.primaryColor.opacity(0.6))
                            )
                            .cornerRadius(8)
                            .focused($focusedField, equals: .password)

                        Button(action: signInOrRegister) {
                            Text("Sign In / Register")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.primaryColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                        }
                    }

                    Spacer(minLength: 20) // Keeps button visible above keyboard
                }
                .padding()
                .frame(maxWidth: 400)
            }
            .onTapGesture {
                focusedField = nil
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .fullScreenCover(isPresented: $isSignedIn) {
            ContentView()
        }
    }

    func signInOrRegister() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if result != nil {
                self.isSignedIn = true
            } else {
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
