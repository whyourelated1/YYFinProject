import Foundation
import SwiftData

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var total: Decimal = 0
    @Published var startDate: Date
    @Published var endDate: Date
    @Published var isLoading = false
    @Published var alertError: String?

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
        let backupStore: TransactionsBackupStore? = backupContainer.map { TransactionsBackupStore(container: $0) }

        self.service = TransactionsService(
            client: client,
            localStore: localStore,
            backupStore: backupStore
        )

        let calendar = Calendar.current
        let now = Date()
        self.endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
        self.startDate = calendar.startOfDay(for: oneMonthAgo)

        Task { await load() }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let all = try await service.getTransactions(
                forAccount: accountId,
                from: startDate.startOfDay(),
                to: endDate.endOfDay()
            )
            let filtered = all.filter { $0.category.direction == direction }
            self.transactions = filtered
            self.total = filtered.reduce(0) { $0 + $1.amount }
        } catch {
            print("Ошибка при загрузке истории: \(error)")
            alertError = "Не удалось загрузить операции: \(error.localizedDescription)"

            let cached = service.cachedTransactions
            let filtered = cached.filter {
                $0.transactionDate >= startDate &&
                $0.transactionDate <= endDate &&
                $0.account.id == accountId &&
                $0.category.direction == direction
            }
            self.transactions = filtered
            self.total = filtered.reduce(0) { $0 + $1.amount }
        }
    }
}
