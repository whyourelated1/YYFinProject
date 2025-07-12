/*содержит асинхронный метод для получения списка операций за период
 содержит асинхронный метод для создания транзакции
 содержит асинхронный метод для редактирования транзакции
 содержит асинхронный метод для удаления транзакции*/
import Foundation

final class TransactionsService {
    public var transactions: [Transaction] //!
    
    init() {
        self.transactions = MockData.transactions
    }
    
    func fetchTransactions(
        direction: TransactionCategory.Direction? = nil,
        from: Date,
        to: Date,
        limit: Int? = nil,
        offset: Int = 0
    ) async throws -> [Transaction] {
        //фильтрация по дате
        var filtered = transactions.filter {
            $0.transactionDate >= from && $0.transactionDate <= to
        }
        
        //фильтрация по направлению
        if let direction = direction {
            filtered = filtered.filter {
                $0.category?.direction == direction
            }
        }
        
        //сортировка по дате (новые сначала)
        filtered.sort { $0.transactionDate > $1.transactionDate }
        
        //применение пагинации
        if let limit = limit {
            let endIndex = min(offset + limit, filtered.count)
            return Array(filtered[offset..<endIndex])
        }
        
        return filtered
    }
    
    func createTransaction(_ transaction: Transaction) async throws -> Transaction {
        transactions.append(transaction)
        return transaction
    }
    
    func getTransactions(from startDate: Date, to endDate: Date) async -> [Transaction] {
            return transactions.filter({$0.transactionDate >= startDate && $0.transactionDate <= endDate})
    }
    
    func updateTransaction(_ updated: Transaction) async throws -> Transaction {
        guard let index = transactions.firstIndex(where: { $0.id == updated.id }) else {
            throw NSError(domain: "Transaction not found", code: 404)
        }
        
        let newTransaction = transactions[index].updated(
            categoryId: updated.categoryId,
            amount: updated.amount,
            comment: updated.comment,
            transactionDate: updated.transactionDate,
            hidden: updated.hidden
        )
        
        transactions[index] = newTransaction
        return newTransaction
    }
    
    func deleteTransaction(id: Int) async throws {
        transactions.removeAll { $0.id == id }
    }
}
