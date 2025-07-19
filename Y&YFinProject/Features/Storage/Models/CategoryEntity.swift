import Foundation
import SwiftData

@Model
final class CategoryEntity {
    @Attribute(.unique) var id: Int
    var name: String
    var emoji: String
    var direction: Bool

    init(id: Int, name: String, emoji: String, direction: Bool) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.direction = direction
    }

    func toModel() -> Category {
        Category(
            id: id,
            name: name,
            emoji: emoji.first ?? "❓",
            isIncome: direction
        )

    }
}
