import Foundation

final class CategoriesService {
    private let client: NetworkClient
    private let localStore: CategoriesLocalStore?

    init(client: NetworkClient, localStore: CategoriesLocalStore? = nil) {
        self.client = client
        self.localStore = localStore
    }

    func all() async throws -> [Category] {
        do {
            let categories: [Category] = try await client.request(
                path: "categories",
                method: "GET",
                body: Optional<EmptyRequest>.none
            )
            try await localStore?.saveAll(categories)
            return categories
        } catch {
            guard let local = try await localStore?.getAll(), !local.isEmpty else {
                throw error
            }
            return local
        }
    }

    func byDirection(_ direction: Direction) async throws -> [Category] {
        let allCategories = try await all()
        return allCategories.filter { $0.direction == direction }
    }

    func getCategory(withId id: Int) async throws -> Category {
        let categories = try await all()
        guard let category = categories.first(where: { $0.id == id }) else {
            throw NSError(domain: "CategoriesService", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Категория с id \(id) не найдена"
            ])
        }
        return category
    }
    
    func loadFromLocal() async throws -> [Category] {
            guard let store = localStore else {
                throw NSError(domain: "CategoriesService", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "Локальное хранилище не задано"
                ])
            }
            return try await store.getAll()
        }
}
