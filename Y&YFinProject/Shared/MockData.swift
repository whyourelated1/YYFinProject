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
        TransactionCategory(id: 1, name: "Продукты", emoji: "🍎", direction: .outcome),
        TransactionCategory(id: 2, name: "Зарплата", emoji: "💼", direction: .income),
        TransactionCategory(id: 3, name: "Магазины", emoji: "🛍️", direction: .outcome),
        TransactionCategory(id: 4, name: "Фриланс", emoji: "💻", direction: .income),
        TransactionCategory(id: 5, name: "Кафе и рестораны", emoji: "🍽️", direction: .outcome),
        TransactionCategory(id: 6, name: "Развлечения", emoji: "🎡", direction: .outcome),

    ]

    static let transactions: [Transaction] = [
        //расходы: продукты
        Transaction(
            id: 1,
            accountId: account.id,
            categoryId: categories[0].id,
            amount: Decimal(string: "1200.00")!,
            comment: "Супермаркет",
            transactionDate: Date().addingTimeInterval(-3600 * 1),
            createdAt: Date(),
            updatedAt: Date(),
            hidden: false,
            account: account,
            category: categories[0]
        ),
        //доход: зарплата
        Transaction(
            id: 2,
            accountId: account.id,
            categoryId: categories[1].id,
            amount: Decimal(string: "50000.00")!,
            comment: "Июньская зарплата",
            transactionDate: Date().addingTimeInterval(-3600 * 3),
            createdAt: Date(),
            updatedAt: Date(),
            hidden: false,
            account: account,
            category: categories[1]
        ),
        //расходы: развлечения
        Transaction(
            id: 3,
            accountId: account.id,
            categoryId: categories[5].id,
            amount: Decimal(string: "800.00")!,
            comment: "Кинотеатр",
            transactionDate: Date().addingTimeInterval(-3600 * 5),
            createdAt: Date(),
            updatedAt: Date(),
            hidden: false,
            account: account,
            category: categories[5]
        ),
        //доход: фриланс
        Transaction(
            id: 4,
            accountId: account.id,
            categoryId: categories[3].id,
            amount: Decimal(string: "7500.00")!,
            comment: "Дизайн",
            transactionDate: Date().addingTimeInterval(-3600 * 7),
            createdAt: Date(),
            updatedAt: Date(),
            hidden: false,
            account: account,
            category: categories[3]
        ),
        //расходы: кафе
        Transaction(
            id: 5,
            accountId: account.id,
            categoryId: categories[4].id,
            amount: Decimal(string: "450.00")!,
            comment: "Кофе и десерт",
            transactionDate: Date().addingTimeInterval(-3600 * 9),
            createdAt: Date(),
            updatedAt: Date(),
            hidden: false,
            account: account,
            category: categories[4]
        ),
        //расходы: шопинг
        Transaction(
            id: 6,
            accountId: account.id,
            categoryId: categories[2].id,
            amount: Decimal(string: "2300.00")!,
            comment: "Новая обувь",
            transactionDate: Date().addingTimeInterval(-3600 * 12),
            createdAt: Date(),
            updatedAt: Date(),
            hidden: false,
            account: account,
            category: categories[2]
        )
    ]
}

