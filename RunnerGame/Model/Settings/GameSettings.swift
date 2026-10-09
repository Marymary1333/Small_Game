import Foundation

/// Everything the player can change in Settings. Persisted as JSON.
struct GameSettings: Codable, Equatable {
    /// 0...1
    var musicVolume: Double
    /// 0...1
    var effectsVolume: Double
    var difficulty: Difficulty
    var theme: BackgroundTheme
    var character: CharacterSkin

    /// User-confirmed settings for a brand-new player.
    static let firstLaunch = GameSettings(
        musicVolume: 0.7,
        effectsVolume: 0.7,
        difficulty: .easy,
        theme: .forest,
        character: .cat
    )
}
