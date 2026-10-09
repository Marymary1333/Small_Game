import Foundation

enum BackgroundTheme: String, Codable, CaseIterable, Identifiable {
    case forest, snow, space

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .forest: return "Forest"
        case .snow: return "Snow"
        case .space: return "Space"
        }
    }
}
