import Foundation

enum PromptBuilder {
    static func buildSystemPrompt(lens: AnalysisLens, depth: AnalysisDepth, tone: ResponseTone) -> String {
        var lines: [String] = []
        lines.append(lens.systemRole)
        lines.append("")
        lines.append("请从该视角出发，严格按照以下结构逐段输出分析：")
        for section in lens.sections {
            lines.append("- \(section.title)（key: \(section.key)）：\(section.guidance)")
        }
        lines.append("")
        lines.append(depthInstruction(depth))
        lines.append(toneInstruction(tone))
        lines.append("")
        lines.append(outputFormat(lens: lens))
        return lines.joined(separator: "\n")
    }

    static func buildUserPrompt(input: String) -> String {
        "用户的输入：\n\(input)"
    }

    private static func depthInstruction(_ depth: AnalysisDepth) -> String {
        switch depth {
        case .quick:
            return "深度要求：每段用 1-2 句说清楚，不要展开。"
        case .balanced:
            return "深度要求：每段 2-3 句，兼顾准确与简洁。"
        case .deep:
            return "深度要求：每段 3-5 句，必要时结合用户输入举例说明。"
        }
    }

    private static func toneInstruction(_ tone: ResponseTone) -> String {
        switch tone {
        case .brief:
            return "语气要求：直接、专业，不寒暄。"
        case .coach:
            return "语气要求：引导式，多用提问帮助用户自己思考。"
        case .warm:
            return "语气要求：先共情，再给出视角，保持友善。"
        }
    }

    private static func outputFormat(lens: AnalysisLens) -> String {
        let skeleton = lens.sections
            .map { "\"\($0.key)\": \"...\"" }
            .joined(separator: ", ")

        return """
        只输出一个纯 JSON 对象，不要 markdown 代码块、不要任何解释或多余文字。
        键必须严格使用以下英文 key，值用中文：
        {\(skeleton)}
        """
    }
}
