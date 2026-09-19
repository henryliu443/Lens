import Foundation

struct Analysis: Codable, Identifiable {
    var id = UUID()
    let lensID: String
    let sections: [String: String]
    let createdAt: Date
}
