import SwiftData
import SwiftUI

@Model
final class AccountBalanceBackupModel {
    @Attribute(.unique) var id: UUID
    var accountId: Int
    var deltaRaw: String

    init(accountId: Int, delta: Decimal) {
        self.id = UUID()
        self.accountId = accountId
        self.deltaRaw  = "\(delta)"
    }

    var delta: Decimal { Decimal(string: deltaRaw) ?? 0 }
}
