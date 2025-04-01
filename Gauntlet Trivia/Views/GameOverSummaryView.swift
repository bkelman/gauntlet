import SwiftUI

struct GameOverSummaryView: View {
    let score: Int
    let total: Int
    let results: [PlayerResult]
    let onBack: () -> Void // Add this

    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            GameHeaderView(
                date: formattedDate(),
                score: score,
                onBack: onBack
            )
            .padding(.bottom, 12)
            VStack(spacing: 16) {
                Text("Game Over!")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                Text("Final Score: \(score)/\(total)")
                    .font(.title2)
                    .foregroundColor(.white)

                Text("You beat 82% of players today!")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(results) { result in
                        HStack(spacing: 8) {
                            Image(systemName: result.wasCorrect ? "checkmark.circle.fill" : "xmark.octagon.fill")
                                .foregroundColor(result.wasCorrect ? .green : .red)
                            Text(result.name)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.top)
            }
            .padding()
        }
    }
}
