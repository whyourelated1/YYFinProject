import Foundation

final class TransactionsFileCache {
    //содержит закрытую для внешнего изменения, но открытую для получения коллекцию Transaction'ов
    private(set) var transactions: [Transaction] = []

    //предусмотрен механизм защиты от дублирования операций (путем сравнения id)
    private var transactionMap: [Int: Transaction] = [:]

    // можем иметь несколько разных файлов
    private let fileURL: URL

    //инициализация
    init(fileName: String, directory: FileManager.SearchPathDirectory = .documentDirectory) {
        let directoryURL = FileManager.default.urls(for: directory, in: .userDomainMask).first!
        self.fileURL = directoryURL.appendingPathComponent(fileName).appendingPathExtension("json")
    }

    func add(_ transaction: Transaction) {
        guard transactionMap[transaction.id] == nil else { return } // уже есть
        transactions.append(transaction)
        transactionMap[transaction.id] = transaction
    }

    func remove(byId id: Int) {
        guard transactionMap[id] != nil else { return }
        transactions.removeAll { $0.id == id }
        transactionMap.removeValue(forKey: id)
    }

    func saveToFile() throws {
        let jsonArray = transactions.map { $0.jsonObject }

        guard JSONSerialization.isValidJSONObject(jsonArray) else {
            throw NSError(domain: "TransactionsFileCache", code: 100, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON object"])
        }

        let data = try JSONSerialization.data(withJSONObject: jsonArray, options: [.prettyPrinted])
        try data.write(to: fileURL)
    }

    func loadFromFile() throws {
        let data = try Data(contentsOf: fileURL)
        let raw = try JSONSerialization.jsonObject(with: data, options: [])

        guard let array = raw as? [Any] else {
            throw NSError(domain: "TransactionsFileCache", code: 101, userInfo: [NSLocalizedDescriptionKey: "JSON root is not array"])
        }

        var loaded: [Transaction] = []
        var map: [Int: Transaction] = [:]

        for element in array {
            if let transaction = Transaction.parse(jsonObject: element) {
                guard map[transaction.id] == nil else { continue } //от дубликатов
                loaded.append(transaction)
                map[transaction.id] = transaction
            }
        }

        self.transactions = loaded
        self.transactionMap = map
    }

    //очистка кэша
    func clear() {
        transactions = []
        transactionMap = [:]
    }
}
