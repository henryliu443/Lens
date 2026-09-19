# Lens — 全新 iOS 原生「多视角分析」App 构建指令

## 0. 产品定位
一个「同一段输入，换一个视角看」的 AI 分析工具。用户输入一段文字，选择或由系统推荐一个 **Lens（分析视角）**，AI 按该 Lens 定义的固定结构返回多段分析结果。核心不是聊天，而是**结构化的多视角审视**。

首批提供 3 个 Lens：Decision Review / Writing Review / Communication Review。
三个 Lens 必须是**看同一段输入的三种真正不同的方式**，不是同一个 prompt 换措辞。

本项目为**全新项目**（`/Users/henry/Documents/Lens`），不迁移任何旧代码、旧数据、旧模型。

## 0.5 参考代码（拿不定主意时翻阅）
另有一份旧项目可作**工程参考**（只借实现手法，绝不借领域内容）：
- 目录：`/Users/henry/Documents/cbt-like-tool`
- 注意：该目录工作区当前为空，源码在 git 历史里。最新最全的版本在分支
  `origin/cursor/-bc-379ef8d1-8aee-486f-8ce3-176ab2fbba45-1fd2`
- 取出方式（任选）：
  - 看单个文件：`git -C /Users/henry/Documents/cbt-like-tool show <ref>:<path>`
  - 导出整份：`git -C /Users/henry/Documents/cbt-like-tool archive <ref> | tar -x -C /tmp/cbt-ref`
- 重点参考（工程手法）：
  - 多服务商：`Services/OpenAIService.swift`、`AnthropicService.swift`、`DeepSeekService.swift`、`AIServiceProtocol.swift`、`AIServiceFactory.swift`
  - 容错 JSON 解析：`parseJSONContent`（在 `OpenAIService.swift` 内）
  - Keychain：`Services/KeychainManager.swift`
  - 设置持久化：`ViewModels/SettingsViewModel.swift`
  - SwiftData 历史：`Models/HistoryEntry.swift`、`ViewModels/HistoryViewModel.swift`
  - UI 骨架与动效：`Views/*`、`Views/Components/*`、`Assets.xcassets` 色板
- **严禁借鉴或复制**：CBT 角色设定、CBT/苏格拉底/行为激活提示词、`crisisKeywords`、危机/热线、心情/情绪、认知扭曲文案、`ReframeMode` 中的心理语义。旧项目是 CBT 领域，**只作工程参考，不作产品参考**。

## 1. 技术栈硬约束（不可协商）
- 平台：仅 iOS 17+（iPhone + iPad），单一 Xcode 工程
- UI：SwiftUI；架构：MVVM，`@Observable` ViewModel，View 不含业务逻辑
- 持久化：SwiftData（`@Model`）
- 网络：URLSession；安全：Security / Keychain
- 第三方依赖：**零**（禁止 CocoaPods / SPM 外部包）
- 禁止：Kotlin / KMP / Flutter / React Native / 任何 shared、common 模块 / Gradle、Android 工程 / 跨端抽象层
- 不新建任何非 iOS target；不抽「可复用共享层」

## 2. Domain Model
```swift
struct SectionSpec: Codable, Hashable, Identifiable {
    let key: String          // 稳定英文 key，用于 JSON 与持久化
    let title: String        // 中文标题，用于 UI
    let icon: String         // SF Symbol
    let guidance: String     // 告诉 AI 这一段该写什么
    var id: String { key }
}

struct AnalysisLens: Identifiable, Hashable {
    let id: String           // 稳定英文 id
    let name: String         // 中文名
    let shortLabel: String   // 选择器短标签
    let icon: String
    let systemRole: String   // 该 Lens 的角色设定
    let sections: [SectionSpec]
    let keywords: [String]   // 本地推荐规则
}

struct Analysis: Codable, Identifiable {
    var id = UUID()
    let lensID: String
    let sections: [String: String]   // key -> 内容
    let createdAt: Date
}

enum AnalysisDepth: String, CaseIterable, Codable, Identifiable {  // 快速/平衡/深度
    case quick, balanced, deep
}
enum ResponseTone: String, CaseIterable, Codable, Identifiable {   // 简洁/教练/温暖
    case brief, coach, warm
}

@Model final class Record {
    var id: UUID
    var inputText: String
    var lensID: String
    var sectionsData: Data           // JSON 编码的 [String: String]
    var providerName: String
    var modelName: String
    var isFavorite: Bool
    var createdAt: Date
}
```

## 3. 三个 Lens 的精确定义

### Lens 1 — `decision-review` 决策复盘
- name: `决策复盘`；shortLabel: `决策`；icon: `signpost.right.and.left`
- systemRole: `你是一位冷静、结构化的决策分析助手。你不替用户做决定，而是帮他把这个决定本身看清楚。`
- sections:

  | key | title | icon | guidance |
  |---|---|---|---|
  | `key_considerations` | 关键考量 | `list.bullet.clipboard` | 这个决定真正相关的因素有哪些 |
  | `blind_spots` | 盲点 | `eye.slash` | 用户可能忽略的假设、信息或风险 |
  | `alternative_perspectives` | 替代视角 | `binoculars` | 同一处境还可以怎么看 |
  | `next_steps` | 下一步 | `arrow.forward.circle` | 哪些信息或行动能让决定更清晰 |
- keywords: `要不要, 该不该, 选择, 决定, 纠结, 利弊, 值不值, 方案, 还是, 取舍`

### Lens 2 — `writing-review` 写作复盘
- name: `写作复盘`；shortLabel: `写作`；icon: `pencil.and.ruler`
- systemRole: `你是一位严格但友好的文字编辑。你关注表达质量，不改变用户原本的观点。`
- sections:

  | key | title | icon | guidance |
  |---|---|---|---|
  | `clarity` | 清晰度 | `magnifyingglass` | 哪些地方含糊、有歧义 |
  | `structure` | 结构 | `list.number` | 论证是否连贯、层次是否清楚 |
  | `weak_points` | 薄弱点 | `exclamationmark.triangle` | 哪里空泛、重复或缺乏支撑 |
  | `revision_suggestions` | 修改建议 | `pencil` | 针对具体句子给出改进方向 |
  | `example_revision` | 改写示例 | `doc.text.magnifyingglass` | 给出一个更清楚的改写版本 |
- keywords: `写, 文章, 邮件, 文案, 文档, 报告, 草稿, 措辞, 表达, 润色, 修改`

### Lens 3 — `communication-review` 沟通复盘
- name: `沟通复盘`；shortLabel: `沟通`；icon: `bubble.left.and.bubble.right`
- systemRole: `你是一位沟通顾问。你帮用户预判：这段话发出去后，对方可能会怎么理解。`
- sections:

  | key | title | icon | guidance |
  |---|---|---|---|
  | `likely_interpretation` | 对方的可能理解 | `person.wave.2` | 对方大概率会怎么读这句话 |
  | `potential_misunderstandings` | 可能的误解 | `questionmark.bubble` | 哪些地方可能被理解成别的意思 |
  | `communication_risks` | 沟通风险 | `exclamationmark.bubble` | 哪些措辞会制造不必要的摩擦 |
  | `possible_responses` | 更精确的表达 | `text.bubble` | 如何把同样的意思说得更准 |
  | `reply_options` | 可能的后续回复 | `arrowshape.turn.up.left.2` | 对方若这样回，可以怎么接 |
- keywords: `回复, 沟通, 跟他说, 发消息, 老板, 同事, 客户, 朋友, 怎么开口, 吵架, 解释, 微信`

## 4. PromptBuilder 规范
- 输入：`lens`、`depth`、`tone`、`userInput`
- 输出（system prompt）动态拼接：
  1. `lens.systemRole`
  2. 逐条列出 `lens.sections`，每条格式：`- {title}（key: {key}）：{guidance}`
  3. 深度要求：quick = 每段 1-2 句；balanced = 2-3 句；deep = 3-5 句并可举例
  4. 语气要求：brief = 直接专业；coach = 引导式；warm = 先共情再给视角
  5. 严格输出格式（见下）
- user prompt：`用户的输入：\n{userInput}`
- **严格 JSON 输出要求**（写进 prompt）：
  ```
  只输出一个纯 JSON 对象，不要 markdown 代码块、不要任何解释或多余文字。
  键必须严格使用以下英文 key，值用中文：
  {"key_considerations": "...", "blind_spots": "...", ...}
  ```
- 禁止在 prompt 中出现任何 CBT / 心理治疗 / 认知扭曲 / 危机等字样

## 5. 响应解析规范
实现一个通用容错解析器 `parseSections(_ content: String, lens: AnalysisLens) -> [String: String]`：
1. 去掉 ```json / ``` 包裹并 trim
2. 截取第一个 `{` 到最后一个 `}`
3. `JSONDecoder` 解码 `[String: String]`，缺失的 key 补空字符串
4. 解码失败则用 `JSONSerialization` 取 `[String: Any]`，只保留 `String` 值，并尝试中英 key 兜底
5. 仍失败则按行拆分，按 `lens.sections` 顺序映射
6. 全部失败抛 `AIServiceError.parseError`

## 6. AI 服务层
- `AIServiceProtocol`：`func analyze(input: String, model: AIModel, lens: AnalysisLens, depth: AnalysisDepth, tone: ResponseTone) async throws -> Analysis`
- `AIServiceFactory.service(for: AIProvider)`
- 实现：`OpenAIService` / `AnthropicService` / `DeepSeekService` / `LocalAnalysisService`
- OpenAI：`/v1/chat/completions`，Bearer，system+user，temperature 0.7，max_tokens 1024
- Anthropic：`/v1/messages`，`x-api-key` + `anthropic-version: 2023-06-01`，system 单独字段
- DeepSeek：`/v1/chat/completions`；`deepseek-reasoner` 不吃 system role，需把 system 拼进 user，max_tokens 4096，不传 temperature，超时 120s；响应优先取 `content`，空则取 `reasoning_content`；余额不足单独报错
- 错误统一为 `AIServiceError`：`noAPIKey / invalidResponse / networkError / rateLimited / invalidKey / parseError`，映射 401→invalidKey、429→rateLimited
- 三个 provider 的请求构造与错误映射抽成 iOS 内部共享 helper（这是 iOS 内部复用，**不是跨端共享层**）

## 7. 本地离线模式
- `LocalAnalysisService` 为每个 lens 预置 2-3 条示例结果（内容必须贴合该 lens 语义，禁止任何 CBT/心理内容），按输入 hash 选取，加 0.4s 模拟延迟
- 无需 API Key，保证 onboarding 与审核场景可用

## 8. UI 规范（中文文案）
- 入口：`<AppName>App` → 未完成 onboarding 显示 `OnboardingView`，否则 `MainTabView`
- Onboarding 3 页：欢迎（说明「同一段输入，不同视角」）→ 选择 AI 服务商（含离线）+ 填 Key → 就绪
- 三个 Tab：`首页`（`house`）/ `历史`（`clock.arrow.circlepath`）/ `设置`（`gearshape`）
- 首页自上而下：问候语 → `InputCard`（通用 placeholder，如「粘贴或写下你想分析的内容…」）→ `LensPickerView`（3 个 lens 横排切换 + 推荐 chip）→ 分析按钮（显示当前 lens.shortLabel）→ 错误横幅 → `ResultCardView`
- `LensPickerView`：三格等宽，选中高亮，若 `suggestedLens != selected` 显示「推荐: {shortLabel}」chip，点击切换带轻触感
- `ResultCardView`：遍历 `lens.sections` 动态渲染，每段「图标 + 标题 + 内容」，用分隔线分隔
- 历史：`Record` 列表，显示 lens 名称 chip + 时间，展开显示各 section，收藏、搜索、按日期分组、本周统计、滑动删除
- 设置：AI 服务商 / API Key（Keychain）/ 模型 / 分析深度 / 回应语气 / 默认 Lens / 清除所有数据 / 关于
- 复用色板 token：`AccentColor`、`CardBackground`、`TextPrimary`、`TextSecondary`、`GradientStart`、`GradientEnd`，全部支持深色模式
- 交互：弹簧动画、`UIImpactFeedbackGenerator` 轻/中触感、成功通知触感
- 隐私锁：若要保留，必须用 `LocalAuthentication` 真正实现；否则**不要**出现任何 Face ID 开关（禁止死代码）

## 9. 工程规范
- 稳定英文 id 用作一切持久化 key：UserDefaults key、Keychain account、SwiftData 字段、JSON key；**禁止**用中文显示名或 enum rawValue 当 key
- Bundle ID：`com.henryliu.<appname>`；Keychain service：`com.henryliu.<appname>.apikeys`
- 日志前缀统一为 `[<AppName>]`
- 禁止出现：`cbt`、`认知`、`扭曲`、`危机`、`热线`、`心情`、`reframe`、`心理`、`治疗`、`thought`（作为领域概念）
- 无死代码、无 TODO 占位、无注释（除非必要）

## 10. 目标文件结构
```
<AppName>/
├── <AppName>App.swift
├── Models/
│   ├── AnalysisLens.swift        # 3 个 lens 定义 + suggest 推荐
│   ├── SectionSpec.swift
│   ├── Analysis.swift
│   ├── AnalysisDepth.swift       # AnalysisDepth + ResponseTone
│   ├── AIProvider.swift          # provider / model / baseURL
│   └── Record.swift
├── Services/
│   ├── AIServiceProtocol.swift   # 协议 + 工厂 + AIServiceError + 共享请求 helper
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
├── Views/
│   ├── HomeView.swift
│   ├── ResultCardView.swift
│   ├── HistoryView.swift
│   ├── SettingsView.swift
│   ├── OnboardingView.swift
│   └── Components/
│       ├── InputCard.swift
│       ├── LensPickerView.swift
│       └── ErrorBannerView.swift
└── Assets.xcassets/              # 色板 + 新 AppIcon
```

## 11. 执行顺序
1. 在 `/Users/henry/Documents/Lens` 新建 Xcode 工程 `<AppName>`（iOS App / SwiftUI / SwiftData），配置 bundle id 与部署目标 17.0
2. 建 Models 与 3 个 Lens 定义
3. 建 Services：协议/工厂 → 3 个 provider → PromptBuilder → 解析器 → LocalAnalysisService → KeychainManager
4. 建 ViewModels
5. 建 Views 与 Components，接通全流程
6. 配色板、AppIcon、onboarding、README
7. 编译并冒烟测试

## 12. 验收标准
- [ ] 工程编译通过，无阻塞性警告
- [ ] 全局搜索无：`cbt`、`认知`、`扭曲`、`危机`、`热线`、`心情`、`reframe`、`心理`、`治疗`
- [ ] 仓库无 Android / shared / common / Gradle 痕迹，无第三方依赖
- [ ] 全流程可用：onboarding → 选 provider → 输入 → 选/推荐 lens → 分析 → 结果 → 历史 → 收藏
- [ ] 离线模式可用；未填 Key 时给出明确错误而非崩溃
- [ ] 3 个 lens 可切换，且同一段输入返回的 section 结构与内容明显不同
- [ ] 结果 JSON 解析对带 markdown、缺 key、中英 key 的响应都能容错
- [ ] 重启 App 后历史、收藏、设置、Key 均保留
- [ ] 无死代码（尤其未接入 LocalAuthentication 的隐私开关）

## 13. 明确非目标
- 不做聊天/对话式交互，只做「一次输入 → 结构化分析」
- 不做账号、云同步、后端
- 不做 Android / 跨平台 / 共享层
- 不做心理健康、情绪、危机干预相关内容
