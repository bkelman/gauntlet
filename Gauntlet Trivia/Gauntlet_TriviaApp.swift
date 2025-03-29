//
//  Gauntlet_TriviaApp.swift
//  Gauntlet Trivia
//
//  Created by Ben Kelman on 3/28/25.
//

import SwiftUI
import Firebase

@main
struct Gauntlet_TriviaApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
