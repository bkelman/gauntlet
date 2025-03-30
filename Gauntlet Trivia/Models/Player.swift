import Foundation
import FirebaseFirestoreSwift

struct Player: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var imageURL: String
    var difficulty: Int
}
