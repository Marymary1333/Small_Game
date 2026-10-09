import Foundation

/// Score = 1 point per metre + `coinPoints` per coin.
enum Score {
    static func metres(distance: Double, config: GameConfig) -> Int {
        Int(distance / config.pointsPerMetre)
    }

    static func total(metres: Int, coins: Int, config: GameConfig) -> Int {
        metres + coins * config.coinPoints
    }
}
