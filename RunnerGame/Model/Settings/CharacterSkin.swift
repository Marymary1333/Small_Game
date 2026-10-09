import Foundation

enum CharacterSkin: String, Codable, CaseIterable, Identifiable {
    case cat, fox, bear

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cat: return "Cat"
        case .fox: return "Fox"
        case .bear: return "Bear"
        }
    }
}
