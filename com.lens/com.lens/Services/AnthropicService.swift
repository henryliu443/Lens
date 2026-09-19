import Foundation

struct AnthropicService: AIServiceProtocol {
    let provider = AIProvider.anthropic

    func analyze(
        input: String,
        model: AIModel,
        lens: AnalysisLens,
        depth: AnalysisDepth,
        tone: ResponseTone
    ) async throws -> Analysis {
        let apiKey = try AIRequestHelper.apiKey(for: provider)

        let body: [String: Any] = [
            "model": model.id,
            "max_tokens": 1024,
            "system": PromptBuilder.buildSystemPrompt(lens: lens, depth: depth, tone: tone),
            "messages": [
                ["role": "user", "content": PromptBuilder.buildUserPrompt(input: input)],
            ],
        ]

        let request = try AIRequestHelper.makeRequest(
            url: URL(string: provider.baseURL)!,
            headers: [
                "x-api-key": apiKey,
                "anthropic-version": "2023-06-01",
            ],
            body: body,
            timeout: 60
        )

        let data = try await AIRequestHelper.send(request, provider: provider)
        return try parseResponse(data, lens: lens)
    }

    private func parseResponse(_ data: Data, lens: AnalysisLens) throws -> Analysis {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let textBlock = content.first(where: { $0["type"] as? String == "text" }),
              let text = AIRequestHelper.nonEmptyString(textBlock["text"]) else {
            throw AIServiceError.invalidResponse
        }

        let sections = try parseSections(text, lens: lens)
        return Analysis(lensID: lens.id, sections: sections, createdAt: Date())
    }
}
