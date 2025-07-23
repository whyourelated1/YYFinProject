protocol TransactionsLocalStore {
    func getAll() async throws -> [Transaction]
    func create(_ transaction: Transaction) async throws
    func update(_ transaction: Transaction) async throws
    func delete(by id: Int) async throws
    func get(by id: Int) async throws -> Transaction?
    func replaceAll(_ transactions: [Transaction]) async throws
}
