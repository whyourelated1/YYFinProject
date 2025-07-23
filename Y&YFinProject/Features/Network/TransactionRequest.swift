import Foundation

struct TransactionRequestBody: Codable {
    let accountId: Int
    let categoryId: Int
    let amount: String
    let transactionDate: String
    let comment: String?

    init(
        accountId: Int,
        categoryId: Int,
        amount: Decimal,
        transactionDate: Date,
        comment: String?
    ) {
        self.accountId = accountId
        self.categoryId = categoryId
        self.amount = String(format: "%.2f", NSDecimalNumber(decimal: amount).doubleValue)
        self.transactionDate = Self.formatter.string(from: transactionDate)
        self.comment = comment
    }

    private static let formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}
extension TransactionRequestBody {
    init(from transaction: Transaction) {
        self.init(
            accountId: transaction.account.id,
            categoryId: transaction.category.id,
            amount: transaction.amount,
            transactionDate: transaction.transactionDate,
            comment: transaction.comment
        )
    }
}
