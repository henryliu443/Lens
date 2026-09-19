import Foundation

enum AnalysisDepth: String, CaseIterable, Codable, Identifiable {
    case quick
    case balanced
    case deep

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .quick: return "快速"
        case .balanced: return "平衡"
        case .deep: return "深度"
        }
    }

    var detail: String {
        switch self {
        case .quick: return "每段 1-2 句，快速抓住重点"
        case .balanced: return "每段 2-3 句，兼顾速度与深度"
        case .deep: return "每段 3-5 句，可举例展开"
        }
    }
}

enum ResponseTone: String, CaseIterable, Codable, Identifiable {
    case brief
    case coach
    case warm

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .brief: return "简洁"
        case .coach: return "教练"
        case .warm: return "温暖"
        }
    }

    var detail: String {
        switch self {
        case .brief: return "直接、专业"
        case .coach: return "引导式提问"
        case .warm: return "先共情，再给视角"
        }
    }
}
