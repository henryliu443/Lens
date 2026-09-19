import Foundation

struct DeepSeekService: AIServiceProtocol {
    let provider = AIProvider.deepseek

    func analyze(
        input: String,
        model: AIModel,
        lens: AnalysisLens,
        depth: AnalysisDepth,
        tone: ResponseTone
    ) async throws -> Analysis {
        let apiKey = try AIRequestHelper.apiKey(for: provider)
        let isReasoner = model.id.contains("reasoner")

        let systemPrompt = PromptBuilder.buildSystemPrompt(lens: lens, depth: depth, tone: tone)
        let userPrompt = PromptBuilder.buildUserPrompt(input: input)

        var body: [String: Any] = [
            "model": model.id,
            "max_tokens": isReasoner ? 4096 : 1024,
        ]

        if isReasoner {
            body["messages"] = [
                ["role": "user", "content": "\(systemPrompt)\n\n\(userPrompt)"],
            ]
        } else {
            body["messages"] = [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt],
            ]
            body["temperature"] = 0.7
        }

        let request = try AIRequestHelper.makeRequest(
            url: URL(string: provider.baseURL)!,
            headers: ["Authorization": "Bearer \(apiKey)"],
            body: body,
            timeout: isReasoner ? 120 : 60
        )

        let data = try await AIRequestHelper.send(request, provider: provider)
        return try parseResponse(data, lens: lens)
    }

    private func parseResponse(_ data: Data, lens: AnalysisLens) throws -> Analysis {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any] else {
            throw AIServiceError.invalidResponse
        }

        let text = AIRequestHelper.nonEmptyString(message["content"])
            ?? AIRequestHelper.nonEmptyString(message["reasoning_content"])

        guard let text else {
            throw AIServiceError.invalidResponse
        }

        let sections = try parseSections(text, lens: lens)
        return Analysis(lensID: lens.id, sections: sections, createdAt: Date())
    }
}
