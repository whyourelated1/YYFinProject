import Foundation

@MainActor
final class TransactionsService {

    let client: NetworkClient
    private let fileCache = TransactionsFileCache()
    private let fileURL:  URL

    private let localStore:    TransactionsLocalStore?
    private let backupStore:   TransactionsBackupStore?
    private let accountsLocalStore:  BankAccountsLocalStore?
    private let accountsBackupStore: AccountBalanceBackupStore?
    private let categoriesLocalStore: CategoriesLocalStore?

    init(
        client: NetworkClient,
        localStore: TransactionsLocalStore? = nil,
        backupStore: TransactionsBackupStore? = nil,
        accountsStore: BankAccountsLocalStore? = nil,
        accBackupStore: AccountBalanceBackupStore? = nil,
        categoriesStore: CategoriesLocalStore? = nil,
        fileName: String = "transactions"
    ) {
        self.client               = client
        self.localStore           = localStore
        self.backupStore          = backupStore
        self.accountsLocalStore   = accountsStore
        self.accountsBackupStore  = accBackupStore
        self.categoriesLocalStore = categoriesStore

        self.fileURL = TransactionsFileCache.defaultFileURL(fileName: fileName)
        try? fileCache.load(from: fileURL)
    }

    // MARK: Cache helpers
    var cachedTransactions: [Transaction] { fileCache.transactions }
    func refreshFromCache() { try? fileCache.load(from: fileURL) }

    func getTransactions(
        forAccount accId: Int,
        from start: Date,
        to end: Date
    ) async throws -> [Transaction] {

        try await syncBackupWithRemote()

        let path = "transactions/account/\(accId)/period"
        let q    = DateFormatter.yyyyMMddQuery(start: start, end: end)

        do {
            let remote: [Transaction] = try await client.request(
                path: path, method: "GET",
                body: Optional<EmptyRequest>.none,
                queryItems: q
            )
            fileCache.replaceAll(remote)
            try? fileCache.save(to: fileURL)
            try? await localStore?.replaceAll(remote)
            return remote
        } catch {
            let local  = try await localStore?.getAll() ?? []
            let backup = try await backupStore?.getAll().map { $0.transaction } ?? []
            return Self.dedup(local + backup).filter {
                $0.account.id == accId &&
                $0.transactionDate >= start &&
                $0.transactionDate <= end
            }
        }
    }

    func createTransaction(_ body: TransactionRequestBody) async throws -> Transaction {
        do {
            let resp: TransactionResponseBody = try await client.request(
                path: "transactions", method: "POST", body: body
            )
            let tx = try await mapResponse(resp)

            try? await localStore?.create(tx)
            try? await accountsLocalStore?.apply(delta: tx.signedAmount, to: tx.account.id)
            try? await backupStore?.delete(by: tx.id)
            return tx

        } catch {
            let tempId   = Int(Date().timeIntervalSince1970 * -1)
            let dummyTx  = await makeOfflineStub(id: tempId, from: body)

            try? await localStore?.create(dummyTx)
            try? await backupStore?.save(
                TransactionBackupModel(id: tempId, action: .create, transaction: dummyTx)
            )
            try? await accountsLocalStore?.apply(delta: dummyTx.signedAmount, to: body.accountId)
            try? await accountsBackupStore?.add(
                AccountBalanceBackupModel(accountId: body.accountId,
                                          delta: dummyTx.signedAmount)
            )
            return dummyTx
        }
    }

    func updateTransaction(id: Int, with body: TransactionRequestBody) async throws -> Transaction {
        let oldTx = try await localStore?.get(by: id)

        do {
            let new: Transaction = try await client.request(
                path: "transactions/\(id)", method: "PUT", body: body
            )

            let delta = new.signedAmount - (oldTx?.signedAmount ?? 0)
            try? await accountsLocalStore?.apply(delta: delta, to: body.accountId)

            try? await localStore?.update(new)
            try? await backupStore?.delete(by: id)
            return new

        } catch {
            let dummyTx = await makeOfflineStub(id: id, from: body)

            let delta = dummyTx.signedAmount - (oldTx?.signedAmount ?? 0)
            try? await accountsLocalStore?.apply(delta: delta, to: body.accountId)
            try? await accountsBackupStore?.add(
                AccountBalanceBackupModel(accountId: body.accountId, delta: delta)
            )

            try? await localStore?.update(dummyTx)
            try? await backupStore?.save(
                TransactionBackupModel(id: id, action: .update, transaction: dummyTx)
            )
            return dummyTx
        }
    }

    func deleteTransaction(id: Int) async throws {
        let oldTx = try await localStore?.get(by: id)

        do {
            try await client.request(
                path: "transactions/\(id)", method: "DELETE", body: EmptyRequest()
            ) as Void

            if let oldTx {
                try? await accountsLocalStore?.apply(delta: -oldTx.signedAmount,
                                                     to: oldTx.account.id)
            }
            try? await localStore?.delete(by: id)
            try? await backupStore?.delete(by: id)

        } catch {
            if let oldTx {
                try? await accountsLocalStore?.apply(delta: -oldTx.signedAmount,
                                                     to: oldTx.account.id)
                try? await accountsBackupStore?.add(
                    AccountBalanceBackupModel(accountId: oldTx.account.id,
                                              delta: -oldTx.signedAmount)
                )
            }
            let stub = Transaction(id: id, account: .test, category: .test,
                                   amount: 0, transactionDate: Date(),
                                   comment: nil, createdAt: Date(), updatedAt: Date())
            try? await backupStore?.save(
                TransactionBackupModel(id: id, action: .delete, transaction: stub)
            )
            try? await localStore?.delete(by: id)
            throw error
        }
    }

    private func makeOfflineStub(
        id: Int,
        from body: TransactionRequestBody
    ) async -> Transaction {
        var isIncome = false
        if let cats = try? await categoriesLocalStore?.getAll(),
           let cat  = cats.first(where: { $0.id == body.categoryId }) {
            isIncome = cat.isIncome
        }

        let stubAccount = BankAccount(
            id: body.accountId,
            name: "Offline",
            balance: 0,
            currency: ""
        )
        let stubCategory = Category(
            id: body.categoryId,
            name: "Offline",
            emoji: "❓",
            isIncome: isIncome
        )

        return Transaction(
            id: id,
            account: stubAccount,
            category: stubCategory,
            amount: Decimal(string: body.amount,
                            locale: Locale(identifier: "en_US_POSIX")) ?? 0,
            transactionDate: ISO8601DateFormatter()
                .date(from: body.transactionDate) ?? Date(),
            comment: body.comment,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func mapResponse(_ r: TransactionResponseBody) async throws -> Transaction {
        let acc = try await BankAccountsService(client: client).getAccount(withId: r.accountId)
        let cat = try await CategoriesService(client: client).getCategory(withId: r.categoryId)
        let fmt = ISO8601DateFormatter()

        return Transaction(
            id: r.id,
            account: acc,
            category: cat,
            amount: Decimal(string: r.amount) ?? 0,
            transactionDate: fmt.date(from: r.transactionDate) ?? Date(),
            comment: r.comment,
            createdAt: fmt.date(from: r.createdAt) ?? Date(),
            updatedAt: fmt.date(from: r.updatedAt) ?? Date()
        )
    }

    private func syncBackupWithRemote() async throws {
        guard let backupStore else { return }

        for backup in try await backupStore.getAll() {
            do {
                switch backup.action {
                case .create:
                    let oldId = backup.transaction.id
                    try? await localStore?.delete(by: oldId)
                    fileCache.remove(withId: oldId); try? fileCache.save(to: fileURL)

                    let resp: TransactionResponseBody = try await client.request(
                        path: "transactions",
                        method: "POST",
                        body: TransactionRequestBody(from: backup.transaction)
                    )
                    let newTx = try await mapResponse(resp)
                    try? await localStore?.create(newTx)
                    try? await accountsLocalStore?.apply(delta: newTx.signedAmount,
                                                         to: newTx.account.id)

                case .update:
                    _ = try await updateTransaction(
                        id: backup.transaction.id,
                        with: TransactionRequestBody(from: backup.transaction)
                    )
                case .delete:
                    try await deleteTransaction(id: backup.transaction.id)
                case .balance:
                    break
                }
                try? await backupStore.delete(backup)
            } catch {
                print("Tx sync fail \(backup.id): \(error)")
            }
        }

        for bal in try await accountsBackupStore?.all() ?? [] {
            do {
                if let acc = try await accountsLocalStore?.getAll()
                    .first(where: { $0.id == bal.accountId }) {

                    struct Patch: Encodable {
                        let name: String
                        let balance: String
                        let currency: String
                    }
                    _ = try await client.request(
                        path: "accounts/\(acc.id)",
                        method: "PUT",
                        body: Patch(name: acc.name,
                                    balance: "\(acc.balance)",
                                    currency: acc.currency)
                    ) as BankAccount
                    try? await accountsBackupStore?.delete(bal)
                }
            } catch { print("Balance sync fail \(bal.accountId): \(error)") }
        }
    }

    private static func dedup(_ array: [Transaction]) -> [Transaction] {
        Dictionary(grouping: array, by: \.id)
            .values
            .compactMap { $0.max(by: { $0.updatedAt < $1.updatedAt }) } // берём свежую
    }
}

fileprivate extension DateFormatter {
    static func yyyyMMddQuery(start: Date, end: Date) -> [URLQueryItem] {
        let f = DateFormatter()
        f.timeZone = .init(secondsFromGMT: 0)
        f.locale   = .init(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return [
            .init(name: "startDate", value: f.string(from: start)),
            .init(name: "endDate",   value: f.string(from: end))
        ]
    }
}
