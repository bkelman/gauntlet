import SwiftUI

struct GameHeaderView: View {
    let date: String
    let score: Int
    var onBack: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Back arrow
            if let onBack = onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .padding(.trailing, 0)
                }
                .buttonStyle(.plain)
            }

            // Wordmark and date
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Text("GAUNTLET")
                        .foregroundColor(Color.primaryColor)
                        .font(.headline.bold())
                    Text("TRIVIA")
                        .foregroundColor(Color.secondaryColor)
                        .font(.headline.bold())
                }
                Text(date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Score
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundStyle(LinearGradient(
                        colors: [Color.primaryColor, .yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .shadow(color: .yellow.opacity(0.6), radius: 4, x: 0, y: 2)
                Text("\(score)")
                    .font(.subheadline.bold())
                    .foregroundStyle(LinearGradient(
                        colors: [Color.primaryColor, .yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .shadow(color: .yellow.opacity(0.6), radius: 2, x: 0, y: 1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 2)
        .padding(.bottom, 6)
    }
}
