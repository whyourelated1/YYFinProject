import Foundation
import Combine
import SwiftData

@MainActor
final class AnalysisViewModel: ObservableObject {
    let service: TransactionsService
    let direction: Direction
    let accountId: Int
    let modelContainer: ModelContainer

    @Published var transactions: [Transaction] = []
    @Published var total: Decimal = 0
    @Published var startDate: Date {
        didSet { load() }
    }
    @Published var endDate: Date {
        didSet { load() }
    }
    @Published var isLoading: Bool = false
    @Published var alertMessage: String?

    var sortOption: SortOption = .date {
        didSet { sortTransactions() }
    }

    var onUpdate: (() -> Void)?
    var cancellables: Set<AnyCancellable> = []

    init(client: NetworkClient, accountId: Int, direction: Direction, modelContainer: ModelContainer) {
        self.accountId = accountId
        self.direction = direction
        self.modelContainer = modelContainer

        let localStore: TransactionsLocalStore = TransactionsSwiftDataStore(container: modelContainer)
        let backupSchema = Schema([TransactionBackupModel.self])
        let backupContainer = try? ModelContainer(for: backupSchema)
        let backupStore: TransactionsBackupStore? = backupContainer.map { TransactionsBackupStore(container: $0) }

        self.service = TransactionsService(
            client: client,
            localStore: localStore,
            backupStore: backupStore
        )

        let now = Date()
        self.endDate = now.endOfDay()
        self.startDate = Calendar.current.date(byAdding: .month, value: -1, to: now)!.startOfDay()

        load()
    }

    func load() {
        isLoading = true
        Task {
            defer { isLoading = false }

            do {
                let all = try await service.getTransactions(
                    forAccount: accountId,
                    from: startDate.startOfDay(),
                    to: endDate.endOfDay()
                )

                let filtered = all.filter { $0.category.direction == direction }

                self.transactions = filtered
                self.total = filtered.reduce(Decimal(0)) { $0 + $1.amount }

                sortTransactions()
            } catch {
                alertMessage = "Не удалось загрузить данные: \(error.localizedDescription)"
            }
        }
    }

    private func sortTransactions() {
        switch sortOption {
        case .date:
            transactions.sort(by: { $0.transactionDate > $1.transactionDate })
        case .amount:
            transactions.sort(by: { $0.amount > $1.amount })
        }
        onUpdate?()
    }
}
