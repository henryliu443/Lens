import SwiftUI

struct ResultCardView: View {
    let analysis: Analysis

    private var lens: AnalysisLens {
        AnalysisLens.lens(for: analysis.lensID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            ForEach(lens.sections) { section in
                Divider()
                    .padding(.horizontal, 16)
                sectionView(section)
            }
        }
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color("TextSecondary").opacity(0.12), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: lens.icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(lens.name)
                    .font(.headline)
                    .foregroundStyle(Color("TextPrimary"))
                Text(analysis.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(Color("TextSecondary"))
            }

            Spacer()
        }
        .padding(16)
    }

    private func sectionView(_ section: SectionSpec) -> some View {
        let content = analysis.sections[section.key] ?? ""

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: section.icon)
                    .foregroundStyle(Color.accentColor)
                Text(section.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("TextPrimary"))
            }

            Text(content.isEmpty ? "（无内容）" : content)
                .font(.body)
                .foregroundStyle(content.isEmpty ? Color("TextSecondary") : Color("TextPrimary"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }
}
