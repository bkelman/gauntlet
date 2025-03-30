import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

struct ContentView: View {
    @State private var useImageMode = false
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

