# Lens

**English** | [中文](README.zh-CN.md)

`dev0.0.1`

Same input, seen from another angle.

Lens is a native iOS "multi-perspective analysis" tool: the user enters a piece of text, picks a **Lens (analysis perspective)**, and the AI returns several sections of analysis following that Lens's fixed structure. It is not a chat tool — it is structured multi-perspective review.

## The Three Lenses

| Lens | Description | Output structure |
|---|---|---|
| Decision Review `decision-review` | Calm, structured decision analysis | Key considerations / Blind spots / Alternative perspectives / Next steps |
| Writing Review `writing-review` | A strict but friendly editor | Clarity / Structure / Weak points / Revision suggestions / Example revision |
| Communication Review `communication-review` | Anticipates how the other side will read it | Likely interpretation / Potential misunderstandings / Communication risks / More precise wording / Possible replies |

The three Lenses are three genuinely different ways of reading the same input: each has its own system role, section structure, guidance, and recommendation keywords.

## Tech Stack

- iOS 17+ only (iPhone + iPad), a single Xcode project
- SwiftUI + MVVM, `@Observable` ViewModels, no business logic in Views
- SwiftData for history persistence
- URLSession for networking, Security / Keychain for API keys
- Zero third-party dependencies

## Directory Structure

```
com.lens/
├── LensApp.swift
├── Models/
│   ├── AnalysisLens.swift        # 3 Lens definitions + local recommendation rules
│   ├── SectionSpec.swift
│   ├── Analysis.swift
│   ├── AnalysisDepth.swift       # AnalysisDepth + ResponseTone
│   ├── AIProvider.swift          # provider / model / baseURL
│   └── Record.swift
├── Services/
│   ├── AIServiceProtocol.swift   # protocol + factory + errors + shared request helper + tolerant parser
│   ├── OpenAIService.swift
│   ├── AnthropicService.swift
│   ├── DeepSeekService.swift
│   ├── LocalAnalysisService.swift
│   ├── PromptBuilder.swift
│   └── KeychainManager.swift
├── ViewModels/
│   ├── AnalysisViewModel.swift
│   ├── SettingsViewModel.swift
│   └── HistoryViewModel.swift
└── Views/
    ├── MainTabView.swift
    ├── HomeView.swift
    ├── ResultCardView.swift
    ├── HistoryView.swift
    ├── SettingsView.swift
    ├── OnboardingView.swift
    └── Components/
        ├── InputCard.swift
        ├── LensPickerView.swift
        ├── ErrorBannerView.swift
        └── ReadableWidth.swift
```

## AI Providers

| Provider | Notes |
|---|---|
| OpenAI | `/v1/chat/completions`, Bearer auth |
| Anthropic | `/v1/messages`, `x-api-key` + `anthropic-version: 2023-06-01` |
| DeepSeek | `/v1/chat/completions`; `deepseek-reasoner` folds system into user, 120s timeout |
| Local (offline) | Bundled sample results, no key needed, works offline |

Errors map uniformly to `AIServiceError`: `noAPIKey / invalidResponse / networkError / rateLimited / invalidKey / parseError`, with 401 → invalidKey and 429 → rateLimited.

## Tolerant Parsing

`parseSections(_:lens:)` tries in order: strip markdown wrapper → extract JSON → `JSONDecoder` → `JSONSerialization` (with Chinese-title key fallback) → map by line order → throw `parseError`. It tolerates markdown-wrapped responses, missing keys, and mixed Chinese/English keys.

## Build & Run

1. Open `com.lens/com.lens.xcodeproj` in Xcode
2. Select an iOS 17+ simulator or device
3. On first launch, finish onboarding: pick a provider (you can pick "Local (offline)") and enter an API key
4. Enter text on Home → choose/accept the recommended Lens → Analyze → the result is saved to history automatically

Command-line build:

```bash
xcodebuild -project com.lens/com.lens.xcodeproj -scheme com.lens \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```

## Privacy

- API keys are stored only in the local Keychain (service: `com.henryliu.lens.apikeys`) and never uploaded
- No accounts, no cloud sync, no backend
- History is stored locally via SwiftData

## Non-Goals

- No chat/conversational interaction — only "one input → structured analysis"
- No Android / cross-platform / shared layer
- No mental-health, emotion, or crisis-intervention content

## License

Apache-2.0. See `LICENSE`.
