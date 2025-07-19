import Foundation
import SwiftData

@MainActor
final class TransactionsBackupStore {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func getAll() async throws -> [TransactionBackupModel] {
        try container.mainContext.fetch(FetchDescriptor<TransactionBackupModel>())
    }

    func get(by id: Int) async throws -> TransactionBackupModel? {
        let descriptor = FetchDescriptor<TransactionBackupModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try container.mainContext.fetch(descriptor).first
    }

    func addOrReplace(_ backup: TransactionBackupModel) async throws {
        let context = container.mainContext

        if let existing = try await get(by: backup.id) {
            context.delete(existing)
        }

        context.insert(backup)
        try context.save()
    }

    func delete(by id: Int) async throws {
        let context = container.mainContext
        if let existing = try await get(by: id) {
            context.delete(existing)
            try context.save()
        }
    }

    func delete(_ backup: TransactionBackupModel) async throws {
        let context = container.mainContext
        context.delete(backup)
        try context.save()
    }
    
    func save(_ backup: TransactionBackupModel) async throws {
        try await addOrReplace(backup)
    }


    func deleteAll() async throws {
        let context = container.mainContext
        let all = try await getAll()
        for item in all {
            context.delete(item)
        }
        try context.save()
    }
}
