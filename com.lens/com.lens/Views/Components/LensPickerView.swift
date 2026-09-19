import SwiftUI

struct LensPickerView: View {
    let selected: AnalysisLens
    let suggested: AnalysisLens?
    let onSelect: (AnalysisLens) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("分析视角")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("TextPrimary"))

                Spacer()

                if let suggested {
                    Button {
                        onSelect(suggested)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                            Text("推荐: \(suggested.shortLabel)")
                        }
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }

            HStack(spacing: 10) {
                ForEach(AnalysisLens.all) { lens in
                    lensButton(lens)
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: suggested)
    }

    private func lensButton(_ lens: AnalysisLens) -> some View {
        let isSelected = lens == selected

        return Button {
            onSelect(lens)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: lens.icon)
                    .font(.title3)
                Text(lens.shortLabel)
                    .font(.caption.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.16) : Color("CardBackground"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color("TextSecondary").opacity(0.15), lineWidth: isSelected ? 1.5 : 1)
            )
            .foregroundStyle(isSelected ? Color.accentColor : Color("TextSecondary"))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}
