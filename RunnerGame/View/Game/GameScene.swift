import SpriteKit

/// Draws the world from GameViewModel each frame. Holds no game rules.
final class GameScene: SKScene {
    static let logicalSize = CGSize(width: 1280, height: 720)
    static let groundHeight: CGFloat = 120
    static let playerScreenX: CGFloat = 320

    var showHitboxes = false {
        didSet { hitboxLayer.isHidden = !showHitboxes }
    }

    private let viewModel: GameViewModel
    private let background: ParallaxBackgroundNode
    private let objectLayer = SKNode()
    private let hitboxLayer = HitboxDebugLayer()
    private var characterNode: CharacterShapeNode?
    private var hazardNodes: [Int: HazardShapeNode] = [:]
    private var coinNodes: [Int: CoinShapeNode] = [:]
    private var appliedTheme: BackgroundTheme?
    private var appliedCharacter: CharacterSkin?
    private var lastUpdateTime: TimeInterval?

    init(viewModel: GameViewModel) {
        self.viewModel = viewModel
        background = ParallaxBackgroundNode(size: Self.logicalSize, groundHeight: Self.groundHeight)
        super.init(size: Self.logicalSize)
        scaleMode = .aspectFit
        anchorPoint = .zero
        addChild(background)
        objectLayer.zPosition = 10
        addChild(objectLayer)
        hitboxLayer.zPosition = 100
        hitboxLayer.isHidden = true
        addChild(hitboxLayer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdateTime.map { currentTime - $0 } ?? 0
        lastUpdateTime = currentTime

        viewModel.tick(dt: dt)
        applyAppearanceIfChanged()
        render(viewModel.world)
    }

    // MARK: Rendering

    private func applyAppearanceIfChanged() {
        if appliedTheme != viewModel.theme {
            appliedTheme = viewModel.theme
            background.apply(theme: viewModel.theme)
            backgroundColor = ThemePalette.palette(for: viewModel.theme).sky
        }
        if appliedCharacter != viewModel.character {
            appliedCharacter = viewModel.character
            characterNode?.removeFromParent()
            let node = CharacterShapeNode(skin: viewModel.character, config: viewModel.config)
            node.zPosition = 5
            objectLayer.addChild(node)
            characterNode = node
        }
    }

    private func render(_ world: World) {
        let config = viewModel.config
        let playerX = world.player.x
        let toScreen: (Double, Double) -> CGPoint = { x, y in
            CGPoint(x: Self.playerScreenX + CGFloat(x - playerX), y: Self.groundHeight + CGFloat(y))
        }

        background.update(distance: playerX)

        if let characterNode {
            characterNode.position = toScreen(world.player.x, world.player.y)
            let blinkOn = !world.lives.isInvincible || Int(world.elapsed * 12) % 2 == 0
            characterNode.update(isDucking: world.player.isDucking, blinkVisible: blinkOn)
        }

        for event in viewModel.frameEvents {
            if case .lifeLost(let broken) = event, let node = hazardNodes.removeValue(forKey: broken.id) {
                shatter(node: node, at: toScreen(broken.x, broken.y), size: CGSize(width: broken.width, height: broken.height))
            }
        }

        var liveHazards = Set<Int>()
        for hazard in world.hazards {
            liveHazards.insert(hazard.id)
            let node = hazardNodes[hazard.id] ?? {
                let created = HazardShapeNode(hazard: hazard)
                objectLayer.addChild(created)
                hazardNodes[hazard.id] = created
                return created
            }()
            node.position = toScreen(hazard.x, hazard.y)
            node.update(hazard: hazard)
        }
        for (id, node) in hazardNodes where !liveHazards.contains(id) {
            node.removeFromParent()
            hazardNodes.removeValue(forKey: id)
        }

        var liveCoins = Set<Int>()
        for coin in world.coins {
            liveCoins.insert(coin.id)
            let node = coinNodes[coin.id] ?? {
                let created = CoinShapeNode(config: config)
                objectLayer.addChild(created)
                coinNodes[coin.id] = created
                return created
            }()
            node.position = toScreen(coin.x, coin.y)
        }
        for (id, node) in coinNodes where !liveCoins.contains(id) {
            node.removeFromParent()
            coinNodes.removeValue(forKey: id)
        }

        if showHitboxes {
            hitboxLayer.draw(world: world, config: config, toScreen: toScreen)
        }
    }

    /// Obstacle break effect: the shape is replaced by small pieces flying apart.
    private func shatter(node: HazardShapeNode, at origin: CGPoint, size: CGSize) {
        node.removeFromParent()
        let centre = CGPoint(x: origin.x + size.width / 2, y: origin.y + size.height / 2)
        for i in 0..<8 {
            let piece = SKShapeNode(rectOf: CGSize(width: 10, height: 10))
            piece.fillColor = node.color
            piece.strokeColor = .clear
            piece.position = centre
            piece.zPosition = 20
            objectLayer.addChild(piece)
            let angle = CGFloat(i) / 8 * 2 * .pi
            let move = SKAction.moveBy(x: cos(angle) * 60, y: sin(angle) * 60, duration: 0.35)
            piece.run(.sequence([.group([move, .fadeOut(withDuration: 0.35), .rotate(byAngle: .pi, duration: 0.35)]),
                                 .removeFromParent()]))
        }
    }
}
