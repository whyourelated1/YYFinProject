import SwiftUI
import SwiftData
import SwiftUI

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search", text: $text)
                .disableAutocorrection(true)
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(10)
    }
}

private enum Constants {
    static let navHPad: CGFloat = 16
    static let vSpace: CGFloat = 16
    static let titleHPad: CGFloat = 16
    static let topOffset: CGFloat = 40
    static let cardCorner: CGFloat = 12
    static let cellVPad: CGFloat = 8
    static let cellHPad: CGFloat = 12
    static let icon: CGFloat = 32
}

struct CategoriesView: View {
    let client: NetworkClient
    let modelContainer: ModelContainer

    @StateObject private var vm: CategoriesViewModel
    private var filtered: [Category] { vm.filteredCategories }

    init(client: NetworkClient, modelContainer: ModelContainer) {
        self.client = client
        self.modelContainer = modelContainer
        _vm = StateObject(wrappedValue: CategoriesViewModel(client: client, modelContainer: modelContainer))
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: Constants.vSpace) {
                Text("Мои статьи")
                    .font(.largeTitle.bold())
                    .padding(.top, Constants.topOffset)
                    .padding(.horizontal, Constants.titleHPad)

                SearchBar(text: $vm.searchText)
                    .padding(.horizontal, Constants.titleHPad)

                Text("СТАТЬИ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, Constants.titleHPad)

                if filtered.isEmpty {
                    EmptyStateView()
                        .frame(maxWidth: .infinity)
                        .background(cardBackground)
                        .cornerRadius(Constants.cardCorner)
                        .padding(.horizontal, Constants.navHPad)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filtered) { cat in
                                CategoryRow(category: cat)

                                if cat.id != filtered.last?.id {
                                    Divider()
                                        .padding(.leading, Constants.icon + Constants.cellHPad)
                                }
                            }
                        }
                        .background(cardBackground)
                        .cornerRadius(Constants.cardCorner)
                        .padding(.horizontal, Constants.navHPad)
                    }
                }

                Spacer(minLength: Constants.vSpace)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .alert("Ошибка", isPresented: Binding(get: {
                vm.error != nil
            }, set: { _ in
                vm.error = nil
            })) {
                Button("Ок", role: .cancel) {}
            } message: {
                Text(vm.error?.localizedDescription ?? "Неизвестная ошибка")
            }
        }
    }

    private var cardBackground: some View {
        Color(.systemBackground)
    }
}

private struct CategoryRow: View {
    let category: Category
    var body: some View {
        HStack(spacing: Constants.cellHPad) {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: Constants.icon, height: Constants.icon)
                .overlay(Text(String(category.emoji)))

            Text(category.name).font(.body)
            Spacer()
        }
        .padding(.vertical, Constants.cellVPad)
        .padding(.horizontal, Constants.cellHPad)
    }
}

