import Foundation

/// Gameplay constants shared by all difficulty levels.
/// Values are starting points to be tuned with the user during play-testing.
struct GameConfig: Equatable {
    // Simulation
    var fixedStep: Double = 1.0 / 120.0
    /// Longest frame the engine simulates at once; longer frames run in slow motion instead of teleporting objects.
    var maxFrameDelta: Double = 1.0 / 30.0
    var pointsPerMetre: Double = 50

    // Player
    var gravity: Double = 2600
    var jumpVelocity: Double = 950
    var doubleJumpVelocity: Double = 850
    var playerWidth: Double = 48
    var playerStandingHeight: Double = 72
    var playerDuckingHeight: Double = 36
    var hitboxInset: Double = 0.1

    // Lives and score
    var maxLives: Int = 3
    var invincibilityDuration: Double = 1.0
    var coinPoints: Int = 10

    // Objects
    var coinSize: Double = 28
    var barrelSize: Double = 44
    var barrelRollSpeed: Double = 160
    var birdWidth: Double = 44
    var birdHeight: Double = 32
    var birdBottom: Double = 44
    var birdFlySpeed: Double = 120
    var rockSize: Double = 44
    var rockDropHeight: Double = 520
    var rockWarningDuration: Double = 0.8
    var rockMaxFallSpeed: Double = 1400
    /// How long before the player reaches it a rock should be on the ground.
    var rockLandLeadTime: Double = 0.3
    var spikeHeight: Double = 26
    var narrowSpikeWidth: Double = 60
    /// Wide spikes are this much wider than the distance a single jump clears.
    var wideSpikeExtraWidth: Double = 60

    // Spawning
    /// New patterns appear this far ahead of the player (beyond the right screen edge).
    var spawnAheadDistance: Double = 1500
    /// Objects this far behind the player are removed.
    var despawnBehindDistance: Double = 400
    /// Minimum time between one hazard fully passing the player and the next arriving.
    var recoveryTime: Double = 0.45

    static let standard = GameConfig()

    // MARK: Derived jump physics

    /// Seconds a single jump keeps the player's feet above `height`.
    func singleJumpTimeAbove(height: Double) -> Double {
        let (t1, t2) = timesAt(height: height, startHeight: 0, velocity: jumpVelocity)
        return max(0, t2 - t1)
    }

    /// Seconds a jump followed by a double jump at the apex keeps the feet above `height`.
    func doubleJumpTimeAbove(height: Double) -> Double {
        let apexTime = jumpVelocity / gravity
        let apexHeight = jumpVelocity * jumpVelocity / (2 * gravity)
        let (rise, _) = timesAt(height: height, startHeight: 0, velocity: jumpVelocity)
        let (_, fall) = timesAt(height: height, startHeight: apexHeight, velocity: doubleJumpVelocity)
        return (apexTime - rise) + fall
    }

    var singleJumpPeak: Double { jumpVelocity * jumpVelocity / (2 * gravity) }

    var doubleJumpPeak: Double {
        singleJumpPeak + doubleJumpVelocity * doubleJumpVelocity / (2 * gravity)
    }

    /// Solves start + v·t − g·t²/2 = height for both roots.
    private func timesAt(height: Double, startHeight: Double, velocity: Double) -> (Double, Double) {
        let a = gravity / 2
        let b = -velocity
        let c = height - startHeight
        let disc = b * b - 4 * a * c
        guard disc >= 0 else { return (0, 0) }
        let root = disc.squareRoot()
        return ((-b - root) / (2 * a), (-b + root) / (2 * a))
    }
}
