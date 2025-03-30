import SwiftUI
import FirebaseAuth

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isSignedIn = false
    @State private var showLaunchScreen = true
    @State private var showLoginFields = false
    @State private var logoOffsetY: CGFloat = 0
    @State private var logoAtTop = false

    var body: some View {
  
        ZStack {
            Color.triviaBackground.ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 24) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 350, height: 350)
                        .offset(y: logoOffsetY)

                    if showLoginFields {
                        VStack(spacing: 16) {
                            TextField("Email", text: $email)
                                .padding()
                                .background(Color(.systemGray6).opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)

                            SecureField("Password", text: $password)
                                .padding()
                                .background(Color(.systemGray6).opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(10)

                            Button(action: signInOrRegister) {
                                Text("Sign In / Register")
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.triviaButton)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal)
            .frame(maxWidth: 400)
        }



        .fullScreenCover(isPresented: $isSignedIn) {
            ContentView() // show main game screen once signed in
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    logoOffsetY = -80
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    showLoginFields = true
                }
            }
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
