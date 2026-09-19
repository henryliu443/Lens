import SwiftUI

struct InputCard: View {
    @Binding var text: String
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var editorHeight: CGFloat {
        sizeClass == .regular ? 220 : 150
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.pencil")
                    .foregroundStyle(Color.accentColor)
                Text("输入内容")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("TextPrimary"))
                Spacer()
                if !text.isEmpty {
                    Text("\(text.count) 字")
                        .font(.caption)
                        .foregroundStyle(Color("TextSecondary"))
                }
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("粘贴或写下你想分析的内容…")
                        .foregroundStyle(Color("TextSecondary"))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                TextEditor(text: $text)
                    .frame(minHeight: editorHeight)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(Color("TextPrimary"))
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color("TextSecondary").opacity(0.12), lineWidth: 1)
        )
    }
}
