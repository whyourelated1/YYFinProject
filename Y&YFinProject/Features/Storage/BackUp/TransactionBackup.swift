enum BackupAction: String, Codable {
    case create
    case update
    case delete
    case balance  
}

struct TransactionBackup: Identifiable, Codable {
    let id: Int
    let action: BackupAction
    let transaction: Transaction
}
