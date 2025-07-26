import Foundation

struct TransactionCategory: Identifiable, Codable {
    let id: Int
    let name: String
    let emoji: Character
    let direction: Direction

    enum Direction: String, Codable {
        case income
        case outcome
    }
}

