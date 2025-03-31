import SwiftUI

struct PlayerImageView: View {
    let imageURL: String
    let feedbackText: String
    let showFeedback: Bool

    var body: some View {
        AsyncImage(url: URL(string: imageURL)) { phase in
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
}
