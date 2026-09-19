import Foundation

struct SectionSpec: Codable, Hashable, Identifiable {
    let key: String
    let title: String
    let icon: String
    let guidance: String

    var id: String { key }
}
