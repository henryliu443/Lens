import SwiftUI

struct OnboardingView: View {
    @Environment(SettingsViewModel.self) private var settings
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                welcomePage
                    .readableWidth(560)
                    .tag(0)
                providerPage
                    .readableWidth(560)
                    .tag(1)
                readyPage
                    .readableWidth(560)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(action: advance) {
                Text(page == 2 ? "开始使用" : "下一步")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        LinearGradient(
                            colors: [Color("GradientStart"), Color("GradientEnd")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(
            LinearGradient(
                colors: [
                    Color("GradientStart").opacity(0.12),
                    Color("GradientEnd").opacity(0.05),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }

    private var welcomePage: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "binoculars.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)

            Text("同一段输入，不同视角")
                .font(.title.weight(.bold))
                .foregroundStyle(Color("TextPrimary"))

            Text("Lens 不和你聊天。它把同一段文字，按你选择的视角，拆成结构化的分析。")
                .font(.subheadline)
                .foregroundStyle(Color("TextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 12) {
                ForEach(AnalysisLens.all) { lens in
                    HStack(spacing: 12) {
                        Image(systemName: lens.icon)
                            .frame(width: 28)
                            .foregroundStyle(Color.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lens.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color("TextPrimary"))
                            Text(lens.sections.map(\.title).joined(separator: " · "))
                                .font(.caption)
                                .foregroundStyle(Color("TextSecondary"))
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(Color("CardBackground"))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private var providerPage: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("选择 AI 服务商")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color("TextPrimary"))

            Text("可以先用本地离线模式体验，随时在设置里切换。")
                .font(.subheadline)
                .foregroundStyle(Color("TextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 12) {
                ForEach(AIProvider.allCases) { provider in
                    Button {
                        settings.selectedProvider = provider
                    } label: {
                        HStack {
                            Text(provider.displayName)
                                .foregroundStyle(Color("TextPrimary"))
                            Spacer()
                            if settings.selectedProvider == provider {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding(14)
                        .background(Color("CardBackground"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    settings.selectedProvider == provider ? Color.accentColor : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            if settings.selectedProvider.requiresAPIKey {
                SecureField("粘贴 API Key", text: apiKeyBinding)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(Color("CardBackground"))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal, 24)
            }

            Spacer()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: settings.selectedProvider)
    }

    private var readyPage: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)

            Text("准备好了")
                .font(.title.weight(.bold))
                .foregroundStyle(Color("TextPrimary"))

            Text("当前服务商：\(settings.selectedProvider.displayName)")
                .font(.subheadline)
                .foregroundStyle(Color("TextSecondary"))

            if settings.selectedProvider.requiresAPIKey, !settings.hasAPIKey {
                Text("还没有填写 API Key，分析时会提示你先去设置里补充。")
                    .font(.footnote)
                    .foregroundStyle(Color.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            } else {
                Text("输入一段文字，选一个视角，开始你的第一次分析。")
                    .font(.footnote)
                    .foregroundStyle(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
    }

    private var apiKeyBinding: Binding<String> {
        Binding(
            get: { settings.apiKeyInput },
            set: { settings.apiKeyInput = $0 }
        )
    }

    private func advance() {
        if page < 2 {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                page += 1
            }
        } else {
            settings.saveAPIKey()
            hasCompletedOnboarding = true
        }
    }
}
