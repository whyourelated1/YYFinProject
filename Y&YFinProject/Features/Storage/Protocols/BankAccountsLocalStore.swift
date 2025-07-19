import Foundation

protocol BankAccountsLocalStore {
    func saveAll(_ accounts: [BankAccount]) async throws
    func getAll() async throws -> [BankAccount]
    func apply(delta: Decimal, to accountId: Int) async throws
}
