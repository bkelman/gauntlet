import SwiftUI

struct PlayerSearchView: View {
    @Binding var searchText: String
    @Binding var selectedGuess: String?
    let suggestions: [String]
    let onGuessSelected: (String) -> Void

    var body: some View {
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

            ForEach(suggestions, id: \.self) { name in
                Button(action: {
                    selectedGuess = name
                    onGuessSelected(name)
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
