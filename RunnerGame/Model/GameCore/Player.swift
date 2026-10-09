import Foundation

/// The runner. `x` is the world position of the left edge; `y` is feet height above the ground.
struct Player: Equatable {
    var x: Double = 0
    var y: Double = 0
    var vy: Double = 0
    var isOnGround = true
    var hasDoubleJumped = false
    var isDucking = false

    func height(config: GameConfig) -> Double {
        isDucking ? config.playerDuckingHeight : config.playerStandingHeight
    }

    func hitbox(config: GameConfig) -> Hitbox {
        Hitbox(minX: x, minY: y, width: config.playerWidth, height: height(config: config))
            .inset(by: config.hitboxInset)
    }

    /// Applies jump / double jump / duck. Returns the jump event if one started.
    mutating func apply(_ input: GameInput, config: GameConfig) -> GameEvent? {
        if input.jumpPressed {
            if isOnGround {
                vy = config.jumpVelocity
                isOnGround = false
                isDucking = false
                return .jumped
            }
            if !hasDoubleJumped {
                vy = config.doubleJumpVelocity
                hasDoubleJumped = true
                return .doubleJumped
            }
        }
        // Ducking is only possible on the ground.
        isDucking = isOnGround && input.duckHeld
        return nil
    }

    /// Vertical motion under gravity (exact for constant acceleration). Landing resets the double jump.
    mutating func integrate(dt: Double, config: GameConfig) {
        guard !isOnGround else { return }
        y += vy * dt - config.gravity * dt * dt / 2
        vy -= config.gravity * dt
        if y <= 0 {
            y = 0
            vy = 0
            isOnGround = true
            hasDoubleJumped = false
        }
    }
}
