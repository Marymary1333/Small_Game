import SpriteKit

/// Sky decoration (10%), far layer (30%), near layer (60%) and ground (100%) scrolling at fractions of the run distance.
final class ParallaxBackgroundNode: SKNode {
    private struct Layer {
        let node: SKNode
        let factor: CGFloat
    }

    private let size: CGSize
    private let groundHeight: CGFloat
    private var layers: [Layer] = []

    init(size: CGSize, groundHeight: CGFloat) {
        self.size = size
        self.groundHeight = groundHeight
        super.init()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func apply(theme: BackgroundTheme) {
        removeAllChildren()
        layers = []
        let palette = ThemePalette.palette(for: theme)
        var random = TileRandom(seed: 7)
        let skyTile = makeSkyTile(theme: theme, palette: palette, random: &random)
        let farTile = makeFarTile(theme: theme, palette: palette, random: &random)
        let nearTile = makeNearTile(theme: theme, palette: palette, random: &random)
        let groundTile = makeGroundTile(palette: palette)
        for (tile, factor, z) in [(skyTile, 0.1, -40.0), (farTile, 0.3, -30.0), (nearTile, 0.6, -20.0), (groundTile, 1.0, -10.0)] {
            let layer = SKNode()
            layer.zPosition = z
            layer.addChild(tile)
            let copy = tile.copy() as! SKNode
            copy.position.x = size.width
            layer.addChild(copy)
            addChild(layer)
            layers.append(Layer(node: layer, factor: CGFloat(factor)))
        }
    }

    func update(distance: Double) {
        for layer in layers {
            let offset = (CGFloat(distance) * layer.factor).truncatingRemainder(dividingBy: size.width)
            layer.node.position.x = -offset
        }
    }

    // MARK: Tiles (elements stay inside the tile width so copies join seamlessly)

    private func makeSkyTile(theme: BackgroundTheme, palette: ThemePalette, random: inout TileRandom) -> SKNode {
        let tile = SKNode()
        switch theme {
        case .forest, .snow:
            for _ in 0..<5 {
                let cloud = SKNode()
                for i in 0..<3 {
                    let puff = SKShapeNode(circleOfRadius: CGFloat(22 + random.next(12)))
                    puff.fillColor = palette.skyDecoration
                    puff.strokeColor = .clear
                    puff.position = CGPoint(x: CGFloat(i) * 30, y: CGFloat(random.next(10)))
                    cloud.addChild(puff)
                }
                cloud.position = CGPoint(x: 40 + CGFloat(random.next(Int(size.width) - 160)),
                                         y: size.height - 80 - CGFloat(random.next(160)))
                tile.addChild(cloud)
            }
        case .space:
            for _ in 0..<90 {
                let star = SKShapeNode(rectOf: CGSize(width: 3, height: 3))
                star.fillColor = palette.skyDecoration
                star.strokeColor = .clear
                star.position = CGPoint(x: 4 + CGFloat(random.next(Int(size.width) - 8)),
                                        y: groundHeight + 60 + CGFloat(random.next(Int(size.height - groundHeight) - 70)))
                tile.addChild(star)
            }
        }
        return tile
    }

    private func makeFarTile(theme: BackgroundTheme, palette: ThemePalette, random: inout TileRandom) -> SKNode {
        let tile = SKNode()
        switch theme {
        case .forest, .snow:
            for i in 0..<4 {
                let width = CGFloat(260 + random.next(80))
                let height = CGFloat(140 + random.next(90))
                let hill = SKShapeNode(rect: CGRect(x: 0, y: 0, width: width, height: height), cornerRadius: width / 2.4)
                hill.fillColor = palette.far
                hill.strokeColor = theme == .snow ? SKColor(white: 0.85, alpha: 1) : .clear
                hill.position = CGPoint(x: CGFloat(i) * size.width / 4 + 10, y: groundHeight - 40)
                tile.addChild(hill)
            }
        case .space:
            for i in 0..<2 {
                let radius = CGFloat(40 + random.next(40))
                let planet = SKShapeNode(circleOfRadius: radius)
                planet.fillColor = palette.far
                planet.strokeColor = .clear
                planet.position = CGPoint(x: CGFloat(i) * size.width / 2 + radius + CGFloat(random.next(300)),
                                          y: size.height - 180 - CGFloat(random.next(160)))
                tile.addChild(planet)
            }
        }
        return tile
    }

    private func makeNearTile(theme: BackgroundTheme, palette: ThemePalette, random: inout TileRandom) -> SKNode {
        let tile = SKNode()
        switch theme {
        case .forest, .snow:
            for i in 0..<7 {
                let tree = SKNode()
                let trunk = SKShapeNode(rect: CGRect(x: -8, y: 0, width: 16, height: 40))
                trunk.fillColor = theme == .forest ? palette.nearAccent : SKColor(red: 0.35, green: 0.25, blue: 0.18, alpha: 1)
                trunk.strokeColor = .clear
                tree.addChild(trunk)
                let crownHeight = CGFloat(90 + random.next(50))
                let crown = SKShapeNode(path: triangle(width: 80, height: crownHeight))
                crown.fillColor = palette.near
                crown.strokeColor = .clear
                crown.position.y = 30
                tree.addChild(crown)
                if theme == .snow {
                    let cap = SKShapeNode(path: triangle(width: 34, height: crownHeight * 0.4))
                    cap.fillColor = palette.nearAccent
                    cap.strokeColor = .clear
                    cap.position.y = 30 + crownHeight * 0.6
                    tree.addChild(cap)
                }
                tree.position = CGPoint(x: 60 + CGFloat(i) * (size.width - 120) / 7 + CGFloat(random.next(60)), y: groundHeight)
                tile.addChild(tree)
            }
        case .space:
            for i in 0..<5 {
                let width = CGFloat(180 + random.next(60))
                let hill = SKShapeNode(rect: CGRect(x: 0, y: 0, width: width, height: 70), cornerRadius: 34)
                hill.fillColor = palette.near
                hill.strokeColor = .clear
                let crater = SKShapeNode(ellipseOf: CGSize(width: 50, height: 16))
                crater.fillColor = palette.nearAccent
                crater.strokeColor = .clear
                crater.position = CGPoint(x: width / 2, y: 44)
                hill.addChild(crater)
                hill.position = CGPoint(x: CGFloat(i) * (size.width / 5) + 10, y: groundHeight - 30)
                tile.addChild(hill)
            }
        }
        return tile
    }

    private func makeGroundTile(palette: ThemePalette) -> SKNode {
        let tile = SKNode()
        let ground = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: groundHeight))
        ground.fillColor = palette.ground
        ground.strokeColor = .clear
        tile.addChild(ground)
        let spacing: CGFloat = 80
        var x: CGFloat = 0
        while x < size.width {
            let mark = SKShapeNode(rect: CGRect(x: x, y: groundHeight - 14, width: 30, height: 6))
            mark.fillColor = palette.groundMark
            mark.strokeColor = .clear
            tile.addChild(mark)
            x += spacing
        }
        return tile
    }

    private func triangle(width: CGFloat, height: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -width / 2, y: 0))
        path.addLine(to: CGPoint(x: width / 2, y: 0))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        return path
    }
}

/// Deterministic numbers so background layouts look the same every run.
private struct TileRandom {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next(_ upperBound: Int) -> Int {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Int((state >> 33) % UInt64(max(1, upperBound)))
    }
}
