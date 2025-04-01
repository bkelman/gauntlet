import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

struct PlayerName: Identifiable, Codable {
    var id = UUID()
    var name: String
    var seasons: Int
}

struct PlayerResult: Identifiable {
    let id = UUID()
    let name: String
    let wasCorrect: Bool
}

struct DailyGameView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPlayer: Player?
    @State private var userGuess = ""
    @State private var score = 0
    @State private var showFeedback = false
    @State private var feedbackText = ""
    @State private var isGameOver = false
    @State private var allPlayers: [Player] = []
    @State private var currentIndex = 0
    @State private var allPlayerNames: [PlayerName] = []
    @State private var searchText = ""
    @State private var filteredSuggestions: [String] = []
    @State private var selectedGuess: String? = nil
    @State private var timeRemaining: Double = 15.0
    @State private var timer: Timer?
    @State private var isTimerRunning = false
    @State private var results: [PlayerResult] = []
    @State private var isGuessLocked = false
    @FocusState private var isSearchFieldFocused: Bool

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()

    var body: some View {
        ZStack {
            Color.triviaBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    if isGameOver {
                        GameOverSummaryView(
                            score: score,
                            total: results.count,
                            results: results,
                            onBack: { dismiss() }
                        )
                    }
                    else {
                        GameHeaderView(date: dateFormatter.string(from: Date()), score: score, onBack: {
                            dismiss()
                        })
                        Divider()
                            .background(Color.white.opacity(0.1))

                        if let player = currentPlayer, !isGameOver {
                            PlayerImageView(
                                    imageURL: player.imageURL,
                                    feedbackText: feedbackText,
                                    showFeedback: showFeedback
                                )
                        }

                        ProgressView(value: min(max(timeRemaining, 0), 15), total: 15)
                            .progressViewStyle(LinearProgressViewStyle())
                            .accentColor(Color.primaryColor)
                            .scaleEffect(x: 1, y: 2)
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 4)

                        PlayerSearchView(
                            searchText: $searchText,
                            selectedGuess: $selectedGuess,
                            suggestions: filteredSuggestions,
                            onGuessSelected: { name in
                                searchText = name
                                filteredSuggestions = []
                                checkGuess()
                            }
                        )
                        .focused($isSearchFieldFocused)
                        .onChange(of: searchText) {
                            if searchText.count >= 3 {
                                filteredSuggestions = allPlayerNames
                                    .filter { $0.name.lowercased().contains(searchText.lowercased()) }
                                    .sorted { $0.seasons > $1.seasons }
                                    .prefix(5)
                                    .map { $0.name }
                            } else {
                                filteredSuggestions = []
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: 400)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            loadAllPlayers()
            loadAllPlayerNames()
        }
    }

    func checkGuess() {
        guard let player = currentPlayer else { return }
        guard let selected = selectedGuess else {
            feedbackText = "❌ Please select a player from the list"
            showFeedback = true
            return
        }

        guard !isGuessLocked else { return }
        isGuessLocked = true

        let isCorrect = selected.lowercased() == player.name.lowercased()
        results.append(PlayerResult(name: player.name, wasCorrect: isCorrect))

        if isCorrect {
            score += 1
            feedbackText = "✅ Correct!"
        } else {
            feedbackText = "❌ Wrong! That was \(player.name)"
        }

        withAnimation {
            showFeedback = true
        }

        timer?.invalidate()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                showFeedback = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentIndex += 1
                if currentIndex < allPlayers.count {
                    currentPlayer = allPlayers[currentIndex]
                    searchText = ""
                    selectedGuess = nil
                    filteredSuggestions = []
                    isGuessLocked = false
                    startTimer()
                } else {
                    isGameOver = true
                    saveResultsToFirestore()
                }
            }
        }
    }

    func saveResultsToFirestore() {
        guard let user = Auth.auth().currentUser else {
            print("⚠️ No user logged in.")
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let today = formatter.string(from: Date())
        let db = Firestore.firestore()

        let data: [String: Any] = [
            "score": score,
            "total": results.count,
            "results": results.map { ["name": $0.name, "wasCorrect": $0.wasCorrect] }
        ]

        db.collection("gameResults")
            .document(user.uid)
            .collection("daily")
            .document("\(today)")
            .setData(data) { error in
                if let error = error {
                    print("❌ Failed to save game results: \(error.localizedDescription)")
                } else {
                    print("✅ Game results saved successfully for \(today)")
                }
            }
    }

    
    func startTimer() {
        timeRemaining = 15.0
        isTimerRunning = true

        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeRemaining -= 0.1
            if timeRemaining <= 0 {
                timer?.invalidate()
                handleTimeout()
            }
        }
    }

    func handleTimeout() {
        guard let player = currentPlayer else { return }
        results.append(PlayerResult(name: player.name, wasCorrect: false))
        feedbackText = "⏰ Time’s up! That was \(player.name)"
        showFeedback = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                showFeedback = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentIndex += 1
                if currentIndex < allPlayers.count {
                    currentPlayer = allPlayers[currentIndex]
                    searchText = ""
                    selectedGuess = nil
                    filteredSuggestions = []
                    startTimer()
                } else {
                    isGameOver = true
                }
            }
        }
    }

    func loadAllPlayers() {
        isSearchFieldFocused = true
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
                startTimer()
            }
    }

    func loadAllPlayerNames() {
        let db = Firestore.firestore()
        let cacheKey = "playerNamesCache"
        let timestampKey = "playerNamesTimestamp"
        let now = Date()
        
        // Check if we have a recent cached version
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let timestamp = UserDefaults.standard.object(forKey: timestampKey) as? Date,
           now.timeIntervalSince(timestamp) < 604800, // 604800 seconds = 7 days
           let cached = try? JSONDecoder().decode([PlayerName].self, from: data) {
            self.allPlayerNames = cached
            print("✅ Loaded player names from cache")
            return
        }

        // Otherwise fetch from Firestore
        db.collection("playerNames").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error loading player names: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("⚠️ No player names found")
                return
            }

            let names: [PlayerName] = documents.compactMap { doc in
                guard let name = doc["name"] as? String else { return nil }
                let seasons = doc["seasons"] as? Int ?? 0
                return PlayerName(name: name, seasons: seasons)
            }

            self.allPlayerNames = names
            print("✅ Fetched and cached \(names.count) player names")

            // Save to cache
            if let encoded = try? JSONEncoder().encode(names) {
                UserDefaults.standard.set(encoded, forKey: cacheKey)
                UserDefaults.standard.set(now, forKey: timestampKey)
            }
        }
    }


}

#Preview {
    DailyGameView()
}
