import SwiftUI
import SwiftData

@Model
final class TransactionBackupModel {
    @Attribute(.unique) var id: Int
    var actionRaw: String
    var transactionData: Data

    init(id: Int, action: BackupAction, transaction: Transaction) {
        self.id = id
        self.actionRaw = action.rawValue
        self.transactionData = try! JSONEncoder().encode(transaction)
    }

    var action: BackupAction {
        BackupAction(rawValue: actionRaw) ?? .create
    }

    var transaction: Transaction {
        try! JSONDecoder().decode(Transaction.self, from: transactionData)
    }
}
