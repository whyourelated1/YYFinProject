import SwiftUI
import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case byDate = "По дате"
    case byAmount = "По сумме"
    
    var id: String { rawValue }
}

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var startDate: Date {
        didSet {
            if startDate > endDate {
                endDate = startDate
            }
            reloadTransactions()
            onTransactionsUpdated?()
        }
    }
    @Published var endDate: Date {
        didSet {
            if endDate < startDate {
                startDate = endDate
            }
            reloadTransactions()
            onTransactionsUpdated?()
        }
    }
    @Published var selectedSort: SortOption {
        didSet { applySort() }
    }
    
    @Published var onTransactionsUpdated: (() -> Void)?
    
    @Published private(set) var allTransactions: [Transaction] = []
    var visibleTransactions: [Transaction] = [] {
        didSet { totalAmount = visibleTransactions.reduce(0) { $0 + $1.amount } }
    }
    @Published private(set) var totalAmount: Decimal = 0
    
    private let service: TransactionsService
    private let direction: TransactionCategory.Direction
    
    init(direction: TransactionCategory.Direction,
         service: TransactionsService = TransactionsService()) {
        
        self.direction = direction
        self.service = service
        let (defaultStart, defaultEnd) = Self.makeDefaultDateWindow()
        self.startDate = defaultStart
        self.endDate = defaultEnd
        self.selectedSort = .byDate
        
        Task { await loadTransactions() }
    }
    
    private func loadTransactions() async {
        let fetched = await service.getTransactions(from: startDate, to: endDate)
        allTransactions = fetched.filter { $0.category?.direction == direction }
        visibleTransactions = allTransactions
        applySort()
        self.onTransactionsUpdated?()
    }
    
    private func reloadTransactions() {
        Task { await loadTransactions() }
    }
    
    func updateSort(_ option: SortOption) {
        selectedSort = option
    }
    
    private func applySort() {
        switch selectedSort {
        case .byDate:
            visibleTransactions = allTransactions.sorted { $0.transactionDate < $1.transactionDate }
        case .byAmount:
            visibleTransactions = allTransactions.sorted { $0.amount < $1.amount }
        }
        onTransactionsUpdated?()
    }
    
    private static func makeDefaultDateWindow() -> (Date, Date) {
        let now = Date()
        let calendar = Calendar.current
        
        let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? Date()
        let start = calendar.date(byAdding: .day, value: -30, to: endOfToday) ?? Date()
        let startOfDay = calendar.startOfDay(for: start)
        
        return (startOfDay, endOfToday)
    }
}
