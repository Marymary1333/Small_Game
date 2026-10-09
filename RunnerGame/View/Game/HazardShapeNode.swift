import SpriteKit

/// Barrel, bird, rock (with shadow) or spikes. Origin = bottom-left of the hazard's box.
final class HazardShapeNode: SKNode {
    let color: SKColor
    private let spinner = SKNode()
    private var shadow: SKShapeNode?
    private var rockBody: SKNode?

    init(hazard: Hazard) {
        let w = CGFloat(hazard.width)
        let h = CGFloat(hazard.height)
        switch hazard.type {
        case .barrel: color = SKColor(red: 0.55, green: 0.33, blue: 0.15, alpha: 1)
        case .bird: color = SKColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 1)
        case .rock: color = SKColor(white: 0.5, alpha: 1)
        case .narrowSpikes, .wideSpikes: color = SKColor(white: 0.6, alpha: 1)
        }
        super.init()

        switch hazard.type {
        case .barrel:
            spinner.position = CGPoint(x: w / 2, y: h / 2)
            let disc = SKShapeNode(circleOfRadius: w / 2)
            disc.fillColor = color
            disc.strokeColor = SKColor(red: 0.35, green: 0.2, blue: 0.08, alpha: 1)
            disc.lineWidth = 3
            spinner.addChild(disc)
            let stripe = SKShapeNode(rect: CGRect(x: -w / 2 + 4, y: -2, width: w - 8, height: 4))
            stripe.fillColor = disc.strokeColor
            stripe.strokeColor = .clear
            spinner.addChild(stripe)
            addChild(spinner)
        case .bird:
            let bodyNode = SKShapeNode(rect: CGRect(x: 0, y: 0, width: w, height: h), cornerRadius: 4)
            bodyNode.fillColor = color
            bodyNode.strokeColor = .clear
            addChild(bodyNode)
            let eye = SKShapeNode(rect: CGRect(x: 6, y: h - 12, width: 6, height: 6))
            eye.fillColor = .black
            eye.strokeColor = .clear
            addChild(eye)
        case .rock:
            let shadowNode = SKShapeNode(ellipseOf: CGSize(width: w + 8, height: 12))
            shadowNode.fillColor = SKColor(white: 0, alpha: 0.4)
            shadowNode.strokeColor = .clear
            shadowNode.position.x = w / 2
            addChild(shadowNode)
            shadow = shadowNode
            let bodyNode = SKShapeNode(rect: CGRect(x: 0, y: 0, width: w, height: h), cornerRadius: 3)
            bodyNode.fillColor = color
            bodyNode.strokeColor = SKColor(white: 0.3, alpha: 1)
            bodyNode.lineWidth = 2
            addChild(bodyNode)
            rockBody = bodyNode
        case .narrowSpikes, .wideSpikes:
            let count = max(1, Int(w / 20))
            let toothWidth = w / CGFloat(count)
            let path = CGMutablePath()
            for i in 0..<count {
                let x = CGFloat(i) * toothWidth
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x + toothWidth, y: 0))
                path.addLine(to: CGPoint(x: x + toothWidth / 2, y: h))
                path.closeSubpath()
            }
            let teeth = SKShapeNode(path: path)
            teeth.fillColor = color
            teeth.strokeColor = SKColor(white: 0.35, alpha: 1)
            addChild(teeth)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func update(hazard: Hazard) {
        if hazard.type == .barrel {
            spinner.zRotation = -CGFloat(hazard.x / (hazard.width / 2))
        }
        if hazard.type == .rock {
            shadow?.isHidden = !hazard.showsShadow
            shadow?.position.y = -CGFloat(hazard.y)      // keep the shadow on the ground
            rockBody?.isHidden = hazard.rockPhase == .waiting || hazard.showsShadow && hazard.rockPhase != .falling
        }
    }
}
