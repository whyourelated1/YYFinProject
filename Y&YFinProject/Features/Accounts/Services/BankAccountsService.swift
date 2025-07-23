import Foundation

final class BankAccountsService {
    private let client: NetworkClient
    private let localStore: BankAccountsLocalStore?

    init(client: NetworkClient, localStore: BankAccountsLocalStore? = nil) {
        self.client = client
        self.localStore = localStore
    }

    func getAccount() async throws -> BankAccount {
        do {
            let accounts: [BankAccount] = try await client.request(
                path: "accounts",
                method: "GET",
                body: Optional<EmptyRequest>.none
            )
            try await localStore?.saveAll(accounts)

            guard let first = accounts.first else {
                throw NSError(domain: "BankAccountsService", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "У пользователя нет ни одного счёта"
                ])
            }
            return first
        } catch {
            guard let localAccounts = try await localStore?.getAll(), let first = localAccounts.first else {
                throw error
            }
            return first
        }
    }

    func getAccount(withId id: Int) async throws -> BankAccount {
        do {
            let accounts: [BankAccount] = try await client.request(
                path: "accounts",
                method: "GET",
                body: Optional<EmptyRequest>.none
            )
            try await localStore?.saveAll(accounts)

            guard let account = accounts.first(where: { $0.id == id }) else {
                throw NSError(domain: "BankAccountsService", code: 404, userInfo: [
                    NSLocalizedDescriptionKey: "Счёт с id \(id) не найден"
                ])
            }
            return account
        } catch {
            guard let localAccount = try await localStore?.getAll().first(where: { $0.id == id }) else {
                throw error
            }
            return localAccount
        }
    }

    func updateAccount(id: Int, name: String, balance: Decimal, currency: String) async throws -> BankAccount {
        struct UpdateRequest: Encodable {
            let name: String
            let balance: String
            let currency: String
        }

        let body = UpdateRequest(
            name: name,
            balance: "\(balance)",
            currency: currency
        )

        let updated: BankAccount = try await client.request(
            path: "accounts/\(id)",
            method: "PUT",
            body: body
        )

        try await localStore?.saveAll([updated])
        return updated
    }
}
