import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(SettingsViewModel.self) private var settings
    @Environment(\.modelContext) private var context
    @State private var showClearConfirm = false
    @State private var showSavedFeedback = false

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            Form {
                Section("AI 服务商") {
                    Picker("服务商", selection: $settings.selectedProvider) {
                        ForEach(AIProvider.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                }

                if settings.selectedProvider.requiresAPIKey {
                    Section {
                        SecureField("API Key", text: $settings.apiKeyInput)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        Button {
                            settings.saveAPIKey()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showSavedFeedback = true
                            }
                        } label: {
                            HStack {
                                Text("保存 API Key")
                                Spacer()
                                if showSavedFeedback {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    } header: {
                        Text("API Key")
                    } footer: {
                        Text("Key 仅保存在本机 Keychain，不会上传。")
                    }
                }

                Section("模型") {
                    Picker("模型", selection: $settings.selectedModelId) {
                        ForEach(settings.selectedProvider.availableModels) { model in
                            Text(model.name).tag(model.id)
                        }
                    }
                }

                Section("分析偏好") {
                    Picker("分析深度", selection: $settings.depth) {
                        ForEach(AnalysisDepth.allCases) { depth in
                            Text(depth.displayName).tag(depth)
                        }
                    }

                    Picker("回应语气", selection: $settings.tone) {
                        ForEach(ResponseTone.allCases) { tone in
                            Text(tone.displayName).tag(tone)
                        }
                    }

                    Picker("默认视角", selection: $settings.defaultLensID) {
                        ForEach(AnalysisLens.all) { lens in
                            Text(lens.name).tag(lens.id)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Text("清除所有数据")
                    }
                } footer: {
                    Text("会删除历史记录、收藏、设置与本机保存的 API Key。")
                }

                Section("关于") {
                    LabeledContent("名称", value: "Lens")
                    LabeledContent("版本", value: appVersion)
                    LabeledContent("模式", value: "一次输入 · 结构化多视角分析")
                }
            }
            .readableWidth(760)
            .navigationTitle("设置")
            .confirmationDialog(
                "确定清除所有数据？",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("清除", role: .destructive) {
                    clearAll()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("此操作无法撤销。")
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func clearAll() {
        try? context.delete(model: Record.self)
        try? context.save()
        settings.clearAllData()
        showSavedFeedback = false
    }
}
