import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

struct PlayerGuessView: View {
    @State private var currentPlayer: Player?
    @State private var userGuess = ""
    @State private var score = 0
    @State private var lives = 3
    @State private var showFeedback = false
    @State private var feedbackText = ""
    @State private var isGameOver = false
    @State private var allPlayers: [Player] = []
    @State private var currentIndex = 0

    var body: some View {
        ZStack {
            Color.triviaBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                if let player = currentPlayer, !isGameOver {
                    AsyncImage(url: URL(string: player.imageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable()
                                 .scaledToFit()
                                 .frame(height: 300)
                        case .failure(_):
                            Text("⚠️ Failed to load image")
                        case .empty:
                            ProgressView()
                        @unknown default:
                            EmptyView()
                        }
                    }

                    TextField("Who is this player?", text: $userGuess)
                        .padding()
                        .background(Color(.systemGray6).opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .autocapitalization(.words)

                    Button("Submit Guess") {
                        checkGuess()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.triviaButton)
                    .foregroundColor(.white)
                    .cornerRadius(12)

                    Text("Lives: \(lives) | Score: \(score)")
                        .foregroundColor(.white)

                    if showFeedback {
                        Text(feedbackText)
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                } else if isGameOver {
                    Text("Game Over! Final Score: \(score)")
                        .font(.title)
                        .foregroundColor(.white)
                } else {
                    ProgressView()
                }
            }
            .padding()
            .frame(maxWidth: 400)
        }
        .onAppear {
            loadAllPlayers()
        }
    }

    func loadAllPlayers() {
        let db = Firestore.firestore()
        db.collection("NFLplayers")
            .order(by: "difficulty", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error loading players: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("⚠️ No players found")
                    return
                }

                self.allPlayers = documents.compactMap { try? $0.data(as: Player.self) }
                self.currentIndex = 0
                self.currentPlayer = self.allPlayers.first
            }
    }
    
    func loadNextPlayer() {
        userGuess = ""
        currentIndex += 1

        if currentIndex < allPlayers.count {
            currentPlayer = allPlayers[currentIndex]
        } else {
            isGameOver = true
        }
    }

    func checkGuess() {
        guard let player = currentPlayer else { return }

        let normalizedGuess = userGuess.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedAnswer = player.name.lowercased()

        if normalizedGuess == normalizedAnswer {
            score += 1
            feedbackText = "✅ Correct!"
        } else {
            lives -= 1
            feedbackText = "❌ Wrong! That was \(player.name)"
        }

        showFeedback = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showFeedback = false

            if lives == 0 {
                isGameOver = true
            } else {
                loadNextPlayer()
            }
        }
    }
}
