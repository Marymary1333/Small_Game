import Foundation

/// Schedules hazards and coin patterns so every sequence is survivable.
///
/// Works in time: each hazard gets an arrival time (when it reaches the player's front edge)
/// and a clear time (when it has fully passed). The next hazard never arrives earlier than
/// the previous clear time plus `recoveryTime` plus a random gap from the difficulty profile.
final class Spawner {
    enum CoinPattern: Equatable { case jumpArc, high, riskyUnderBird, riskyAboveRock }

    private let config: GameConfig
    private let random: RandomSource
    private var nextID = 1

    private(set) var nextArrivalTime: Double
    private(set) var pendingType: HazardType?
    /// Arrival and clear times of every hazard spawned, for survivability checks in tests.
    private(set) var schedule: [(type: HazardType, arrival: Double, clear: Double)] = []

    init(config: GameConfig, random: RandomSource) {
        self.config = config
        self.random = random
        self.nextArrivalTime = config.firstHazardDelay
    }

    func update(world: inout World, profile: DifficultyProfile) {
        let type = pendingType ?? random.pick(weighted: profile.hazardWeights)
        pendingType = type

        let speed = world.speed
        let relativeSpeed = speed + approachSpeed(of: type)
        let timeToArrival = nextArrivalTime - world.elapsed
        let frontEdge = world.player.x + config.playerWidth
        let neededDistance = relativeSpeed * timeToArrival
        let spawnDistance = max(config.spawnAheadDistance, rockTriggerDistance(speed: speed) + 100)
        guard neededDistance <= (type == .rock ? spawnDistance : config.spawnAheadDistance) else { return }

        let hazardX = frontEdge + neededDistance
        let hazard = makeHazard(type: type, x: hazardX, speed: speed)
        world.hazards.append(hazard)

        let passDuration = (hazard.width + config.playerWidth) / relativeSpeed
        let clearTime = nextArrivalTime + passDuration
        schedule.append((type, nextArrivalTime, clearTime))

        if random.chance(profile.coinPatternChance) {
            let pattern = coinPattern(for: type)
            let meetingX = world.player.x + speed * max(0, timeToArrival) + config.playerWidth + hazard.width / 2
            world.coins.append(contentsOf: makeCoins(pattern: pattern, hazard: hazard, meetingX: meetingX))
        }

        nextArrivalTime = clearTime + config.recoveryTime + random.double(in: profile.gapTime)
        pendingType = nil
    }

    // MARK: Hazards

    private func approachSpeed(of type: HazardType) -> Double {
        switch type {
        case .barrel: return config.barrelRollSpeed
        case .bird: return config.birdFlySpeed
        case .rock, .narrowSpikes, .wideSpikes: return 0
        }
    }

    private func makeHazard(type: HazardType, x: Double, speed: Double) -> Hazard {
        defer { nextID += 1 }
        switch type {
        case .barrel: return .barrel(id: nextID, x: x, config: config)
        case .bird: return .bird(id: nextID, x: x, config: config)
        case .rock: return .rock(id: nextID, x: x, config: config)
        case .narrowSpikes:
            return .spikes(id: nextID, type: .narrowSpikes, x: x, width: config.narrowSpikeWidth, config: config)
        case .wideSpikes:
            return .spikes(id: nextID, type: .wideSpikes, x: x, width: config.wideSpikeWidth(speed: speed), config: config)
        }
    }

    /// Distance ahead of the player's front edge at which a rock starts its warning.
    func rockTriggerDistance(speed: Double) -> Double {
        speed * (config.rockWarningDuration + config.rockFallDuration + config.rockLandLeadTime)
    }

    // MARK: Coins

    private func coinPattern(for type: HazardType) -> CoinPattern {
        switch type {
        case .barrel, .narrowSpikes: return random.chance(0.5) ? .jumpArc : .high
        case .wideSpikes: return .high
        case .bird: return .riskyUnderBird
        case .rock: return .riskyAboveRock
        }
    }

    private func makeCoins(pattern: CoinPattern, hazard: Hazard, meetingX: Double) -> [Coin] {
        func coin(_ x: Double, _ y: Double) -> Coin {
            defer { nextID += 1 }
            return Coin(id: nextID, x: x, y: y)
        }
        switch pattern {
        case .jumpArc:
            let count = 5
            let span = hazard.width + 2 * config.coinSize * 2
            let peak = hazard.height + config.coinArcClearance
            return (0..<count).map { i in
                let t = Double(i) / Double(count - 1)          // 0...1
                let x = meetingX - span / 2 + span * t
                let arc = 1 - pow(2 * t - 1, 2)                 // 0 at ends, 1 in the middle
                return coin(x, config.coinSize / 2 + (peak - config.coinSize / 2) * arc)
            }
        case .high:
            let spacing = config.coinSize * 1.5
            return (-1...1).map { coin(meetingX + Double($0) * spacing, config.highCoinCentreY) }
        case .riskyUnderBird:
            return [coin(meetingX, config.coinSize / 2 + 6)]
        case .riskyAboveRock:
            return [coin(hazard.x + hazard.width / 2, config.rockSize + config.coinArcClearance / 2)]
        }
    }
}

extension GameConfig {
    /// First hazard arrives this many seconds into a run.
    var firstHazardDelay: Double { 3.0 }

    /// Height of the top of a jump-arc coin pattern above the hazard.
    var coinArcClearance: Double { 60 }

    /// Seconds from release to landing for a rock, including the fall speed cap.
    var rockFallDuration: Double {
        let timeToCap = rockMaxFallSpeed / gravity
        let distanceToCap = rockMaxFallSpeed * rockMaxFallSpeed / (2 * gravity)
        if distanceToCap >= rockDropHeight {
            return (2 * rockDropHeight / gravity).squareRoot()
        }
        return timeToCap + (rockDropHeight - distanceToCap) / rockMaxFallSpeed
    }

    /// Hitbox inset on one side for a dimension.
    func insetMargin(_ size: Double) -> Double { size * hitboxInset / 2 }

    /// Feet height the player needs to clear a ground hazard of `height`, accounting for hitbox insets.
    func clearanceHeight(forHazardHeight height: Double) -> Double {
        (height - insetMargin(height)) - insetMargin(playerStandingHeight)
    }

    var playerHitboxWidth: Double { playerWidth - 2 * insetMargin(playerWidth) }

    /// Spike width a single jump cannot clear at `speed`, but a double jump can.
    func wideSpikeWidth(speed: Double) -> Double {
        let clearHeight = clearanceHeight(forHazardHeight: spikeHeight)
        let singleClear = speed * singleJumpTimeAbove(height: clearHeight) - playerHitboxWidth
        // Spike hitbox is inset too: hitboxWidth = width × (1 − inset).
        return singleClear / (1 - hitboxInset) + wideSpikeExtraWidth
    }

    /// Centre height for high coins: above anything a single jump reaches, below a double jump's reach.
    var highCoinCentreY: Double {
        let singleTop = singleJumpPeak + playerStandingHeight - insetMargin(playerStandingHeight)
        return singleTop + coinSize / 2 + 20
    }
}
