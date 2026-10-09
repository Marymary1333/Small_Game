import SpriteKit

/// Draws every hitbox as a thin outline (development aid).
final class HitboxDebugLayer: SKNode {
    func draw(world: World, config: GameConfig, toScreen: (Double, Double) -> CGPoint) {
        removeAllChildren()
        guard !isHidden else { return }
        outline(world.player.hitbox(config: config), .green, toScreen)
        for hazard in world.hazards {
            if let box = hazard.hitbox(config: config) { outline(box, .red, toScreen) }
        }
        for coin in world.coins {
            outline(coin.hitbox(config: config), .yellow, toScreen)
        }
    }

    private func outline(_ box: Hitbox, _ color: SKColor, _ toScreen: (Double, Double) -> CGPoint) {
        let origin = toScreen(box.minX, box.minY)
        let node = SKShapeNode(rect: CGRect(x: origin.x, y: origin.y, width: box.width, height: box.height))
        node.strokeColor = color
        node.fillColor = .clear
        node.lineWidth = 1.5
        addChild(node)
    }
}
