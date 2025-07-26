import Foundation
import SwiftData

@MainActor
final class TransactionsListViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var total: Decimal = 0
    @Published var isLoading = false
    @Published var alertError: String?
    @Published var isOffline = false

    private let direction: Direction
    private let service: TransactionsService
    private let accountId: Int

    init(
        direction: Direction,
        client: NetworkClient,
        accountId: Int,
        modelContainer: ModelContainer
    ) {
        self.direction = direction
        self.accountId = accountId

        let localStore: TransactionsLocalStore = TransactionsSwiftDataStore(container: modelContainer)

        let backupSchema = Schema([TransactionBackupModel.self])
        let backupContainer = try? ModelContainer(for: backupSchema)
        let backupStore: TransactionsBackupStore? = backupContainer.map {
            TransactionsBackupStore(container: $0)
        }

        self.service = TransactionsService(
            client: client,
            localStore: localStore,
            backupStore: backupStore
        )

        Task { await loadToday() }
    }

    func loadToday() async {
        isLoading = true
        defer { isLoading = false }

        let calendar = Calendar.current
        let today = Date()
        guard let interval = calendar.dateInterval(of: .day, for: today) else {
            alertError = "Не удалось определить дату"
            return
        }

        do {
            let all = try await service.getTransactions(
                forAccount: accountId,
                from: interval.start,
                to: interval.end
            )

            let filtered = all.filter {
                interval.contains($0.transactionDate) &&
                $0.category.direction == direction
            }

            transactions = filtered
            total = filtered.reduce(0) { $0 + $1.amount }
            isOffline = false

        } catch {
            alertError = "Не удалось загрузить операции: \(error.localizedDescription)"

            let cached = service.cachedTransactions
            let filtered = cached.filter {
                interval.contains($0.transactionDate) &&
                $0.account.id == accountId &&
                $0.category.direction == direction
            }

            transactions = filtered
            total = filtered.reduce(0) { $0 + $1.amount }
            isOffline = true
        }
    }
}
