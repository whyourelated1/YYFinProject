import Foundation

final class TransactionsFileCache {

    // MARK: - Enum Exceptions
    enum CacheError: Error {
        case invalidJSON
        case invalidStructure
    }

    // MARK: - Date Formatter
    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        return f
    }()

    // MARK: - Storage
    private(set) var transactions: [Transaction] = []

    // MARK: - CRUD
    func add(_ tx: Transaction) {
        guard !transactions.contains(where: { $0.id == tx.id }) else { return }
        transactions.append(tx)
    }

    func remove(withId id: Int) {
        transactions.removeAll { $0.id == id }
    }
    
    func replaceAll(_ newTransactions: [Transaction]) {
        transactions = newTransactions
    }


    // MARK: - Persistence
    func save(to fileURL: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(transactions)
        try data.write(to: fileURL, options: [.atomic])
    }


    func load(from fileURL: URL) throws {
        let data = try Data(contentsOf: fileURL)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let arr = json as? [Any] else {
            throw CacheError.invalidStructure
        }

        var loaded: [Transaction] = []

        for obj in arr {
            do {
                let tx = try Transaction.parse(jsonObject: obj)
                loaded.append(tx)
            } catch {
                print("Failed to parse transaction: \(error.localizedDescription)")
            }
        }

        var seenIds = Set<Int>()
        var uniqueOrdered: [Transaction] = []

        for tx in loaded {
            if !seenIds.contains(tx.id) {
                uniqueOrdered.append(tx)
                seenIds.insert(tx.id)
            }
        }

        transactions = uniqueOrdered
    }

    // MARK: - Helpers
    static func defaultFileURL(fileName: String) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("\(fileName).json")
    }
}
