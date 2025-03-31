import SwiftUI

struct GameOverSummaryView: View {
    let score: Int
    let total: Int
    let results: [PlayerResult]

    var body: some View {
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
