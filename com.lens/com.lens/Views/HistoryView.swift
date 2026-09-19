import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Record.createdAt, order: .reverse) private var records: [Record]
    @State private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ContentUnavailableView(
                        "还没有记录",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("在首页完成一次分析后，结果会出现在这里")
                    )
                } else {
                    listContent
                }
            }
            .navigationTitle("历史")
            .searchable(text: $viewModel.searchText, prompt: "搜索输入或结果")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            viewModel.favoritesOnly.toggle()
                        }
                    } label: {
                        Image(systemName: viewModel.favoritesOnly ? "star.fill" : "star")
                    }
                    .tint(Color.accentColor)
                }
            }
        }
    }

    private var listContent: some View {
        List {
            statsSection

            ForEach(viewModel.grouped(records), id: \.title) { group in
                Section(group.title) {
                    ForEach(group.records) { record in
                        RecordRow(record: record)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.delete(record, context: context)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    viewModel.toggleFavorite(record, context: context)
                                } label: {
                                    Label(
                                        record.isFavorite ? "取消收藏" : "收藏",
                                        systemImage: record.isFavorite ? "star.slash" : "star"
                                    )
                                }
                                .tint(.yellow)
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var statsSection: some View {
        let stats = viewModel.weeklyStats(records)

        return Section {
            HStack {
                statItem(title: "本周分析", value: stats.count)
                Divider()
                statItem(title: "本周收藏", value: stats.favorites)
            }
            .padding(.vertical, 4)
            .listRowBackground(Color("CardBackground"))
        }
    }

    private func statItem(title: String, value: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.accentColor)
            Text(title)
                .font(.caption)
                .foregroundStyle(Color("TextSecondary"))
        }
        .frame(maxWidth: .infinity)
    }
}

struct RecordRow: View {
    let record: Record
    @State private var expanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(record.lens.sections) { section in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: section.icon)
                                .font(.caption)
                            Text(section.title)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(Color.accentColor)

                        Text(record.sections[section.key] ?? "（无内容）")
                            .font(.footnote)
                            .foregroundStyle(Color("TextPrimary"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.vertical, 6)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Label(record.lens.name, systemImage: record.lens.icon)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.14))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())

                    if record.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }

                    Spacer()

                    Text(record.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(Color("TextSecondary"))
                }

                Text(record.inputText)
                    .font(.subheadline)
                    .foregroundStyle(Color("TextPrimary"))
                    .lineLimit(expanded ? nil : 2)
            }
        }
        .tint(Color("TextSecondary"))
    }
}
