import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.secondary)

            Text("По вашему запросу ничего нет")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
}

