import SwiftUI

struct ScreenContainer<Content: View>: View {
    let title: String
    let content: Content

    init(
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    //заголовок
                    HStack {
                        Text(title)
                            .font(.title)
                            .bold()
                            .padding(.horizontal)
                        Spacer()
                    }
                    .padding(.top)
                    Spacer().frame(height: 8)
                    content
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

