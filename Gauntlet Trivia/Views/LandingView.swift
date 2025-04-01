import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct LandingView: View {
    @State private var hasPlayedToday = false
    @State private var isLoading = true
    @State private var navigateToGame = false
    @State private var todayScore: Int? = nil
    @State private var guessResults: [PlayerResult] = []
    @State private var today: String = ""

    var formattedToday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d'\(daySuffix(for: Date()))', yyyy"
        return formatter.string(from: Date())
    }

    func daySuffix(for date: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        switch day {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.triviaBackground.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                } else {
                    VStack(spacing: 48) {
                        Spacer()

                        VStack(spacing: 12) {
                            HStack(spacing: 0) {
                                Text("GAUNTLET")
                                    .foregroundColor(Color.primaryColor)
                                    .font(.largeTitle.bold())
                                Text(" TRIVIA")
                                    .foregroundColor(Color.secondaryColor)
                                    .font(.largeTitle.bold())
                            }

                            Text("Try to name 10 NFL players based on their image.")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }

                        VStack(spacing: 20) {
                            if hasPlayedToday {
                                NavigationLink(destination: GameOverSummaryView(score: todayScore ?? 0, total: guessResults.count, results: guessResults, onBack: { navigateToGame = false })) {
                                    VStack {
                                        Text("View Today’s Score")
                                            .font(.title3.bold())
                                            .padding(.bottom, 2)
                                        Text("Score: \(todayScore ?? 0)/\(guessResults.count)")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.primaryColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            } else {
                                Button(action: {
                                    navigateToGame = true
                                }) {
                                    VStack {
                                        Text("Play")
                                            .font(.title3.bold())
                                            .padding(.bottom, 2)
                                        Text(today)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.primaryColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }

                            Button(action: {
                                // Stats action placeholder
                            }) {
                                Text("My Stats")
                                    .font(.title3.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.secondaryColor.opacity(0.2))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .disabled(true)
                            .opacity(0.3)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: 400)
                    .padding(.horizontal)
                    .padding(.bottom, 60)
                }
            }
            .navigationDestination(isPresented: $navigateToGame) {
                DailyGameView()
            }
            .navigationDestination(isPresented: .constant(false)) {
                GameOverSummaryView(score: todayScore ?? 0, total: guessResults.count, results: guessResults, onBack: {})
            }
        }
        .onAppear {
            today = formattedToday
            checkIfPlayedToday()
        }
    }

    func checkIfPlayedToday() {
        guard let user = Auth.auth().currentUser else {
            self.isLoading = false
            return
        }

        let db = Firestore.firestore()
        let todayDate = formattedToday

        db.collection("gameResults")
            .document(user.uid)
            .collection("daily")
            .document(todayDate)
            .getDocument { snapshot, error in
                self.isLoading = false

                if let data = snapshot?.data() {
                    self.hasPlayedToday = true
                    self.todayScore = data["score"] as? Int
                    if let results = data["results"] as? [[String: Any]] {
                        self.guessResults = results.compactMap { dict in
                            guard let name = dict["name"] as? String,
                                  let wasCorrect = dict["wasCorrect"] as? Bool else { return nil }
                            return PlayerResult(name: name, wasCorrect: wasCorrect)
                        }
                    }
                } else {
                    self.hasPlayedToday = false
                }
            }
    }
}
#Preview {
    DailyGameView()
}
