import Foundation

/// Complete state of a run at one moment.
struct World: Equatable {
    var player = Player()
    var hazards: [Hazard] = []
    var coins: [Coin] = []
    var lives: Lives
    /// Current scroll speed, points per second.
    var speed: Double
    var elapsed: Double = 0
    var coinsCollected = 0
    var isGameOver = false

    init(config: GameConfig, startSpeed: Double) {
        lives = Lives(max: config.maxLives)
        speed = startSpeed
    }

    func metres(config: GameConfig) -> Int {
        Score.metres(distance: player.x, config: config)
    }

    func score(config: GameConfig) -> Int {
        Score.total(metres: metres(config: config), coins: coinsCollected, config: config)
    }
}
