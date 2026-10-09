import SpriteKit

/// Cat, Fox or Bear built from simple shapes. Origin = bottom-left of the player's box.
final class CharacterShapeNode: SKNode {
    private let body = SKNode()
    private let width: CGFloat
    private let height: CGFloat

    init(skin: CharacterSkin, config: GameConfig) {
        width = CGFloat(config.playerWidth)
        height = CGFloat(config.playerStandingHeight)
        super.init()
        addChild(body)
        build(skin)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func update(isDucking: Bool, blinkVisible: Bool) {
        body.yScale = isDucking ? 0.5 : 1
        alpha = blinkVisible ? 1 : 0.25
    }

    private func build(_ skin: CharacterSkin) {
        switch skin {
        case .cat:
            let grey = SKColor(white: 0.55, alpha: 1)
            add(rect(CGRect(x: -14, y: 30, width: 18, height: 6), grey))                 // thin tail
            add(rect(CGRect(x: 0, y: 0, width: width, height: height), grey, radius: 8))  // body
            add(triangle(at: CGPoint(x: 12, y: height - 2), width: 16, height: 16, grey))
            add(triangle(at: CGPoint(x: 36, y: height - 2), width: 16, height: 16, grey))
        case .fox:
            let orange = SKColor(red: 0.93, green: 0.48, blue: 0.13, alpha: 1)
            add(ellipse(CGRect(x: -26, y: 14, width: 34, height: 22), orange))            // bushy tail
            add(rect(CGRect(x: 0, y: 0, width: width, height: height), orange, radius: 8))
            add(rect(CGRect(x: 26, y: 16, width: 16, height: 26), .white, radius: 6))     // chest
            add(triangle(at: CGPoint(x: 12, y: height - 2), width: 14, height: 24, orange))
            add(triangle(at: CGPoint(x: 36, y: height - 2), width: 14, height: 24, orange))
        case .bear:
            let brown = SKColor(red: 0.45, green: 0.29, blue: 0.16, alpha: 1)
            add(rect(CGRect(x: -4, y: 0, width: width + 8, height: height), brown, radius: 12))
            add(circle(center: CGPoint(x: 8, y: height), radius: 9, brown))
            add(circle(center: CGPoint(x: 40, y: height), radius: 9, brown))
        }
        add(rect(CGRect(x: 32, y: height - 24, width: 8, height: 8), .black))              // eye, facing right
    }

    private func add(_ node: SKNode) { body.addChild(node) }

    private func rect(_ r: CGRect, _ color: SKColor, radius: CGFloat = 0) -> SKShapeNode {
        let node = SKShapeNode(rect: r, cornerRadius: radius)
        node.fillColor = color
        node.strokeColor = .clear
        return node
    }

    private func ellipse(_ r: CGRect, _ color: SKColor) -> SKShapeNode {
        let node = SKShapeNode(ellipseIn: r)
        node.fillColor = color
        node.strokeColor = .clear
        return node
    }

    private func circle(center: CGPoint, radius: CGFloat, _ color: SKColor) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: radius)
        node.position = center
        node.fillColor = color
        node.strokeColor = .clear
        return node
    }

    private func triangle(at base: CGPoint, width: CGFloat, height: CGFloat, _ color: SKColor) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -width / 2, y: 0))
        path.addLine(to: CGPoint(x: width / 2, y: 0))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        let node = SKShapeNode(path: path)
        node.position = base
        node.fillColor = color
        node.strokeColor = .clear
        return node
    }
}
