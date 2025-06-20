import Foundation

extension Transaction {
    static func parseCSV(from filename: String) -> [Transaction] {
        var transactions = [Transaction]()
        
        guard let filepath = Bundle.main.path(forResource: filename, ofType: "csv") else {
            print("CSV файл не найден")
            return []
        }
        
        var csvData = ""
        do {
            csvData = try String(contentsOfFile: filepath, encoding: .utf8)
        } catch {
            print("Ошибка чтения файла: \(error)")
            return []
        }
        //обработка , и ;
        let firstLine = csvData.components(separatedBy: .newlines).first ?? ""
        let divider = firstLine.contains(";") ? ";" : ","
        
        var rows = csvData.components(separatedBy: .newlines)
        
        guard !rows.isEmpty else { return [] }
        if rows[0].contains("id") && (rows[0].contains("accountId")) {
            rows.removeFirst()
        }
        
        let dateFormatter = ISO8601DateFormatter()
        
        for row in rows {
            guard !row.isEmpty else { continue }
            
            let columns = row.components(separatedBy: divider)
            
            
            guard columns.count >= 9 else {
                print("Неверное количество колонок в строке: \(row)")
                continue
            }
            
            do {
                let transaction = try parseTransactionRow(
                    columns: columns,
                    dateFormatter: dateFormatter
                )
                transactions.append(transaction)
            } catch {
                print("Ошибка парсинга строки: \(row). Ошибка: \(error)")
            }
        }
        
        return transactions
    }
    
    private static func parseTransactionRow(
        columns: [String],
        dateFormatter: ISO8601DateFormatter
    ) throws -> Transaction {
        
        guard let id = Int(columns[0]) else {
            throw ParseError.invalidValue(column: "id", value: columns[0])
        }
        
        guard let accountId = Int(columns[1]) else {
            throw ParseError.invalidValue(column: "accountId", value: columns[1])
        }
        
        guard let amount = Decimal(string: columns[3]) else {
            throw ParseError.invalidValue(column: "amount", value: columns[3])
        }
        
        guard let transactionDate = dateFormatter.date(from: columns[5]) else {
            throw ParseError.invalidValue(column: "transactionDate", value: columns[5])
        }
        
        guard let createdAt = dateFormatter.date(from: columns[6]) else {
            throw ParseError.invalidValue(column: "createdAt", value: columns[6])
        }
        
        guard let updatedAt = dateFormatter.date(from: columns[7]) else {
            throw ParseError.invalidValue(column: "updatedAt", value: columns[7])
        }
        
        let categoryId: Int? = columns[2].isEmpty ? nil : (Int(columns[2]) ?? nil)
        let comment: String? = columns[4].isEmpty ? nil : columns[4]
        let hidden = columns[8].lowercased() == "true"
        
        return Transaction(
            id: id,
            accountId: accountId,
            categoryId: categoryId,
            amount: amount,
            comment: comment,
            transactionDate: transactionDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            hidden: hidden,
            account: nil,
            category: nil
        )
    }
    
    func toCSVRow() -> String {
        let dateFormatter = ISO8601DateFormatter()
        return [
            String(id),
            String(accountId),
            categoryId?.description ?? "",
            amount.description,
            comment ?? "",
            dateFormatter.string(from: transactionDate),
            dateFormatter.string(from: createdAt),
            dateFormatter.string(from: updatedAt),
            hidden ? "true" : "false"
        ].joined(separator: ",")
    }
    
    static func writeToCSV(_ transactions: [Transaction], filename: String) throws {
        var csvString = "id,accountId,categoryId,amount,comment,transactionDate,createdAt,updatedAt,hidden\n"
        
        for transaction in transactions {
            csvString += transaction.toCSVRow() + "\n"
        }
        
        let fileURL = try FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(filename)
            .appendingPathExtension("csv")
        
        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
