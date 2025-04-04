import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

struct TriviaQuestion: Codable, Identifiable {
    var id: UUID = UUID() // Generate locally, not from Firestore
    var text: String
    var options: [String]
    var correctAnswer: String
    private enum CodingKeys: String, CodingKey {
        case text, options, correctAnswer
    }
}

struct Question {
    let text: String
    let options: [String]
    let correctAnswer: String
}

struct MultipleChoiceTriviaView: View {
    @State private var questions: [TriviaQuestion] = []
    @State private var currentQuestionIndex = 0
    @State private var loading = true
    @State private var lives = 3
    @State private var score = 0
    @State private var showFeedback = false
    @State private var feedbackText = ""
    @State private var gameLocked = false
    @State private var selectedOption: String? = nil    
    
    var body: some View {
        ZStack {
            Color.triviaBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("🏆 Gauntlet Trivia")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(Color.triviaText)
                    HStack {
                        Label("Lives: \(lives)", systemImage: "heart.fill")
                            .foregroundColor(.red)
                        Spacer()
                        Label("Score: \(score)", systemImage: "bolt.fill")
                            .foregroundColor(.yellow)
                    }
                    .font(.headline)
                    .padding(.horizontal)
                }
                .padding(.top)
                
                
                Spacer()
                
                if loading {
                    ProgressView("Loading Trivia...")
                } else if gameLocked {
                    VStack(spacing: 16) {
                        Image(systemName: "lock.shield.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.gray)
                        
                        Text("You've already played today.\nCome back tomorrow!")
                            .multilineTextAlignment(.center)
                            .font(.title2)
                            .padding()
                            .foregroundColor(Color.triviaText)
                    }
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .padding()
                } else if lives > 0 && currentQuestionIndex < questions.count {
                    let current = questions[currentQuestionIndex]
                    
                    Text(current.text)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.triviaText)
                        .padding()
                    
                    ForEach(current.options, id: \.self) { option in
                        Button(action: {
                            withAnimation(.easeIn(duration: 0.2)) {
                                handleAnswer(option)
                            }
                        }) {
                            Text(option)
                                .font(.headline)
                                .foregroundColor(
                                    selectedOption == option
                                        ? (option == questions[currentQuestionIndex].correctAnswer ? Color.triviaCorrect : Color.triviaWrong)
                                        : Color.triviaText
                                )
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.triviaButton)
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "flag.checkered")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.red)
                        
                        Text("Game Over! Final Score: \(score)")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
                
                
                ZStack {
                    if showFeedback {
                        Text(feedbackText)
                            .font(.title2)
                            .bold()
                            .foregroundColor(feedbackText.contains("✅") ? .green : .red)
                            .transition(.opacity)
                    } else {
                        // Reserve space so layout doesn't jump
                        Text(" ")
                            .font(.title2)
                            .bold()
                            .hidden()
                            .frame(height: 28)
                    }
                }
                .animation(.easeInOut, value: showFeedback)
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            if Auth.auth().currentUser != nil {
                print("✅ Signed in as \(Auth.auth().currentUser?.email ?? "unknown user")")
                checkDailyStatus()
            } else {
                print("❌ Not signed in — should never hit this if using SignInView properly")
            }
        }
    }
    func checkDailyStatus() {
        guard let user = Auth.auth().currentUser else { return }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)

        userRef.getDocument { docSnapshot, error in
            if let data = docSnapshot?.data(),
               let lastPlayed = data["lastPlayedDate"] as? String {
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd"
                let today = formatter.string(from: Date())

                if lastPlayed == today {
                    gameLocked = true
                    loading = false
                } else {
                    loadTriviaForToday()
                }
            } else {
                // No user doc yet — treat as new player
                loadTriviaForToday()
            }
        }
    }

    
    func loadTriviaForToday() {
        let db = Firestore.firestore()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayKey = dateFormatter.string(from: Date())

        db.collection("dailyTrivia").document(todayKey).getDocument { snapshot, error in
            if let error = error {
                print("❌ Error loading trivia: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data() else {
                print("⚠️ No questions found in document.")
                return
            }

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let decoded = try JSONDecoder().decode([TriviaQuestion].self, from: jsonData)
                self.questions = decoded
                self.currentQuestionIndex = 0
            } catch {
                print("❌ Failed to decode questions: \(error)")
            }
        }
    }


    
    
    // MARK: - Answer Logic
    func handleAnswer(_ selected: String) {
        
        selectedOption = selected

        guard lives > 0, currentQuestionIndex < questions.count else { return }

        let current = questions[currentQuestionIndex]
        if selected == current.correctAnswer {
            score += 1
            feedbackText = "✅ Correct!"
        } else {
            lives -= 1
            feedbackText = "❌ Wrong! Correct: \(current.correctAnswer)"
        }
        if lives == 0 || currentQuestionIndex >= questions.count {
            markPlayedToday()
            gameLocked = true
        }

        showFeedback = true

        // Move to next question after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showFeedback = false
            currentQuestionIndex += 1

            if lives == 0 || currentQuestionIndex >= questions.count {
                markPlayedToday()
                gameLocked = true
            }
            selectedOption = nil
        }
    }
    
    func markPlayedToday() {
        guard let user = Auth.auth().currentUser else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let today = formatter.string(from: Date())

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)

        userRef.setData(["lastPlayedDate": today], merge: true)
    }


}

#Preview {
    MultipleChoiceTriviaView()
}
