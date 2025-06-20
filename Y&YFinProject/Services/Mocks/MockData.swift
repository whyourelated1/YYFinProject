import Foundation

enum MockData {
    static let account = BankAccount(
        id: 1,
        userId: 42,
        name: "Основной счёт",
        balance: Decimal(string: "15000.00")!,
        currency: "RUB",
        createdAt: Date(),
        updatedAt: Date()
    )

    static let categories: [TransactionCategory] = [
        TransactionCategory(id: 1, name: "Продукты", emoji: "🛒", direction: .outcome),
        TransactionCategory(id: 2, name: "Зарплата", emoji: "💼", direction: .income),
        TransactionCategory(id: 3, name: "Развлечения", emoji: "🎮", direction: .outcome),
    ]

    static let transactions: [Transaction] = [
        Transaction(
            id: 1,
            accountId: account.id,
            categoryId: categories[0].id,
            amount: Decimal(string: "1000.00")!,
            comment: "Магазин",
            transactionDate: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            hidden: false,
            account: account,
            category: categories[0]
        )
    ]
}
