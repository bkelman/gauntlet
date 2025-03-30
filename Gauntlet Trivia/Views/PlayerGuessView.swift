import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

struct PlayerName: Identifiable {
    var id = UUID()
    var name: String
    var seasons: Int
}

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
    @State private var allPlayerNames: [PlayerName] = []
    @State private var searchText = ""
    @State private var filteredSuggestions: [String] = []
    @State private var selectedGuess: String? = nil
    @State private var timeRemaining: Double = 15.0 //timer duration (also update in startTimer() and ProgressView
    @State private var timer: Timer?
    @State private var isTimerRunning = false
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        ZStack {
            Color.triviaBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    
                    if isGameOver {
                        VStack(spacing: 16) {
                            Text("Game Over!")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                            
                            Text("Final Score: \(score)")
                                .font(.title2)
                                .foregroundColor(.white) //improve screen later
                        }
                    } else {
                        // 🔼 Lives + Score
                        HStack(alignment: .top) {
                            // ⬅️ Left Side: Wordmark + Date
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Gauntlet Trivia")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text(formattedDate())
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            // ➡️ Right Side: Lives + Score
                            VStack(alignment: .trailing, spacing: 8) {
                                // ❤️ Lives (video game style)
                                HStack(spacing: 4) {
                                    ForEach(0..<3, id: \.self) { index in
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(index < lives ? .red : .gray)
                                            .shadow(radius: index < lives ? 2 : 0)
                                    }
                                }

                                // ⭐ Score
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .shadow(radius: 2)
                                    Text("Score: \(score)")
                                }
                                .foregroundColor(Color.yellow)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // 🕓 Progress bar
                        ProgressView(value: min(max(timeRemaining, 0), 15), total: 15)
                            .progressViewStyle(LinearProgressViewStyle())
                            .accentColor(Color.triviaButton)
                            .scaleEffect(x: 1, y: 2)
                            .padding(.horizontal)
                        
                        // 🖼️ Image
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
                                    .frame(height: 250) // 🖼 Controls the whole block's size

                                case .failure(_):
                                    Text("⚠️ Image failed to load")

                                case .empty:
                                    ProgressView()

                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }

                        
                        // 🔍 Search field + suggestions
                        VStack(alignment: .leading, spacing: 0) {
                            TextField("Search for player...", text: $searchText)
                                .padding()
                                .background(Color(.systemGray6).opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .focused($isSearchFieldFocused)
                                .autocorrectionDisabled(true)
                                .textInputAutocapitalization(.never)
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
                            
                            ForEach(filteredSuggestions, id: \.self) { name in
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
                        
                        /* 🟧 Submit button (removed because we're auto-submitting, and it's broken anyway)
                         if selectedGuess != nil {
                         Button("Submit Guess") {
                         checkGuess()
                         }
                         .padding()
                         .frame(maxWidth: .infinity)
                         .background(Color.triviaButton)
                         .foregroundColor(.white)
                         .cornerRadius(10)
                         }*/
                        
                    }
                }
                            .padding()
                            .frame(maxWidth: 400)
                }
            .ignoresSafeArea(.keyboard, edges: .bottom)

        .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .onAppear {
            loadAllPlayers()
            loadAllPlayerNames()
        }
    }

    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
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
                startTimer() // start the timer for the first player
            }
    }
    
    func loadAllPlayerNames() {
        let db = Firestore.firestore()
        db.collection("playerNames").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error loading player names: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("⚠️ No player names found")
                return
            }

            self.allPlayerNames = documents.compactMap { doc in
                guard let name = doc["name"] as? String else { return nil }
                let seasons = doc["seasons"] as? Int ?? 0
                return PlayerName(name: name, seasons: seasons)
            }

            print("✅ Loaded \(self.allPlayerNames.count) player names")
        }
    }

    
    func loadNextPlayer() {
        userGuess = ""
        searchText = ""
        selectedGuess = nil
        filteredSuggestions = []
        currentIndex += 1
        isSearchFieldFocused = true
        if currentIndex < allPlayers.count {
                currentPlayer = allPlayers[currentIndex]
                startTimer()
            } else {
                isGameOver = true
                timer?.invalidate()
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
        
        if isCorrect {
            score += 1
            feedbackText = "✅ Correct!"
        } else {
            lives -= 1
            feedbackText = "❌ Wrong! That was \(player.name)"
        }

        withAnimation {
            showFeedback = true
        }

        timer?.invalidate() // Stop the timer on manual submission
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                showFeedback = false
            }

            // Add a short delay before switching players so the fade-out completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if lives == 0 || currentIndex + 1 >= allPlayers.count {
                    isGameOver = true
                    timer?.invalidate()
                    return
                } else {
                    loadNextPlayer()
                }
            }
        }

    }
    
    func startTimer() {
        timeRemaining = 15.0
        isTimerRunning = true

        timer?.invalidate() // stop any previous timer

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
        
        lives -= 1
        feedbackText = "⏰ Time’s up! That was \(player.name)"
        showFeedback = true
        
        if lives == 0 || currentIndex + 1 >= allPlayers.count {
            isGameOver = true
            timer?.invalidate()
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                showFeedback = false
            }
            
            // Add a short delay before switching players so the fade-out completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if lives == 0 || currentIndex + 1 >= allPlayers.count {
                    isGameOver = true
                    timer?.invalidate()
                    return
                } else {
                    loadNextPlayer()
                }
            }
        }

    }


}

#Preview {
    PlayerGuessView()
}

