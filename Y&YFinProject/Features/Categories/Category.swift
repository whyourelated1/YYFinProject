import Foundation

extension TransactionCategory {
    init(id: Int, name: String, emoji: Character, direction: Direction) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.isIncome = (direction == .income)
    }
}

enum Direction {
    case income
    case outcome
}

struct TransactionCategory: Codable {
    let id: Int
    let name: String
    let emoji: Character
    let isIncome: Bool

    var direction: Direction {
        return isIncome ? .income : .outcome
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isIncome = try container.decode(Bool.self, forKey: .isIncome)

        let emojiString = try container.decode(String.self, forKey: .emoji)
        guard let firstChar = emojiString.first else {
            throw DecodingError.dataCorruptedError(forKey: .emoji, in: container, debugDescription: "Emoji string is empty")
        }
        emoji = firstChar
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(isIncome, forKey: .isIncome)
        try container.encode(String(emoji), forKey: .emoji)
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, emoji, isIncome
    }
}

extension TransactionCategory {
    func toStorage() -> CategoryStorage {
        CategoryStorage(
            id: self.id,
            emoji: self.emoji,
            name: self.name,
            isIncome: self.isIncome
        )
    }
}

