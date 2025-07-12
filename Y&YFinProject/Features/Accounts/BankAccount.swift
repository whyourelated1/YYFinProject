import Foundation

struct BankAccount: Identifiable, Codable, Sendable {
    let id: Int
    let userId: Int
    let name: String
    let balance: Decimal
    let currency: String
    let createdAt: Date
    let updatedAt: Date
}

