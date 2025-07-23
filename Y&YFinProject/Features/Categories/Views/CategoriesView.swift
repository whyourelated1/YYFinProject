import SwiftUI
import SwiftData

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
            VStack(alignment: .leading, spacing: 16) {
                Text("Мои статьи")
                    .font(.largeTitle.bold())
                    .padding(.top, 40)
                    .padding(.horizontal, 16)

                SearchBar(text: $vm.searchText)
                    .padding(.horizontal, 16)

                Text("СТАТЬИ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)

                if filtered.isEmpty {
                    EmptyStateView()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filtered) { cat in
                                CategoryRow(category: cat)

                                if cat.id != filtered.last?.id {
                                    Divider()
                                        .padding(.leading, 32 + 12)
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                    }
                }

                Spacer(minLength: 16)
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
}

private struct CategoryRow: View {
    let category: Category

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(Text(String(category.emoji)))

            Text(category.name)
                .font(.body)
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}
