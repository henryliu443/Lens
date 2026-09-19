import Foundation

struct AnalysisLens: Identifiable, Hashable {
    let id: String
    let name: String
    let shortLabel: String
    let icon: String
    let systemRole: String
    let sections: [SectionSpec]
    let keywords: [String]
}

extension AnalysisLens {
    static let decisionReview = AnalysisLens(
        id: "decision-review",
        name: "决策复盘",
        shortLabel: "决策",
        icon: "signpost.right.and.left",
        systemRole: "你是一位冷静、结构化的决策分析助手。你不替用户做决定，而是帮他把这个决定本身看清楚。",
        sections: [
            SectionSpec(
                key: "key_considerations",
                title: "关键考量",
                icon: "list.bullet.clipboard",
                guidance: "这个决定真正相关的因素有哪些"
            ),
            SectionSpec(
                key: "blind_spots",
                title: "盲点",
                icon: "eye.slash",
                guidance: "用户可能忽略的假设、信息或风险"
            ),
            SectionSpec(
                key: "alternative_perspectives",
                title: "替代视角",
                icon: "binoculars",
                guidance: "同一处境还可以怎么看"
            ),
            SectionSpec(
                key: "next_steps",
                title: "下一步",
                icon: "arrow.forward.circle",
                guidance: "哪些信息或行动能让决定更清晰"
            ),
        ],
        keywords: ["要不要", "该不该", "选择", "决定", "纠结", "利弊", "值不值", "方案", "还是", "取舍"]
    )

    static let writingReview = AnalysisLens(
        id: "writing-review",
        name: "写作复盘",
        shortLabel: "写作",
        icon: "pencil.and.ruler",
        systemRole: "你是一位严格但友好的文字编辑。你关注表达质量，不改变用户原本的观点。",
        sections: [
            SectionSpec(
                key: "clarity",
                title: "清晰度",
                icon: "magnifyingglass",
                guidance: "哪些地方含糊、有歧义"
            ),
            SectionSpec(
                key: "structure",
                title: "结构",
                icon: "list.number",
                guidance: "论证是否连贯、层次是否清楚"
            ),
            SectionSpec(
                key: "weak_points",
                title: "薄弱点",
                icon: "exclamationmark.triangle",
                guidance: "哪里空泛、重复或缺乏支撑"
            ),
            SectionSpec(
                key: "revision_suggestions",
                title: "修改建议",
                icon: "pencil",
                guidance: "针对具体句子给出改进方向"
            ),
            SectionSpec(
                key: "example_revision",
                title: "改写示例",
                icon: "doc.text.magnifyingglass",
                guidance: "给出一个更清楚的改写版本"
            ),
        ],
        keywords: ["写", "文章", "邮件", "文案", "文档", "报告", "草稿", "措辞", "表达", "润色", "修改"]
    )

    static let communicationReview = AnalysisLens(
        id: "communication-review",
        name: "沟通复盘",
        shortLabel: "沟通",
        icon: "bubble.left.and.bubble.right",
        systemRole: "你是一位沟通顾问。你帮用户预判：这段话发出去后，对方可能会怎么理解。",
        sections: [
            SectionSpec(
                key: "likely_interpretation",
                title: "对方的可能理解",
                icon: "person.wave.2",
                guidance: "对方大概率会怎么读这句话"
            ),
            SectionSpec(
                key: "potential_misunderstandings",
                title: "可能的误解",
                icon: "questionmark.bubble",
                guidance: "哪些地方可能被理解成别的意思"
            ),
            SectionSpec(
                key: "communication_risks",
                title: "沟通风险",
                icon: "exclamationmark.bubble",
                guidance: "哪些措辞会制造不必要的摩擦"
            ),
            SectionSpec(
                key: "possible_responses",
                title: "更精确的表达",
                icon: "text.bubble",
                guidance: "如何把同样的意思说得更准"
            ),
            SectionSpec(
                key: "reply_options",
                title: "可能的后续回复",
                icon: "arrowshape.turn.up.left.2",
                guidance: "对方若这样回，可以怎么接"
            ),
        ],
        keywords: ["回复", "沟通", "跟他说", "发消息", "老板", "同事", "客户", "朋友", "怎么开口", "吵架", "解释", "微信"]
    )

    static let all: [AnalysisLens] = [.decisionReview, .writingReview, .communicationReview]

    static func lens(for id: String) -> AnalysisLens {
        all.first { $0.id == id } ?? .decisionReview
    }

    static func suggest(for text: String) -> AnalysisLens? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var best: (lens: AnalysisLens, score: Int)?
        for lens in all {
            let score = lens.keywords.reduce(0) { partial, keyword in
                partial + (trimmed.contains(keyword) ? 1 : 0)
            }
            if score > 0, score > (best?.score ?? 0) {
                best = (lens, score)
            }
        }
        return best?.lens
    }
}
