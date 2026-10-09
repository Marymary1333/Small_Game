import SpriteKit

/// Yellow coin. Origin = coin centre.
final class CoinShapeNode: SKShapeNode {
    convenience init(config: GameConfig) {
        self.init(circleOfRadius: CGFloat(config.coinSize / 2))
        fillColor = SKColor(red: 1.0, green: 0.84, blue: 0.1, alpha: 1)
        strokeColor = SKColor(red: 0.8, green: 0.6, blue: 0.0, alpha: 1)
        lineWidth = 3
    }
}
