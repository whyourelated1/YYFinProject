import Foundation

extension TransactionCategory {
    var jsonObject: Any {
        return [
            "id": id,
            "name": name,
            "emoji": String(emoji),
            "isIncome": direction == .income
        ]
    }

    static func parse(jsonObject: Any) -> TransactionCategory? {
        guard let dict = jsonObject as? [String: Any],
              let id = dict["id"] as? Int,
              let name = dict["name"] as? String,
              let emojiStr = dict["emoji"] as? String,
              let emoji = emojiStr.first,
              let isIncome = dict["isIncome"] as? Bool
        else {
            return nil
        }

        let direction: Direction = isIncome ? .income : .outcome

        return TransactionCategory(
            id: id,
            name: name,
            emoji: emoji,
            direction: direction
        )
    }
}
