import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

struct ContentView: View {
    @State private var useImageMode = true
    var body: some View {
        if useImageMode {
            PlayerGuessView()
        } else {
            MultipleChoiceTriviaView()
        }
    }
}

#Preview {
    ContentView()
}

