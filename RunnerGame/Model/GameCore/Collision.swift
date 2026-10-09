import Foundation

/// AABB collision between the player and nearby hazards and coins.
enum Collision {
    /// Objects further than this from the player (in world points) are not tested.
    static let checkRange: Double = 400

    /// Collects overlapping coins, and applies at most one hazard hit per step.
    /// Hit hazards break (are removed). Hazard overlaps are ignored while invincible.
    static func resolve(
        player: Player,
        hazards: inout [Hazard],
        coins: inout [Coin],
        lives: inout Lives,
        config: GameConfig
    ) -> [GameEvent] {
        var events: [GameEvent] = []
        let box = player.hitbox(config: config)
        let nearMin = player.x - checkRange
        let nearMax = player.x + checkRange

        // Coins are collected even while invincible.
        var keptCoins: [Coin] = []
        keptCoins.reserveCapacity(coins.count)
        for coin in coins {
            if coin.x >= nearMin, coin.x <= nearMax, coin.hitbox(config: config).overlaps(box) {
                events.append(.coinCollected(coin))
            } else {
                keptCoins.append(coin)
            }
        }
        coins = keptCoins

        guard !lives.isInvincible, !lives.isOut else { return events }

        if let index = hazards.firstIndex(where: { hazard in
            hazard.maxX >= nearMin && hazard.x <= nearMax &&
            (hazard.hitbox(config: config)?.overlaps(box) ?? false)
        }) {
            let broken = hazards.remove(at: index)
            lives.loseLife(invincibility: config.invincibilityDuration)
            events.append(.lifeLost(brokenHazard: broken))
            if lives.isOut {
                events.append(.gameOver)
            }
        }
        return events
    }
}
