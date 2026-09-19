import Foundation

@Observable
final class SettingsViewModel {
    enum Keys {
        static let provider = "selectedProvider"
        static let model = "selectedModelId"
        static let depth = "analysisDepth"
        static let tone = "responseTone"
        static let defaultLens = "defaultLensID"
    }

    var selectedProvider: AIProvider {
        didSet {
            UserDefaults.standard.set(selectedProvider.id, forKey: Keys.provider)
            if !selectedProvider.availableModels.contains(where: { $0.id == selectedModelId }) {
                selectedModelId = selectedProvider.defaultModel.id
            }
            loadAPIKey()
        }
    }

    var selectedModelId: String {
        didSet {
            UserDefaults.standard.set(selectedModelId, forKey: Keys.model)
        }
    }

    var depth: AnalysisDepth {
        didSet {
            UserDefaults.standard.set(depth.rawValue, forKey: Keys.depth)
        }
    }

    var tone: ResponseTone {
        didSet {
            UserDefaults.standard.set(tone.rawValue, forKey: Keys.tone)
        }
    }

    var defaultLensID: String {
        didSet {
            UserDefaults.standard.set(defaultLensID, forKey: Keys.defaultLens)
        }
    }

    var apiKeyInput: String = ""

    var selectedModel: AIModel {
        selectedProvider.availableModels.first { $0.id == selectedModelId }
            ?? selectedProvider.defaultModel
    }

    var defaultLens: AnalysisLens {
        AnalysisLens.lens(for: defaultLensID)
    }

    var hasAPIKey: Bool {
        guard selectedProvider.requiresAPIKey else { return true }
        let key = KeychainManager.shared.load(key: selectedProvider.id) ?? ""
        return !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init() {
        let defaults = UserDefaults.standard

        let providerRaw = defaults.string(forKey: Keys.provider) ?? AIProvider.local.id
        let provider = AIProvider(rawValue: providerRaw) ?? .local
        self.selectedProvider = provider

        let modelRaw = defaults.string(forKey: Keys.model) ?? ""
        self.selectedModelId = modelRaw.isEmpty ? provider.defaultModel.id : modelRaw

        let depthRaw = defaults.string(forKey: Keys.depth) ?? AnalysisDepth.balanced.rawValue
        self.depth = AnalysisDepth(rawValue: depthRaw) ?? .balanced

        let toneRaw = defaults.string(forKey: Keys.tone) ?? ResponseTone.warm.rawValue
        self.tone = ResponseTone(rawValue: toneRaw) ?? .warm

        let lensRaw = defaults.string(forKey: Keys.defaultLens) ?? AnalysisLens.decisionReview.id
        self.defaultLensID = AnalysisLens.lens(for: lensRaw).id

        loadAPIKey()
    }

    func loadAPIKey() {
        apiKeyInput = KeychainManager.shared.load(key: selectedProvider.id) ?? ""
    }

    func saveAPIKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            KeychainManager.shared.delete(key: selectedProvider.id)
        } else {
            KeychainManager.shared.save(key: selectedProvider.id, value: trimmed)
        }
    }

    func clearAllData() {
        KeychainManager.shared.deleteAll()
        apiKeyInput = ""

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Keys.provider)
        defaults.removeObject(forKey: Keys.model)
        defaults.removeObject(forKey: Keys.depth)
        defaults.removeObject(forKey: Keys.tone)
        defaults.removeObject(forKey: Keys.defaultLens)

        selectedProvider = .local
        selectedModelId = AIProvider.local.defaultModel.id
        depth = .balanced
        tone = .warm
        defaultLensID = AnalysisLens.decisionReview.id
    }
}
