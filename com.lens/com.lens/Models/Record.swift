import Foundation
import SwiftData

@Model
final class Record {
    var id: UUID
    var inputText: String
    var lensID: String
    var sectionsData: Data
    var providerName: String
    var modelName: String
    var isFavorite: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        inputText: String,
        lensID: String,
        sections: [String: String],
        providerName: String = "",
        modelName: String = "",
        isFavorite: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.inputText = inputText
        self.lensID = lensID
        self.sectionsData = (try? JSONEncoder().encode(sections)) ?? Data()
        self.providerName = providerName
        self.modelName = modelName
        self.isFavorite = isFavorite
        self.createdAt = createdAt
    }

    var lens: AnalysisLens {
        AnalysisLens.lens(for: lensID)
    }

    var sections: [String: String] {
        (try? JSONDecoder().decode([String: String].self, from: sectionsData)) ?? [:]
    }
}
