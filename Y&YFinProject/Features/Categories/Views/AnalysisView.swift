import SwiftUI

struct AnalysisView: View {
    @State private var searchText = ""
    @State private var categories: [TransactionCategory] = []
    @State private var isLoading = false
    @State private var error: Error?
    
    private let categoriesService = CategoriesService()
    
    private var filteredCategories: [TransactionCategory] {
        if searchText.isEmpty {
            return categories
        } else {
            
            return categories
                .map { (category: $0, match: $0.name.fuzzyMatchWithWeight(query: searchText)) }
                .filter { $0.match.weight > 0 }
                .sorted { $0.match.weight > $1.match.weight }
                .map { $0.category }
        }
    }
    
    var body: some View {
        ScreenContainer(title: "Мои статьи") {
            VStack(spacing: 10) {
                //поисковая строка
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                Spacer()
                //заголовок
                HStack {
                    Text("СТАТЬИ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                
                //список категорий
                if isLoading {
                    ProgressView()
                } else if let error = error {
                    Text("Ошибка: \(error.localizedDescription)")
                } else {
                    VStack(spacing: 0) {
                        ForEach(filteredCategories.indices, id: \.self) { index in
                            VStack(spacing: 0) {
                                CategoryRow(category: filteredCategories[index])
                                    if index != filteredCategories.count - 1 {
                                        Divider()
                                            .padding(.leading, 56) //линия под названием статьи
                                }
                            }
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .task {
            await loadCategories()
        }
    }
    
    private func loadCategories() async {
        isLoading = true
        do {
            categories = try await categoriesService.categories()
        } catch {
            self.error = error
        }
        isLoading = false
    }
}

struct CategoryRow: View {
    let category: TransactionCategory
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color("Accent").opacity(0.15))
                .frame(width: 30, height: 30)
                .overlay(
                    Text(String(category.emoji))
                        .font(.system(size: 15))
                )
            
            Text(category.name)
                .font(.body)
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .frame(height: 50)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search", text: $text)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .foregroundColor(.gray)
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                Button(action: {}) {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(8)
            .background(Color(.systemGray5))
            .cornerRadius(10)
            
        }
    }
}

#Preview {
    AnalysisView()
}
