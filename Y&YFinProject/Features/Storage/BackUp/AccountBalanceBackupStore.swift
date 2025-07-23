import SwiftData
import SwiftUI


@MainActor
final class AccountBalanceBackupStore {
    private let container: ModelContainer
    init(container: ModelContainer) { self.container = container }

    func add(_ model: AccountBalanceBackupModel) async throws {
        container.mainContext.insert(model)
        try container.mainContext.save()
    }

    func all() async throws -> [AccountBalanceBackupModel] {
        try container.mainContext.fetch(FetchDescriptor<AccountBalanceBackupModel>())
    }

    func delete(_ model: AccountBalanceBackupModel) async throws {
        container.mainContext.delete(model)
        try container.mainContext.save()
    }
}
