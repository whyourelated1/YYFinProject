import Foundation

struct Transaction: Identifiable, Codable, Sendable {
    let id: Int
    let accountId: Int
    let categoryId: Int?
    let amount: Decimal
    var comment: String?
    let transactionDate: Date
    let createdAt: Date
    let updatedAt: Date
    let hidden: Bool
    
    let account: BankAccount?
    let category: TransactionCategory?
    
    enum ParseError: Error {
        case invalidValue(column: String, value: String)
    }
}
