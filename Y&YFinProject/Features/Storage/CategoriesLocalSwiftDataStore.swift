import Foundation
import SwiftData

@MainActor
final class CategoriesLocalSwiftDataStore: CategoriesLocalStore {
    private let container: ModelContainer

    init(container: ModelContainer) { self.container = container }

    func saveAll(_ categories: [Category]) async throws {
        let ctx = container.mainContext

        for cat in categories {
            let desc = FetchDescriptor<CategoryEntity>(
                predicate: #Predicate { $0.id == cat.id }
            )
            if let e = try ctx.fetch(desc).first {
                e.name      = cat.name
                e.emoji     = String(cat.emoji)
                e.direction = cat.isIncome
            } else {
                ctx.insert(
                    CategoryEntity(id: cat.id,
                                   name: cat.name,
                                   emoji: String(cat.emoji),
                                   direction: cat.isIncome)
                )
            }
        }
        try ctx.save()
    }

    func getAll() async throws -> [Category] {
        let ctx = container.mainContext
        let entities = try ctx.fetch(FetchDescriptor<CategoryEntity>())
        return entities.map { $0.toModel() }
    }
}
