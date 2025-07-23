import Foundation
import Combine
import SwiftData

@MainActor
final class CategoriesViewModel: ObservableObject {

    @Published var categories: [Category] = []
    @Published var searchText: String = ""
    @Published var error: Error?

    private let service: CategoriesService
    private let modelContext: ModelContext

    init(client: NetworkClient, modelContainer: ModelContainer) {
        self.service = CategoriesService(client: client)
        self.modelContext = ModelContext(modelContainer)
        Task { await load() }
    }

    func load() async {
        do {
            let result = try await service.all()
            categories = result
            try? await saveToLocal(result)
        } catch {
            self.error = error
            print("Ошибка загрузки категорий: \(error.localizedDescription)")
            do {
                let fetchDescriptor = FetchDescriptor<CategoryEntity>(
                    sortBy: [SortDescriptor(\.name)]
                )
                let localEntities = try modelContext.fetch(fetchDescriptor)
                categories = localEntities.map { entity in
                    Category(
                        id: entity.id,
                        name: entity.name,
                        emoji: Character(entity.emoji),
                        isIncome: entity.direction
                    )
                }
                print("Загружено \(categories.count) категорий из локального хранилища")
            } catch {
                print("Ошибка загрузки локальных категорий: \(error.localizedDescription)")
            }
        }
    }

    var filteredCategories: [Category] {
        guard !searchText.isEmpty else { return categories }

        let pattern = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let scored = categories.compactMap { cat -> (Category, Int)? in
            let score = fuzzyScore(source: cat.name.lowercased(), pattern: pattern)
            return score == .min ? nil : (cat, score)
        }

        return scored
            .sorted { lhs, rhs in
                lhs.1 == rhs.1 ? lhs.0.name < rhs.0.name : lhs.1 > rhs.1
            }
            .map(\.0)
    }

    private func saveToLocal(_ categories: [Category]) async throws {
        for cat in categories {
            let fetchDescriptor = FetchDescriptor<CategoryEntity>(
                predicate: #Predicate { $0.id == cat.id },
                sortBy: []
            )
            let existing = try modelContext.fetch(fetchDescriptor)

            guard existing.isEmpty else { continue }

            let entity = CategoryEntity(
                id: cat.id,
                name: cat.name,
                emoji: String(cat.emoji),
                direction: cat.isIncome
            )
            modelContext.insert(entity)
        }

        try modelContext.save()
    }

}

private func fuzzyScore(source: String, pattern: String) -> Int {
    var srcIdx = source.startIndex
    var patIdx = pattern.startIndex
    var score = 0
    var lastHit = source.startIndex

    while patIdx < pattern.endIndex, srcIdx < source.endIndex {
        if source[srcIdx] == pattern[patIdx] {
            let gap = source.distance(from: lastHit, to: srcIdx)
            score += 1 - gap
            lastHit = srcIdx
            patIdx = pattern.index(after: patIdx)
        }
        srcIdx = source.index(after: srcIdx)
    }

    return patIdx == pattern.endIndex ? score : .min
}

