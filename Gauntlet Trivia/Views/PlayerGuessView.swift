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
                    VStack(alignment: .leading, spacing: 0) {
                        TextField("Search for player...", text: $searchText)
                            .padding()
                            .background(Color(.systemGray6).opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($isSearchFieldFocused)
                            .onChange(of: searchText) {
                                if searchText.count >= 3 { //number of characters required for suggested search to appear
                                    filteredSuggestions = allPlayerNames
                                        .filter { $0.name.lowercased().contains(searchText.lowercased()) }
                                        .sorted { $0.seasons > $1.seasons }
                                        .prefix(5)
                                        .map { $0.name }
                                } else {
                                    filteredSuggestions = []
                                }
                            }


                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(filteredSuggestions, id: \.self) { name in
                                    Button(action: {
                                        selectedGuess = name
                                        searchText = name
                                        filteredSuggestions = []
                                        checkGuess()
                                    }) {
                                        Text(name)
                                            .foregroundColor(.white)
                                            .padding(.vertical, 4)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }
                        }
                        .frame(height: 120)
                        .background(Color(.systemGray6).opacity(0.2))
                        .cornerRadius(10)
                    }

                    Button("Submit Guess") {
                        checkGuess()
                    }
                    .disabled(selectedGuess == nil)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedGuess == nil ? Color.gray : Color.triviaButton)
                    .foregroundColor(.white)
                    .cornerRadius(12)

                    Text("Lives: \(lives) | Score: \(score)")
                        .foregroundColor(.white)
                    
                    ProgressView(value: min(max(timeRemaining, 0), 15), total: 15)
                        .progressViewStyle(LinearProgressViewStyle())
                        .accentColor(Color.triviaButton)
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .padding(.horizontal)

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
        .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .onAppear {
            loadAllPlayers()
            loadAllPlayerNames()
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
        } else {
            isGameOver = true
        }
        startTimer()
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

        showFeedback = true

        timer?.invalidate() // Stop the timer on manual submission
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showFeedback = false

            if lives == 0 {
                isGameOver = true
                timer?.invalidate()
            }
            else {
                loadNextPlayer()
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

        if lives == 0 {
            isGameOver = true
            timer?.invalidate()
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showFeedback = false
            loadNextPlayer()
        }
    }


}
