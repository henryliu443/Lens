import Foundation
import SwiftData

@Observable
final class HistoryViewModel {
    var searchText: String = ""
    var favoritesOnly: Bool = false

    func filtered(_ records: [Record]) -> [Record] {
        var result = records

        if favoritesOnly {
            result = result.filter(\.isFavorite)
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter { record in
                record.inputText.lowercased().contains(query)
                    || record.lens.name.lowercased().contains(query)
                    || record.sections.values.contains { $0.lowercased().contains(query) }
            }
        }

        return result.sorted { $0.createdAt > $1.createdAt }
    }

    func grouped(_ records: [Record]) -> [(title: String, records: [Record])] {
        let filtered = filtered(records)
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")

        var groups: [String: [Record]] = [:]
        for record in filtered {
            let title: String
            if calendar.isDateInToday(record.createdAt) {
                title = "今天"
            } else if calendar.isDateInYesterday(record.createdAt) {
                title = "昨天"
            } else {
                formatter.dateFormat = "M月d日"
                title = formatter.string(from: record.createdAt)
            }
            groups[title, default: []].append(record)
        }

        return groups
            .map { (title: $0.key, records: $0.value) }
            .sorted { lhs, rhs in
                guard let lDate = lhs.records.first?.createdAt,
                      let rDate = rhs.records.first?.createdAt else { return false }
                return lDate > rDate
            }
    }

    func weeklyStats(_ records: [Record]) -> (count: Int, favorites: Int) {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let thisWeek = records.filter { $0.createdAt >= weekAgo }
        return (thisWeek.count, thisWeek.filter(\.isFavorite).count)
    }

    func toggleFavorite(_ record: Record, context: ModelContext) {
        record.isFavorite.toggle()
        try? context.save()
    }

    func delete(_ record: Record, context: ModelContext) {
        context.delete(record)
        try? context.save()
    }
}
