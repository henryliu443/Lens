import Foundation

enum AIServiceError: LocalizedError {
    case noAPIKey
    case invalidResponse
    case networkError(Error)
    case rateLimited
    case invalidKey
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "请先在设置中填写 API Key"
        case .invalidResponse:
            return "AI 返回了无效的响应，请稍后重试"
        case .networkError(let error):
            return "网络错误：\(error.localizedDescription)"
        case .rateLimited:
            return "请求过于频繁，请稍后再试"
        case .invalidKey:
            return "API Key 无效，请检查设置"
        case .parseError(let detail):
            return "解析响应失败：\(detail)"
        }
    }
}

protocol AIServiceProtocol {
    var provider: AIProvider { get }

    func analyze(
        input: String,
        model: AIModel,
        lens: AnalysisLens,
        depth: AnalysisDepth,
        tone: ResponseTone
    ) async throws -> Analysis
}

enum AIServiceFactory {
    static func service(for provider: AIProvider) -> AIServiceProtocol {
        switch provider {
        case .openai:
            return OpenAIService()
        case .anthropic:
            return AnthropicService()
        case .deepseek:
            return DeepSeekService()
        case .local:
            return LocalAnalysisService()
        }
    }
}

enum AIRequestHelper {
    static func apiKey(for provider: AIProvider) throws -> String {
        guard let key = KeychainManager.shared.load(key: provider.id),
              !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIServiceError.noAPIKey
        }
        return key
    }

    static func makeRequest(
        url: URL,
        headers: [String: String],
        body: [String: Any],
        timeout: TimeInterval
    ) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = timeout
        return request
    }

    static func send(_ request: URLRequest, provider: AIProvider) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AIServiceError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            return data
        case 401:
            throw AIServiceError.invalidKey
        case 429:
            throw AIServiceError.rateLimited
        case 400:
            if provider == .deepseek {
                let text = String(data: data, encoding: .utf8) ?? ""
                if text.contains("Insufficient Balance") || text.lowercased().contains("insufficient") {
                    throw AIServiceError.parseError("DeepSeek 账户余额不足，请充值后重试")
                }
            }
            throw AIServiceError.invalidResponse
        default:
            throw AIServiceError.invalidResponse
        }
    }

    static func nonEmptyString(_ value: Any?) -> String? {
        guard let text = value as? String else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

func parseSections(_ content: String, lens: AnalysisLens) throws -> [String: String] {
    let keys = lens.sections.map(\.key)

    var text = content
        .replacingOccurrences(of: "```json", with: "")
        .replacingOccurrences(of: "```JSON", with: "")
        .replacingOccurrences(of: "```", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)

    if let start = text.firstIndex(of: "{"),
       let end = text.lastIndex(of: "}"),
       start < end {
        text = String(text[start...end])
    }

    if let data = text.data(using: .utf8) {
        if let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            var result: [String: String] = [:]
            for key in keys {
                result[key] = decoded[key] ?? ""
            }
            return result
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            var result: [String: String] = [:]
            var matched = false
            for key in keys {
                if let value = AIRequestHelper.nonEmptyString(json[key]) {
                    result[key] = value
                    matched = true
                }
            }
            let titleToKey = Dictionary(uniqueKeysWithValues: lens.sections.map { ($0.title, $0.key) })
            for (rawKey, rawValue) in json {
                guard let key = titleToKey[rawKey], result[key] == nil else { continue }
                if let value = AIRequestHelper.nonEmptyString(rawValue) {
                    result[key] = value
                    matched = true
                }
            }
            if matched {
                for key in keys where result[key] == nil {
                    result[key] = ""
                }
                return result
            }
        }
    }

    let lines = content
        .components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

    if !lines.isEmpty {
        var result: [String: String] = [:]
        for (index, section) in lens.sections.enumerated() {
            if index < lines.count {
                result[section.key] = cleanLine(lines[index], section: section)
            } else {
                result[section.key] = ""
            }
        }
        if result.values.contains(where: { !$0.isEmpty }) {
            return result
        }
    }

    throw AIServiceError.parseError("无法从响应中解析出分析内容")
}

private func cleanLine(_ line: String, section: SectionSpec) -> String {
    var text = line
    for bullet in ["- ", "* ", "• ", "· ", "－"] {
        if text.hasPrefix(bullet) {
            text = String(text.dropFirst(bullet.count)).trimmingCharacters(in: .whitespaces)
            break
        }
    }
    for prefix in [section.key, section.title] {
        if text.hasPrefix(prefix) {
            text = String(text.dropFirst(prefix.count))
            text = text.trimmingCharacters(in: CharacterSet(charactersIn: "：:）)】] ").union(.whitespaces))
            break
        }
    }
    return text.trimmingCharacters(in: .whitespacesAndNewlines)
}
