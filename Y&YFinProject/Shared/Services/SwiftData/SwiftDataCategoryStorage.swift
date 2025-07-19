import Foundation
import SwiftData

enum CategoryError: Error {
    case notFound
    case duplicateId([Int])
    case storageError(Error)
}

actor SwiftDataCategoryStorage {
    private let context: ModelContext
    
    init(modelContainer: ModelContainer) {
        self.context = ModelContext(modelContainer)
        self.context.autosaveEnabled = false
    }
    
    func saveCategories(_ categories: [TransactionCategory]) async throws -> [TransactionCategory] {
        try await performSave(categories)
        return try await fetchAllCategories()
    }
    
    func fetchAllCategories() async throws -> [TransactionCategory] {
        try performFetchAll()
    }
    
    func clearAllCategories() async throws {
        try performClear()
    }
    
    // MARK: - Private methods
    
    private func performSave(_ categories: [TransactionCategory]) async throws {
        let existing = try context.fetch(FetchDescriptor<CategoryStorage>())

        for category in categories {
            if let existingCategory = existing.first(where: { $0.id == category.id }) {
                existingCategory.name = category.name
                existingCategory.emoji = String(category.emoji)
                existingCategory.isIncome = category.isIncome
            } else {
                context.insert(CategoryStorage(from: category))
            }
        }
        
        try context.save()
    }

    
    private func performFetchAll() throws -> [TransactionCategory] {
        let descriptor = FetchDescriptor<CategoryStorage>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }
    
    private func performClear() throws {
        try context.delete(model: CategoryStorage.self)
        try context.save()
    }
}

extension CategoryStorage {
    convenience init(from category: TransactionCategory) {
        self.init(
            id: category.id,
            emoji: category.emoji,
            name: category.name,
            isIncome: category.isIncome
        )
    }
}
