//добавлено, чтобы не создавалась новая структара, а обновлялись конкретные поля
import Foundation
extension Transaction {
    func updated(
        categoryId: Int? = nil,
        amount: Decimal? = nil,
        comment: String? = nil,
        transactionDate: Date? = nil,
        hidden: Bool? = nil
    ) -> Transaction {
        return Transaction(
            id: self.id,
            accountId: self.accountId,
            categoryId: categoryId ?? self.categoryId,
            amount: amount ?? self.amount,
            comment: comment ?? self.comment,
            transactionDate: transactionDate ?? self.transactionDate,
            createdAt: self.createdAt,
            updatedAt: Date(),
            hidden: hidden ?? self.hidden,
            account: self.account,
            category: self.category
        )
    }
}
