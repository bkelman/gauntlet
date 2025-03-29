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

struct ContentView: View {
    @State private var questions: [TriviaQuestion] = []
    @State private var currentQuestionIndex = 0
    @State private var loading = true
    @State private var lives = 3
    @State private var score = 0
    @State private var showFeedback = false
    @State private var feedbackText = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("🏆 Gauntlet Trivia")
                .font(.largeTitle)
                .bold()
                .padding(.top)

            Text("Lives: \(lives)   |   Score: \(score)")
                .font(.subheadline)
                .foregroundColor(.gray)

            Spacer()

            if loading {
                ProgressView("Loading Trivia...")
            } else if lives > 0 && currentQuestionIndex < questions.count {
                let current = questions[currentQuestionIndex]

                Text(current.text)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()

                ForEach(current.options, id: \.self) { option in
                    Button(action: {
                        handleAnswer(option)
                    }) {
                        Text(option)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
            } else {
                Text("Game Over! Final Score: \(score)")
                    .font(.headline)
                    .foregroundColor(.red)
            }

            if showFeedback {
                Text(feedbackText)
                    .font(.headline)
                    .foregroundColor(.orange)
                    .padding(.top)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            if Auth.auth().currentUser == nil {
                Auth.auth().signInAnonymously { result, error in
                    if let error = error {
                        print("❌ Error signing in: \(error.localizedDescription)")
                    } else {
                        print("✅ Signed in anonymously as user ID: \(result?.user.uid ?? "unknown")")
                        loadTriviaForToday()
                    }
                }
            } else {
                loadTriviaForToday()
            }
        }
    }

    func loadTriviaForToday() {
        let db = Firestore.firestore()

        // Format today as YYYYMMDD
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let todayKey = formatter.string(from: Date())

        db.collection("dailyTrivia").document(todayKey).getDocument { docSnapshot, error in
            if let error = error {
                print("❌ Error fetching trivia: \(error.localizedDescription)")
                loading = false
                return
            }

            guard let data = docSnapshot?.data(),
                  let rawQuestions = data["questions"] as? [[String: Any]] else {
                print("❌ No questions found in document.")
                loading = false
                return
            }

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: rawQuestions)
                let decoded = try JSONDecoder().decode([TriviaQuestion].self, from: jsonData)
                self.questions = decoded
                self.loading = false
            } catch {
                print("❌ Failed to decode questions: \(error)")
                loading = false
            }
        }
    }

    
    // MARK: - Answer Logic
    func handleAnswer(_ selected: String) {
        guard lives > 0, currentQuestionIndex < questions.count else { return }

        let current = questions[currentQuestionIndex]
        if selected == current.correctAnswer {
            score += 1
            feedbackText = "✅ Correct!"
        } else {
            lives -= 1
            feedbackText = "❌ Wrong! Correct: \(current.correctAnswer)"
        }

        showFeedback = true

        // Move to next question after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showFeedback = false
            currentQuestionIndex += 1
        }
    }
}

#Preview {
    ContentView()
}
