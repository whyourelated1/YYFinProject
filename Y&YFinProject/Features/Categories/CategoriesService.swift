import Foundation
import SwiftData

protocol CategoryStorageProtocol {
    func saveCategories(_ categories: [TransactionCategory]) async throws -> [TransactionCategory]
    func fetchAllCategories() async throws -> [TransactionCategory]
    func clearAllCategories() async throws
}

actor CategoriesService {

    let network: NetworkService
    let localStorage: SwiftDataCategoryStorage

    init(network: NetworkService, modelContainer: ModelContainer) {
        self.network = network
        self.localStorage = SwiftDataCategoryStorage(modelContainer: modelContainer)
    }

    func getAll() async throws -> [TransactionCategory] {
        do {
            let categories: [TransactionCategory] = try await network.request(endpoint: "categories")
            do {
                _ = try await localStorage.saveCategories(categories)
            } catch {
                throw error
            }
            return categories
        } catch {
            do {
                return try await localStorage.fetchAllCategories()
            } catch {
                throw error
            }
        }
    }

    func getById(by id: Int) async throws -> TransactionCategory {
        let all = try await getAll()
        guard let category = all.first(where: { $0.id == id }) else {
            throw NSError(domain: "TransactionCategory", code: 404, userInfo: [NSLocalizedDescriptionKey: "Категория с id \(id) не найдена"])
        }
        return category
    }

    func getIncomeOrOutcome(direction: Direction) async throws -> [TransactionCategory] {
        let isIncome = (direction == .income)
        let endpoint = "categories/type/\(isIncome)"
        do {
            let categories: [TransactionCategory] = try await network.request(endpoint: endpoint)
            do {
                _ = try await localStorage.saveCategories(categories)
            } catch {
                print("Ошибка сохранения локально: \(error)")
            }
            return categories
        } catch {
            let allLocalCategories = try await localStorage.fetchAllCategories()
            return allLocalCategories.filter { $0.isIncome == isIncome }
        }
    }

    func searchCategories(all categories: [TransactionCategory], searchText: String) async -> [TransactionCategory] {
        if searchText.isEmpty { return categories }

        return categories
            .map { ($0, $0.name.fuzzyMatchWithWeight(query: searchText).weight) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }
}
