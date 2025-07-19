import Foundation

@MainActor
final class TransactionsListViewModel: ObservableObject, Sendable {
    @Published var transactions: [Transaction] = []
    @Published var totalAmount: Decimal = 0
    
    private let service = TransactionsService()
    
    func loadTransactions(direction: TransactionCategory.Direction, from: Date, to: Date) {
        Task {
            do {
                let transactions = try await service.fetchTransactions(direction: direction, from: from, to: to)
                DispatchQueue.main.async {
                    self.transactions = transactions
                    self.totalAmount = transactions.reduce(0) { $0 + $1.amount }
                }
            } catch {
                print("Error loading transactions: \(error)")
            }
        }
    }
}

