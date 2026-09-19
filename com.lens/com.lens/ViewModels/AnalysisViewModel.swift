import Foundation
import SwiftData
import UIKit

@Observable
final class AnalysisViewModel {
    var inputText: String = "" {
        didSet { refreshSuggestion() }
    }

    var selectedLens: AnalysisLens = .decisionReview {
        didSet { refreshSuggestion() }
    }

    var suggestedLens: AnalysisLens?
    var isAnalyzing: Bool = false
    var errorMessage: String?
    var analysis: Analysis?
    var lastRecord: Record?

    var canAnalyze: Bool {
        !isAnalyzing && !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func selectLens(_ lens: AnalysisLens) {
        selectedLens = lens
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func applySuggestion() {
        guard let suggestedLens else { return }
        selectLens(suggestedLens)
    }

    func analyze(settings: SettingsViewModel, context: ModelContext) async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "请先输入想分析的内容"
            return
        }

        isAnalyzing = true
        errorMessage = nil

        let service = AIServiceFactory.service(for: settings.selectedProvider)
        do {
            let result = try await service.analyze(
                input: trimmed,
                model: settings.selectedModel,
                lens: selectedLens,
                depth: settings.depth,
                tone: settings.tone
            )
            analysis = result

            let record = Record(
                inputText: trimmed,
                lensID: result.lensID,
                sections: result.sections,
                providerName: settings.selectedProvider.displayName,
                modelName: settings.selectedModel.name
            )
            context.insert(record)
            try? context.save()
            lastRecord = record

            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isAnalyzing = false
    }

    func load(_ record: Record) {
        inputText = record.inputText
        selectedLens = record.lens
        analysis = Analysis(lensID: record.lensID, sections: record.sections, createdAt: record.createdAt)
        errorMessage = nil
    }

    func reset() {
        inputText = ""
        analysis = nil
        lastRecord = nil
        errorMessage = nil
    }

    private func refreshSuggestion() {
        guard let suggestion = AnalysisLens.suggest(for: inputText), suggestion != selectedLens else {
            suggestedLens = nil
            return
        }
        suggestedLens = suggestion
    }
}
