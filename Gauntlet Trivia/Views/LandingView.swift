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

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.triviaBackground.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                } else {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                Text("GAUNTLET")
                                    .foregroundColor(Color.primaryColor)
                                    .font(.largeTitle.bold())
                                Text(" TRIVIA")
                                    .foregroundColor(Color.secondaryColor)
                                    .font(.largeTitle.bold())
                            }

                            Text("Identify the NFL player in each image")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                                .padding(.top, 4)
                        }

                        if hasPlayedToday, let score = todayScore {
                            VStack(spacing: 8) {
                                Text("You’ve already played today!")
                                    .foregroundColor(.white)
                                    .font(.title2)

                                Text("Score: \(score)/\(guessResults.count)")
                                    .foregroundColor(Color.primaryColor)
                                    .font(.title.bold())
                            }
                        } else {
                            Button("Play Today’s Gauntlet") {
                                navigateToGame = true
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        // TODO: Add stats / leaderboard buttons here in future
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationDestination(isPresented: $navigateToGame) {
                PlayerGuessView()
            }
        }
        .onAppear {
            checkIfPlayedToday()
        }
    }

    func checkIfPlayedToday() {
        guard let user = Auth.auth().currentUser else {
            self.isLoading = false
            return
        }

        let db = Firestore.firestore()
        let today = dateFormatter.string(from: Date())

        db.collection("gameResults")
            .document(user.uid)
            .collection("daily")
            .document(today)
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
    PlayerGuessView()
}
