import Foundation

extension Character: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(self))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        guard let character = string.first else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode Character from an empty string"
            )
        }

        self = character
    }
}
