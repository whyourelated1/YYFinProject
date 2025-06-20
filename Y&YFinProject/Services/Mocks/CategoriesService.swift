/*содержит асинхронный метод для получения списка всех категорий
содержит асинхронный метод для получения списка категорий расходов или доходов (оперделяется параметром типа Direction)*/
import Foundation

final class CategoriesService {
    func categories() async throws -> [TransactionCategory] {
        return MockData.categories
    }

    func categories(for direction: TransactionCategory.Direction) async throws -> [TransactionCategory] {
        return MockData.categories.filter { $0.direction == direction }
    }
}
