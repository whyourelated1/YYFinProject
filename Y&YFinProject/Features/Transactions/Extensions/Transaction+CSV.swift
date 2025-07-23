import Foundation

enum TransactionCSVParseError: Error, LocalizedError {
    case invalidColumnCount(Int, Int)
    case invalidField(Int, String, String)

    var errorDescription: String? {
        switch self {
        case .invalidColumnCount(let line, let count):
            return "Line \(line): not enough columns (\(count))."
        case .invalidField(let line, let field, let value):
            return "Line \(line): invalid value '\(value)' for field '\(field)'."
        }
    }
}

extension Transaction {

    static func parseCSV(from csv: String) throws -> [Transaction] {
        let lines = csv.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        guard lines.count > 1 else { return [] }

        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var result: [Transaction] = []

        for (index, line) in lines.dropFirst().enumerated() {
            let lineNumber = index + 2
            let cols = parseCSVRow(line)

            guard cols.count >= 14 else {
                throw TransactionCSVParseError.invalidColumnCount(lineNumber, cols.count)
            }

            guard let id = Int(cols[0]) else {
                throw TransactionCSVParseError.invalidField(lineNumber, "id", cols[0])
            }

            guard let accId = Int(cols[1]) else {
                throw TransactionCSVParseError.invalidField(lineNumber, "account id", cols[1])
            }

            let accName = cols[2]
            guard !accName.isEmpty else {
                throw TransactionCSVParseError.invalidField(lineNumber, "account name", accName)
            }

            guard let accBalance = Decimal(string: cols[3]) else {
                throw TransactionCSVParseError.invalidField(lineNumber, "balance", cols[3])
            }

            let accCurrency = cols[4]
            guard !accCurrency.isEmpty else {
                throw TransactionCSVParseError.invalidField(lineNumber, "currency", accCurrency)
            }

            guard let catId = Int(cols[5]) else {
                throw TransactionCSVParseError.invalidField(lineNumber, "category id", cols[5])
            }

            let catName = cols[6]
            guard !catName.isEmpty else {
                throw TransactionCSVParseError.invalidField(lineNumber, "category name", catName)
            }

            let catEmojiStr = cols[7]
            guard let catEmoji = catEmojiStr.first else {
                throw TransactionCSVParseError.invalidField(lineNumber, "emoji", catEmojiStr)
            }

            guard let catIsIncome = Bool(cols[8]) else {
                throw TransactionCSVParseError.invalidField(lineNumber, "isIncome", cols[8])
            }

            guard let amt = Decimal(string: cols[9]) else {
                throw TransactionCSVParseError.invalidField(lineNumber, "amount", cols[9])
            }

            guard let txDate = fmt.date(from: cols[10]) else {
                throw TransactionCSVParseError.invalidField(lineNumber, "transactionDate", cols[10])
            }

            let comment = cols[11].isEmpty ? nil : cols[11]

            guard let cDate = fmt.date(from: cols[12]) else {
                throw TransactionCSVParseError.invalidField(lineNumber, "createdAt", cols[12])
            }

            guard let uDate = fmt.date(from: cols[13]) else {
                throw TransactionCSVParseError.invalidField(lineNumber, "updatedAt", cols[13])
            }

            let account = BankAccount(id: accId, name: accName, balance: accBalance, currency: accCurrency)
            let category = Category(id: catId, name: catName, emoji: catEmoji, isIncome: catIsIncome)

            let tx = Transaction(
                id: id,
                account: account,
                category: category,
                amount: amt,
                transactionDate: txDate,
                comment: comment,
                createdAt: cDate,
                updatedAt: uDate
            )
            result.append(tx)
        }

        return result
    }

    var csvLine: String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return [
            "\(id)",
            "\(account.id)",
            escapeCSV(account.name),
            "\(account.balance)",
            account.currency,
            "\(category.id)",
            escapeCSV(category.name),
            String(category.emoji),
            "\(category.isIncome)",
            "\(amount)",
            fmt.string(from: transactionDate),
            escapeCSV(comment),
            fmt.string(from: createdAt),
            fmt.string(from: updatedAt)
        ].joined(separator: ",")
    }

    // MARK: - CSV Escaping Helper
    private func escapeCSV(_ value: String?) -> String {
        guard let value = value else { return "" }
        if value.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" }) {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        } else {
            return value
        }
    }

    // MARK: - CSV Row Parser
    private static func parseCSVRow(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var iterator = line.makeIterator()

        while let char = iterator.next() {
            if char == "\"" {
                if inQuotes {
                    if let next = iterator.next() {
                        if next == "\"" {
                            current.append("\"")
                        } else if next == "," {
                            result.append(current)
                            current = ""
                            inQuotes = false
                        } else {
                            current.append(next)
                            inQuotes = false
                        }
                    } else {
                        inQuotes = false
                    }
                } else {
                    inQuotes = true
                }
            } else if char == "," && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }

        result.append(current)
        return result
    }
}
