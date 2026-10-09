import Foundation

/// A collectible coin. `x`, `y` are the centre in world coordinates.
struct Coin: Identifiable, Equatable {
    let id: Int
    var x: Double
    var y: Double

    func hitbox(config: GameConfig) -> Hitbox {
        let size = config.coinSize
        return Hitbox(minX: x - size / 2, minY: y - size / 2, width: size, height: size)
            .inset(by: config.hitboxInset)
    }
}
