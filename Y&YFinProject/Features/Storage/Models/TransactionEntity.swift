import Foundation
import SwiftData

@Model
final class TransactionEntity {
    @Attribute(.unique) var id: Int

    @Relationship var account: AccountEntity
    @Relationship var category: CategoryEntity

    var amount: Decimal
    var transactionDate: Date
    var comment: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: Int,
        account: AccountEntity,
        category: CategoryEntity,
        amount: Decimal,
        transactionDate: Date,
        comment: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.account = account
        self.category = category
        self.amount = amount
        self.transactionDate = transactionDate
        self.comment = comment
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension TransactionEntity {
    func toTransaction() -> Transaction {
        Transaction(
            id: id,
            account: BankAccount(
                id: account.id,
                name: account.name,
                balance: account.balance,
                currency: account.currency
            ),
            category: Category(
                id: category.id,
                name: category.name,
                emoji: category.emoji.first ?? "❓",
                isIncome: category.direction
            ),
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
