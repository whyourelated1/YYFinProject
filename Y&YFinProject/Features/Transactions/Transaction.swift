import Foundation

enum Direction: String, Codable, Equatable {
    case income
    case outcome
}

struct Transaction: Codable {
    let id: Int
    let account: BankAccount
    let category: Category
    let amount: Decimal
    let transactionDate: Date
    let comment: String?
    let createdAt: Date
    let updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id, account, category, amount, transactionDate, comment, createdAt, updatedAt
    }

    private static let isoWithFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let isoNoFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
    private static func parseISO(_ s: String) -> Date? {
        isoWithFraction.date(from: s) ?? isoNoFraction.date(from: s)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id       = try c.decode(Int.self,          forKey: .id)
        account  = try c.decode(BankAccount.self,  forKey: .account)
        category = try c.decode(Category.self,     forKey: .category)

        let amtStr = try c.decode(String.self, forKey: .amount)
        guard let amt = Decimal(string: amtStr,
                                locale: Locale(identifier: "en_US_POSIX")) else {
            throw DecodingError.dataCorruptedError(
                forKey: .amount, in: c,
                debugDescription: "Invalid decimal: \(amtStr)"
            )
        }
        amount = amt

        let txStr  = try c.decode(String.self, forKey: .transactionDate)
        let crStr  = try c.decode(String.self, forKey: .createdAt)
        let upStr  = try c.decode(String.self, forKey: .updatedAt)

        guard
            let txDate = Transaction.parseISO(txStr),
            let crDate = Transaction.parseISO(crStr),
            let upDate = Transaction.parseISO(upStr)
        else {
            throw DecodingError.dataCorruptedError(
                forKey: .transactionDate, in: c,
                debugDescription: "Bad ISO‑8601 format"
            )
        }

        transactionDate = txDate
        createdAt       = crDate
        updatedAt       = upDate
        comment         = try c.decodeIfPresent(String.self, forKey: .comment)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)

        try c.encode(id,       forKey: .id)
        try c.encode(account,  forKey: .account)
        try c.encode(category, forKey: .category)
        try c.encode("\(amount)", forKey: .amount)

        let f = Transaction.isoWithFraction
        try c.encode(f.string(from: transactionDate), forKey: .transactionDate)
        try c.encode(f.string(from: createdAt),       forKey: .createdAt)
        try c.encode(f.string(from: updatedAt),       forKey: .updatedAt)
        try c.encodeIfPresent(comment,                forKey: .comment)
    }
}

extension Transaction {
    init(
        id: Int,
        account: BankAccount,
        category: Category,
        amount: Decimal,
        transactionDate: Date,
        comment: String?,
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

extension Transaction {
    init(from request: TransactionRequestBody, id: Int) {
        self.init(
            id: id,
            account: .test,
            category: .test,
            amount: Decimal(string: request.amount,
                            locale: Locale(identifier: "en_US_POSIX")) ?? 0,
            transactionDate: Transaction.isoWithFraction.date(from: request.transactionDate) ?? Date(),
            comment: request.comment,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

extension Transaction {
    var signedAmount: Decimal {
        category.direction == .income ? amount : -amount
    }
}
