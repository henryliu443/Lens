import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(SettingsViewModel.self) private var settings
    @Environment(\.modelContext) private var context
    @State private var viewModel = AnalysisViewModel()
    @State private var didApplyDefaultLens = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    greeting

                    InputCard(text: $viewModel.inputText)
                        .focused($isInputFocused)

                    LensPickerView(
                        selected: viewModel.selectedLens,
                        suggested: viewModel.suggestedLens,
                        onSelect: { lens in
                            isInputFocused = false
                            viewModel.selectLens(lens)
                        }
                    )

                    analyzeButton

                    if let errorMessage = viewModel.errorMessage {
                        ErrorBannerView(message: errorMessage)
                    }

                    if let analysis = viewModel.analysis {
                        ResultCardView(analysis: analysis)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(16)
                .readableWidth()
            }
            .background(
                LinearGradient(
                    colors: [
                        Color("GradientStart").opacity(0.10),
                        Color("GradientEnd").opacity(0.04),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Lens")
            .scrollDismissesKeyboard(.interactively)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.analysis?.id)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: viewModel.errorMessage)
        }
        .onAppear {
            guard !didApplyDefaultLens else { return }
            didApplyDefaultLens = true
            viewModel.selectedLens = settings.defaultLens
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greetingText)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color("TextPrimary"))
            Text("同一段输入，换一个视角看")
                .font(.subheadline)
                .foregroundStyle(Color("TextSecondary"))
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return "早上好"
        case 11..<13: return "中午好"
        case 13..<18: return "下午好"
        case 18..<23: return "晚上好"
        default: return "夜深了"
        }
    }

    private var analyzeButton: some View {
        Button {
            isInputFocused = false
            Task {
                await viewModel.analyze(settings: settings, context: context)
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isAnalyzing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: viewModel.selectedLens.icon)
                }
                Text(viewModel.isAnalyzing ? "分析中…" : "用「\(viewModel.selectedLens.shortLabel)」视角分析")
                    .font(.headline)
            }
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
            .opacity(viewModel.canAnalyze ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canAnalyze)
    }
}
