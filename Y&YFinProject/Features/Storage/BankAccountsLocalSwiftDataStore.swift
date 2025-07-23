import Foundation
import SwiftData

@MainActor
final class BankAccountsLocalSwiftDataStore: BankAccountsLocalStore {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func saveAll(_ accounts: [BankAccount]) async throws {
        let ctx = container.mainContext

        for acc in accounts {
            let desc = FetchDescriptor<AccountEntity>(
                predicate: #Predicate { $0.id == acc.id }
            )

            if let entity = try ctx.fetch(desc).first {
                entity.name     = acc.name
                entity.balance  = acc.balance
                entity.currency = acc.currency
            } else {
                ctx.insert(
                    AccountEntity(id: acc.id, name: acc.name, balance: acc.balance, currency: acc.currency)
                )
            }
        }
        try ctx.save()
    }


    func getAll() async throws -> [BankAccount] {
        let context = container.mainContext
        let entities = try context.fetch(FetchDescriptor<AccountEntity>())

        let accounts: [BankAccount] = entities.map { entity in
            BankAccount(
                id: entity.id,
                name: entity.name,
                balance: entity.balance,
                currency: entity.currency
            )
        }

        return accounts
    }
    
    func apply(delta: Decimal, to accountId: Int) async throws {
        let ctx = container.mainContext
        let desc = FetchDescriptor<AccountEntity>(predicate: #Predicate { $0.id == accountId })
        guard let entity = try ctx.fetch(desc).first else { return }
        entity.balance += delta
        try ctx.save()
    }

}
