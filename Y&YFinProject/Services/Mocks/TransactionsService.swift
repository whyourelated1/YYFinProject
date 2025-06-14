/*содержит асинхронный метод для получения списка операций за период
 содержит асинхронный метод для создания транзакции
 содержит асинхронный метод для редактирования транзакции
 содержит асинхронный метод для удаления транзакции*/
import Foundation

final class TransactionsService {
    private var transactions: [Transaction]

    init() {
        self.transactions = MockData.transactions
    }

    func fetchTransactions(from: Date, to: Date) async throws -> [Transaction] {
        return transactions.filter {
            $0.transactionDate >= from && $0.transactionDate <= to
        }
    }

    func createTransaction(_ transaction: Transaction) async throws -> Transaction {
        transactions.append(transaction)
        return transaction
    }

    func updateTransaction(_ updated: Transaction) async throws -> Transaction {
        if let index = transactions.firstIndex(where: { $0.id == updated.id }) {
            transactions[index] = updated
        }
        return updated
    }

    func deleteTransaction(id: Int) async throws {
        transactions.removeAll { $0.id == id }
    }
}
