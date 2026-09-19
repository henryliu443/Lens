import Foundation

struct LocalAnalysisService: AIServiceProtocol {
    let provider = AIProvider.local

    func analyze(
        input: String,
        model: AIModel,
        lens: AnalysisLens,
        depth: AnalysisDepth,
        tone: ResponseTone
    ) async throws -> Analysis {
        try await Task.sleep(nanoseconds: 400_000_000)

        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AIServiceError.parseError("请先输入想分析的内容")
        }

        let pool = pool(for: lens)
        let index = Self.stableHash(trimmed) % pool.count
        let preset = pool[index]

        var sections: [String: String] = [:]
        for spec in lens.sections {
            sections[spec.key] = preset[spec.key] ?? ""
        }

        return Analysis(lensID: lens.id, sections: sections, createdAt: Date())
    }

    private func pool(for lens: AnalysisLens) -> [[String: String]] {
        switch lens.id {
        case AnalysisLens.writingReview.id:
            return Self.writingPool
        case AnalysisLens.communicationReview.id:
            return Self.communicationPool
        default:
            return Self.decisionPool
        }
    }

    private static func stableHash(_ text: String) -> Int {
        var hash = 5381
        for scalar in text.unicodeScalars {
            hash = (hash &* 33) &+ Int(scalar.value)
        }
        return abs(hash)
    }

    private static let decisionPool: [[String: String]] = [
        [
            "key_considerations": "这件事真正影响结果的因素通常只有少数几个，先分清哪些是你能控制的、哪些不是。把时间和资源集中在可控因素上，往往比反复权衡更有效。",
            "blind_spots": "常见的盲点是把「当下的情绪」当成「长期的事实」，以及只看到两个极端选项。也许还存在第三种你没列出的方案。",
            "alternative_perspectives": "如果把时间拉到一年后回看，这个决定还有现在这么重要吗？换成朋友的角度，你可能会建议他关注成本而非完美。",
            "next_steps": "先列出两个选项各自最坏的结果，确认你能否承受；再找一位有相关经验的人聊十分钟。",
        ],
        [
            "key_considerations": "决策的关键在于明确你的优先级：是更看重收益上限，还是更在意风险下限。两者往往会指向不同的选择。",
            "blind_spots": "你可能高估了「不行动」的成本，也低估了它的价值。维持现状本身也是一种选择。",
            "alternative_perspectives": "把这个问题拆成「现在必须决定」和「可以再等等」两部分，也许有些信息稍后自然会出现。",
            "next_steps": "给每个选项打一个可逆性分数：如果选错，退回原状的代价有多大？",
        ],
        [
            "key_considerations": "先写下这个决定要达成的核心目标，再逐条检查各选项与目标的匹配度，而不是比较选项本身的好坏。",
            "blind_spots": "容易忽略的是沉没成本：已经投入的时间或金钱不应影响下一步判断。",
            "alternative_perspectives": "与其问「哪个更好」，不如问「哪个更坏的时候我更能接受」。",
            "next_steps": "设定一个决定截止日期，避免无限期纠结；到期就按当时掌握的信息行动。",
        ],
    ]

    private static let writingPool: [[String: String]] = [
        [
            "clarity": "部分句子过长，读者需要回头才能抓住主干。建议把一句话里超过两个的从句拆开，让每个句子只承担一个意思。",
            "structure": "整体有开头和结尾，但中间层次偏平，几处论点并列出现，读者不易分辨主次。可以给每段一个明确的小结论。",
            "weak_points": "有几处用了「很多」「非常重要」这类概括词，但缺少具体例子或数据支撑，说服力被稀释。",
            "revision_suggestions": "把抽象表述替换成具体场景；在段首用一句话点明该段要点；删去重复出现的同义表达。",
            "example_revision": "原句：「这个方案有很多好处，非常重要。」改写：「这个方案能把处理时间从两天缩短到两小时，因此值得优先推进。」",
        ],
        [
            "clarity": "开头没有交代背景，读者不知道这段话是写给谁的、要解决什么问题，容易读得云里雾里。",
            "structure": "论证顺序可以调整：先给结论，再给理由，最后给行动建议，会更符合读者的阅读习惯。",
            "weak_points": "结尾部分只是重复了前文，没有推进。可以补充一个具体的下一步，让文章有落点。",
            "revision_suggestions": "第一段补一句目的说明；把最重要的结论提前；结尾用一句话说明希望读者做什么。",
            "example_revision": "改写建议：先写「本文想说明为什么建议推迟上线」，再依次给出三个理由。",
        ],
        [
            "clarity": "代词使用偏多，多处「这个」「它」指代不明，读者需要猜测具体指哪一件事。",
            "structure": "段落之间的过渡较生硬，缺少连接句，读起来像几段独立的文字拼在一起。",
            "weak_points": "论据集中在同一类证据上，视角单一。可以补充一个反例或不同来源的观察。",
            "revision_suggestions": "把「它」换成具体名词；在段落之间加一句承上启下的话；为每个论点配一个例子。",
            "example_revision": "原句：「它影响了我们的判断。」改写：「预算的不确定性影响了我们的判断。」",
        ],
    ]

    private static let communicationPool: [[String: String]] = [
        [
            "likely_interpretation": "对方大概率会先感受到你的情绪，再理解你的内容。如果开头语气偏重，后面的解释可能被当成辩解。",
            "potential_misunderstandings": "「你怎么又……」这类表述容易被理解成指责，即使你的本意只是说明情况。",
            "communication_risks": "在对方还没表达完时给出结论，会让对方觉得没有被听见，从而升级对立。",
            "possible_responses": "把「你总是」换成「这次的情况是」，把评价改成对具体事实的描述，能让对方更容易接住。",
            "reply_options": "如果对方回「你想多了」，可以先承认感受再回到事实：「我理解你这么说，我想确认的是那件事的处理方式。」",
        ],
        [
            "likely_interpretation": "对方可能会把你的直接当成不耐烦，尤其是文字消息缺少语气，容易读得比实际更冷。",
            "potential_misunderstandings": "省略问候和背景直接说事，可能被理解为命令而不是请求。",
            "communication_risks": "把多个问题放在一条消息里，对方容易只回应最扎眼的那一条，其余被忽略。",
            "possible_responses": "一次只谈一件事，并在结尾说明你希望对方做什么、什么时候回复。",
            "reply_options": "如果对方迟迟不回，可以补一句：「不着急，你方便时告诉我你的想法就好。」",
        ],
        [
            "likely_interpretation": "对方会先判断你是在寻求帮助还是在表达不满，这决定了他是配合还是防御。",
            "potential_misunderstandings": "使用绝对化词语「从来」「永远」时，对方容易聚焦在反驳上，而不是你的真实需求。",
            "communication_risks": "在公开场合提出敏感话题，会给对方压力，即使内容本身没问题。",
            "possible_responses": "把诉求说具体：说明发生了什么、你的感受、你希望的结果，三句话即可。",
            "reply_options": "如果对方情绪上来了，可以先暂停：「我们都有点急，晚点再聊这件事，可以吗？」",
        ],
    ]
}
