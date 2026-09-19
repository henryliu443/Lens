import Foundation

struct OpenAIService: AIServiceProtocol {
    let provider = AIProvider.openai

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
            "messages": [
                ["role": "system", "content": PromptBuilder.buildSystemPrompt(lens: lens, depth: depth, tone: tone)],
                ["role": "user", "content": PromptBuilder.buildUserPrompt(input: input)],
            ],
            "temperature": 0.7,
            "max_tokens": 1024,
        ]

        let request = try AIRequestHelper.makeRequest(
            url: URL(string: provider.baseURL)!,
            headers: ["Authorization": "Bearer \(apiKey)"],
            body: body,
            timeout: 60
        )

        let data = try await AIRequestHelper.send(request, provider: provider)
        return try parseResponse(data, lens: lens)
    }

    private func parseResponse(_ data: Data, lens: AnalysisLens) throws -> Analysis {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = AIRequestHelper.nonEmptyString(message["content"]) else {
            throw AIServiceError.invalidResponse
        }

        let sections = try parseSections(content, lens: lens)
        return Analysis(lensID: lens.id, sections: sections, createdAt: Date())
    }
}
