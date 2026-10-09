import XCTest
@testable import RunnerGame

final class CollisionTests: XCTestCase {
    private let config = Sim.config

    func testRectanglesOverlap() {
        let a = Hitbox(minX: 0, minY: 0, width: 10, height: 10)
        XCTAssertTrue(a.overlaps(Hitbox(minX: 5, minY: 5, width: 10, height: 10)))
    }

    func testTouchingEdgesDoNotOverlap() {
        let a = Hitbox(minX: 0, minY: 0, width: 10, height: 10)
        XCTAssertFalse(a.overlaps(Hitbox(minX: 10, minY: 0, width: 10, height: 10)))
        XCTAssertFalse(a.overlaps(Hitbox(minX: 0, minY: 10, width: 10, height: 10)))
    }

    func testSeparatedRectanglesDoNotOverlap() {
        let a = Hitbox(minX: 0, minY: 0, width: 10, height: 10)
        XCTAssertFalse(a.overlaps(Hitbox(minX: 30, minY: 30, width: 5, height: 5)))
    }

    func testBarrelHitsStandingPlayer() {
        let engine = Sim.engine()
        engine.world.hazards = [.barrel(id: 1, x: 300, config: config)]
        XCTAssertTrue(Sim.lostLife(Sim.run(engine, seconds: 1.5)))
    }

    func testWellTimedJumpClearsBarrel() {
        XCTAssertTrue(someJumpTimeSurvives { .barrel(id: 1, x: 400, config: self.config) })
    }

    func testDuckingPassesUnderBird() {
        let engine = Sim.engine()
        engine.world.hazards = [.bird(id: 1, x: 400, config: config)]
        XCTAssertFalse(Sim.lostLife(Sim.run(engine, seconds: 1.5, duck: true)))
    }

    func testStandingPlayerIsHitByBird() {
        let engine = Sim.engine()
        engine.world.hazards = [.bird(id: 1, x: 400, config: config)]
        XCTAssertTrue(Sim.lostLife(Sim.run(engine, seconds: 1.5)))
    }

    func testRockShadowNeverHits() {
        let engine = Sim.engine()
        var rock = Hazard.rock(id: 1, x: 0, config: config)
        rock.rockPhase = .warning(remaining: 10)
        engine.world.hazards = [rock]
        XCTAssertFalse(Sim.lostLife(Sim.run(engine, seconds: 0.5)))
    }

    func testLandedRockHits() {
        let engine = Sim.engine()
        var rock = Hazard.rock(id: 1, x: 250, config: config)
        rock.y = 0
        rock.rockPhase = .landed
        engine.world.hazards = [rock]
        XCTAssertTrue(Sim.lostLife(Sim.run(engine, seconds: 1.5)))
    }

    func testFallingRockLandsAndCanBeJumped() {
        XCTAssertTrue(someJumpTimeSurvives { .rock(id: 1, x: 900, config: self.config) }, "some jump must clear a rock")
    }

    func testWideSpikesCannotBeClearedWithSingleJump() {
        let width = config.wideSpikeWidth(speed: Difficulty.easy.profile.startSpeed)
        XCTAssertFalse(someJumpTimeSurvives { .spikes(id: 1, type: .wideSpikes, x: 500, width: width, config: self.config) })
    }

    func testWideSpikesCanBeClearedWithDoubleJump() {
        let width = config.wideSpikeWidth(speed: Difficulty.easy.profile.startSpeed)
        let apex = config.jumpVelocity / config.gravity
        XCTAssertTrue(someJumpTimeSurvives(doubleJumpAfter: apex) {
            .spikes(id: 1, type: .wideSpikes, x: 500, width: width, config: self.config)
        })
    }

    func testNarrowSpikesCanBeClearedWithSingleJump() {
        XCTAssertTrue(someJumpTimeSurvives { .spikes(id: 1, type: .narrowSpikes, x: 500, width: self.config.narrowSpikeWidth, config: self.config) })
    }

    func testCoinCollectedOnOverlap() {
        let engine = Sim.engine()
        engine.world.coins = [Coin(id: 1, x: 200, y: 30)]
        let events = Sim.run(engine, seconds: 1)
        XCTAssertEqual(Sim.coinCount(events), 1)
        XCTAssertEqual(engine.world.coinsCollected, 1)
        XCTAssertTrue(engine.world.coins.isEmpty)
    }

    /// With a 1/120 s step nothing may move further in one step than the smallest hitbox dimension.
    func testNoTunnelling() {
        let smallest = [
            config.coinSize, config.playerDuckingHeight, config.playerWidth, config.spikeHeight,
            config.narrowSpikeWidth, config.birdHeight, config.birdWidth, config.barrelSize, config.rockSize,
        ].map { $0 * (1 - config.hitboxInset) }.min()!
        let fastestApproach = max(config.barrelRollSpeed, config.birdFlySpeed)
        for difficulty in Difficulty.allCases {
            let horizontal = (difficulty.profile.maxSpeed + fastestApproach) * config.fixedStep
            XCTAssertLessThan(horizontal, smallest, "\(difficulty)")
        }
        XCTAssertLessThan(config.rockMaxFallSpeed * config.fixedStep, smallest)
        XCTAssertLessThan(max(config.jumpVelocity, config.doubleJumpVelocity) * config.fixedStep, smallest)
    }

    // MARK: Helpers

    /// Tries jump start times every 10 ms over 3 s; true if any avoids losing a life.
    private func someJumpTimeSurvives(doubleJumpAfter: Double? = nil, _ makeHazard: () -> Hazard) -> Bool {
        var t = 0.0
        while t < 3.0 {
            let engine = Sim.engine()
            engine.world.hazards = [makeHazard()]
            var jumps = [t]
            if let delay = doubleJumpAfter { jumps.append(t + delay) }
            if !Sim.lostLife(Sim.run(engine, seconds: 4.5, jumpAt: jumps)) { return true }
            t += 0.01
        }
        return false
    }
}
