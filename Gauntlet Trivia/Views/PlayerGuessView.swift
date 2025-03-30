// Updated to remove lives system and add summary result tracking
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

struct PlayerGuessView: View {
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
                        VStack(spacing: 16) {
                            Text("Game Over!")
                                .font(.largeTitle)
                                .foregroundColor(.white)

                            Text("Final Score: \(score)/\(results.count)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.primaryColor, .yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .yellow.opacity(0.6), radius: 4, x: 0, y: 2)

                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(results) { result in
                                    Text(result.name)
                                        .foregroundColor(result.wasCorrect ? .green : .red)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(.top)
                        }
                    } else {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(spacing: 0) {
                                    Text("GAUNTLET")
                                        .foregroundColor(Color.primaryColor)
                                        .font(.headline.bold())
                                    Text(" TRIVIA")
                                        .foregroundColor(Color.secondaryColor)
                                        .font(.headline.bold())
                                }
                                Text(dateFormatter.string(from: Date()))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.top, 1)
                            }

                            Spacer()

                            VStack(spacing: 2) {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(LinearGradient(
                                        colors: [Color.primaryColor, .yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing))
                                        .shadow(color: .yellow.opacity(0.6), radius: 4, x: 0, y: 2)
                                    Text("\(score)")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(LinearGradient(
                                        colors: [Color.primaryColor, .yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing))
                                        .shadow(color: .yellow.opacity(0.6), radius: 2, x: 0, y: 1)
                                    }
                                }
                            }
                        .padding(.horizontal)
                        .padding(.top, 4)

                        Divider()
                            .background(Color.white.opacity(0.1))

                        if let player = currentPlayer, !isGameOver {
                            AsyncImage(url: URL(string: player.imageURL)) { phase in
                                switch phase {
                                case .success(let image):
                                    ZStack(alignment: .bottom) {
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(
                                                        showFeedback
                                                            ? (feedbackText.contains("✅") ? Color.green : Color.red)
                                                            : Color.clear,
                                                        lineWidth: 4
                                                    )
                                            )

                                        if showFeedback {
                                            Text(feedbackText)
                                                .foregroundColor(.white)
                                                .font(.headline)
                                                .padding(6)
                                                .background(
                                                    Capsule()
                                                        .fill(feedbackText.contains("✅") ? Color.green : Color.red)
                                                )
                                                .padding(.bottom, 12)
                                                .transition(.opacity)
                                                .animation(.easeInOut(duration: 0.3), value: showFeedback)
                                        }
                                    }
                                    .frame(maxHeight: 225)
                                case .failure(_):
                                    Text("⚠️ Image failed to load")
                                case .empty:
                                    ProgressView()
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }

                        ProgressView(value: min(max(timeRemaining, 0), 15), total: 15)
                            .progressViewStyle(LinearProgressViewStyle())
                            .accentColor(Color.primaryColor)
                            .scaleEffect(x: 1, y: 2)
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 4)

                        VStack(alignment: .leading, spacing: 0) {
                            TextField("Search for player...", text: $searchText)
                                .padding(10)
                                .background(Color.white.opacity(0.08))
                                .foregroundColor(.white)
                                .autocorrectionDisabled(true)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.default)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.primaryColor.opacity(0.6), lineWidth: 1)
                                )
                                .cornerRadius(8)
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

                            ForEach(filteredSuggestions, id: \ .self) { name in
                                Button(action: {
                                    selectedGuess = name
                                    searchText = name
                                    filteredSuggestions = []
                                    checkGuess()
                                }) {
                                    Text(name)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: 400)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
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

        let today = dateFormatter.string(from: Date())
        let db = Firestore.firestore()

        let data: [String: Any] = [
            "score": score,
            "total": results.count,
            "results": results.map { ["name": $0.name, "wasCorrect": $0.wasCorrect] }
        ]

        db.collection("gameResults")
            .document(user.uid)
            .collection("daily")
            .document(today)
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
           now.timeIntervalSince(timestamp) < 86400, // 86400 seconds = 24 hours
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
    PlayerGuessView()
}
