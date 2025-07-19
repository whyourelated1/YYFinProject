protocol CategoriesLocalStore {
    func saveAll(_ categories: [Category]) async throws
    func getAll() async throws -> [Category]
}
