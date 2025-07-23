import Foundation
import SwiftUI

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int, String)
    case decodingError
    case encodingError
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Некорректный URL запроса."
        case .invalidResponse:
            return "Некорректный ответ сервера."
        case .httpError(let code, let message):
            return "Ошибка HTTP \(code): \(message)"
        case .decodingError:
            return "Не удалось разобрать ответ сервера."
        case .encodingError:
            return "Не удалось сформировать тело запроса."
        case .unknown(let error):
            return "Неизвестная ошибка: \(error.localizedDescription)"
        }
    }
}
struct EmptyRequest: Encodable {}

final class NetworkClient {
    private let baseURL = URL(string: "https://shmr-finance.ru/api/v1")!
    private let session: URLSession
    private let token: String

    init(token: String, session: URLSession = .shared) {
        self.token = token
        self.session = session
    }

    func request<Request: Encodable, Response: Decodable>(
        path: String,
        method: String = "GET",
        body: Request? = nil,
        queryItems: [URLQueryItem] = []
    ) async throws -> Response {
        let request = try makeRequest(path: path, method: method, body: body, queryItems: queryItems)
        let (data, response) = try await session.data(for: request)
        return try handleResponse(data: data, response: response)
    }

    func request<Request: Encodable>(
        path: String,
        method: String = "GET",
        body: Request? = nil,
        queryItems: [URLQueryItem] = []
    ) async throws {
        let request = try makeRequest(path: path, method: method, body: body, queryItems: queryItems)
        let (_, response) = try await session.data(for: request)
        try validateResponse(response: response)
    }

    private func makeRequest<Request: Encodable>(
        path: String,
        method: String,
        body: Request?,
        queryItems: [URLQueryItem]
    ) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 4
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw NetworkError.encodingError
            }
        }

        return request
    }

    private func handleResponse<T: Decodable>(data: Data?, response: URLResponse) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Нет описания ошибки"
            throw NetworkError.httpError(httpResponse.statusCode, message)
        }

        guard let data = data else {
            throw NetworkError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Не удалось декодировать: \(String(data: data, encoding: .utf8) ?? "")")
            throw NetworkError.decodingError
        }
    }

    private func validateResponse(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(httpResponse.statusCode, "Пустой ответ сервера.")
        }
    }
}

