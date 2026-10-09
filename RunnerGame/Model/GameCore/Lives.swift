import Foundation

struct Lives: Equatable {
    private(set) var remaining: Int
    private(set) var invincibleRemaining: Double = 0

    init(max: Int) {
        remaining = max
    }

    var isInvincible: Bool { invincibleRemaining > 0 }
    var isOut: Bool { remaining == 0 }

    mutating func tick(dt: Double) {
        invincibleRemaining = Swift.max(0, invincibleRemaining - dt)
    }

    mutating func loseLife(invincibility: Double) {
        precondition(remaining > 0, "Cannot lose a life with none left")
        remaining -= 1
        invincibleRemaining = invincibility
    }
}
