import Foundation

enum BackupOperationType: String, Codable {
    case add, update, delete
}

struct BackupOperation: Codable, Identifiable {
    var id: Int
    var operationType: BackupOperationType
    var transaction: Transaction?
    var balanceDelta: Decimal?
}
