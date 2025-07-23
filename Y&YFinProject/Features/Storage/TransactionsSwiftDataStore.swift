import Foundation
import SwiftData

@MainActor
final class TransactionsSwiftDataStore: TransactionsLocalStore {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func getAll() async throws -> [Transaction] {
        let context = container.mainContext
        let entities = try context.fetch(FetchDescriptor<TransactionEntity>())
        return entities.map { $0.toTransaction() }
    }

    func get(by id: Int) async throws -> Transaction? {
        let context = container.mainContext
        let descriptor = FetchDescriptor<TransactionEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first?.toTransaction()
    }

    func create(_ transaction: Transaction) async throws {
        let context = container.mainContext

        let accountDescriptor = FetchDescriptor<AccountEntity>(
            predicate: #Predicate { $0.id == transaction.account.id }
        )
        let account: AccountEntity
        if let existing = try context.fetch(accountDescriptor).first {
            account = existing
        } else {
            let new = AccountEntity(
                id: transaction.account.id,
                name: transaction.account.name,
                balance: transaction.account.balance,
                currency: transaction.account.currency
            )
            context.insert(new)
            account = new
        }

        let categoryDescriptor = FetchDescriptor<CategoryEntity>(
            predicate: #Predicate { $0.id == transaction.category.id }
        )
        let category: CategoryEntity
        if let existing = try context.fetch(categoryDescriptor).first {
            category = existing
        } else {
            let new = CategoryEntity(
                id: transaction.category.id,
                name: transaction.category.name,
                emoji: String(transaction.category.emoji),
                direction: transaction.category.isIncome
            )
            context.insert(new)
            category = new
        }

        let entity = TransactionEntity(
            id: transaction.id,
            account: account,
            category: category,
            amount: transaction.amount,
            transactionDate: transaction.transactionDate,
            comment: transaction.comment ?? "",
            createdAt: transaction.createdAt,
            updatedAt: transaction.updatedAt
        )

        context.insert(entity)
        try context.save()
    }

    
    func update(_ transaction: Transaction) async throws {
        let context    = container.mainContext
        let descriptor = FetchDescriptor<TransactionEntity>(
            predicate: #Predicate { $0.id == transaction.id }
        )

        guard let entity = try context.fetch(descriptor).first else {
            try await create(transaction)
            return
        }

        entity.amount = transaction.amount
        entity.transactionDate = transaction.transactionDate
        entity.comment = transaction.comment ?? ""
        entity.updatedAt = transaction.updatedAt
        entity.createdAt = transaction.createdAt

        try context.save()
    }

    func delete(by id: Int) async throws {
        let context    = container.mainContext
        let descriptor = FetchDescriptor<TransactionEntity>(
            predicate: #Predicate { $0.id == id }
        )

        if let entity = try context.fetch(descriptor).first {
            context.delete(entity)
            try context.save()
        }
    }

    func replaceAll(_ transactions: [Transaction]) async throws {
        try await deleteAll()
        for tx in transactions {
            try await create(tx)
        }
    }

    private func deleteAll() async throws {
        let context = container.mainContext
        let all = try context.fetch(FetchDescriptor<TransactionEntity>())
        for tx in all {
            context.delete(tx)
        }
        try context.save()
    }
}
