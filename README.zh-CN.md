# Lens

[English](README.md) | **中文**

`dev0.0.1`

同一段输入，换一个视角看。

Lens 是一个 iOS 原生「多视角分析」工具：用户输入一段文字，选择一个 **Lens（分析视角）**，AI 按该视角固定的结构返回多段分析结果。它不是聊天工具，而是结构化的多视角审视。

## 三个 Lens

| Lens | 说明 | 输出结构 |
|---|---|---|
| 决策复盘 `decision-review` | 冷静、结构化的决策分析 | 关键考量 / 盲点 / 替代视角 / 下一步 |
| 写作复盘 `writing-review` | 严格但友好的文字编辑 | 清晰度 / 结构 / 薄弱点 / 修改建议 / 改写示例 |
| 沟通复盘 `communication-review` | 预判对方会如何理解 | 对方的可能理解 / 可能的误解 / 沟通风险 / 更精确的表达 / 可能的后续回复 |

三个 Lens 是看同一段输入的三种真正不同的方式：各自的角色设定、section 结构、guidance 与推荐关键词都不同。

## 技术栈

- 仅 iOS 17+（iPhone + iPad），单一 Xcode 工程
- SwiftUI + MVVM，`@Observable` ViewModel，View 不含业务逻辑
- SwiftData 持久化历史记录
- URLSession 网络，Security / Keychain 保存 API Key
- 零第三方依赖

## 目录结构

```
com.lens/
├── LensApp.swift
├── Models/
│   ├── AnalysisLens.swift        # 3 个 Lens 定义 + 本地推荐规则
│   ├── SectionSpec.swift
│   ├── Analysis.swift
│   ├── AnalysisDepth.swift       # AnalysisDepth + ResponseTone
│   ├── AIProvider.swift          # provider / model / baseURL
│   └── Record.swift
├── Services/
│   ├── AIServiceProtocol.swift   # 协议 + 工厂 + 错误 + 共享请求 helper + 容错解析器
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

## AI 服务商

| 服务商 | 说明 |
|---|---|
| OpenAI | `/v1/chat/completions`，Bearer 鉴权 |
| Anthropic | `/v1/messages`，`x-api-key` + `anthropic-version: 2023-06-01` |
| DeepSeek | `/v1/chat/completions`；`deepseek-reasoner` 将 system 拼入 user，超时 120s |
| 本地（离线） | 预置示例结果，无需 Key，可离线体验 |

错误统一映射为 `AIServiceError`：`noAPIKey / invalidResponse / networkError / rateLimited / invalidKey / parseError`，401 → invalidKey，429 → rateLimited。

## 容错解析

`parseSections(_:lens:)` 依次尝试：去 markdown 包裹 → 截取 JSON → `JSONDecoder` → `JSONSerialization`（含中文标题 key 兜底）→ 按行顺序映射 → 抛 `parseError`。对带 markdown、缺 key、中英 key 的响应都能容错。

## 构建与运行

1. 用 Xcode 打开 `com.lens/com.lens.xcodeproj`
2. 选择 iOS 17+ 模拟器或真机
3. 首次启动完成 onboarding：选择服务商（可直接选「本地（离线）」）并填写 API Key
4. 首页输入文字 → 选择/接受推荐 Lens → 分析 → 结果自动存入历史

命令行构建：

```bash
xcodebuild -project com.lens/com.lens.xcodeproj -scheme com.lens \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```

## 隐私

- API Key 仅保存在本机 Keychain（service：`com.henryliu.lens.apikeys`），不会上传
- 无账号、无云同步、无后端
- 历史记录保存在本机 SwiftData

## 非目标

- 不做聊天/对话式交互，只做「一次输入 → 结构化分析」
- 不做 Android / 跨平台 / 共享层
- 不做心理健康、情绪、危机干预相关内容

## 许可证 / License

Apache-2.0. 详见 `LICENSE` / See `LICENSE`.
