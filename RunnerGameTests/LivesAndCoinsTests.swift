import XCTest
@testable import RunnerGame

final class LivesAndCoinsTests: XCTestCase {
    private let config = Sim.config

    func testRunStartsWithThreeLives() {
        XCTAssertEqual(Sim.engine().world.lives.remaining, 3)
    }

    func testHitRemovesLifeAndBreaksObstacle() {
        let engine = Sim.engine()
        engine.world.hazards = [.barrel(id: 7, x: 20, config: config)]
        let events = Sim.run(engine, seconds: 0.05)
        XCTAssertTrue(events.contains { if case .lifeLost(let h) = $0 { return h.id == 7 } else { return false } })
        XCTAssertEqual(engine.world.lives.remaining, 2)
        XCTAssertTrue(engine.world.hazards.isEmpty)
        XCTAssertTrue(engine.world.lives.isInvincible)
    }

    func testHazardsIgnoredWhileInvincible() {
        let engine = Sim.engine()
        engine.world.hazards = [
            .spikes(id: 1, type: .narrowSpikes, x: 20, width: 60, config: config),
            .spikes(id: 2, type: .wideSpikes, x: 20, width: 300, config: config),
        ]
        Sim.run(engine, seconds: 0.5)
        XCTAssertEqual(engine.world.lives.remaining, 2)
        XCTAssertEqual(engine.world.hazards.map(\.id), [2])
    }

    func testInvincibilityEndsAfterConfiguredDuration() {
        let engine = Sim.engine()
        engine.world.hazards = [.barrel(id: 1, x: 20, config: config)]
        Sim.run(engine, seconds: 0.02)
        XCTAssertTrue(engine.world.lives.isInvincible)
        Sim.run(engine, seconds: config.invincibilityDuration)
        XCTAssertFalse(engine.world.lives.isInvincible)
    }

    func testThirdHitEndsTheGame() {
        let engine = Sim.engine()
        engine.world.lives.loseLife(invincibility: 0)
        engine.world.lives.loseLife(invincibility: 0)
        engine.world.hazards = [.barrel(id: 1, x: 20, config: config)]
        let events = Sim.run(engine, seconds: 0.1)
        XCTAssertEqual(events.last, .gameOver)
        XCTAssertTrue(engine.world.isGameOver)
        XCTAssertEqual(Sim.run(engine, seconds: 1), [], "engine stops after game over")
    }

    func testCoinsCollectedWhileInvincible() {
        let engine = Sim.engine()
        engine.world.lives.loseLife(invincibility: 5)
        engine.world.coins = [Coin(id: 1, x: 100, y: 30)]
        XCTAssertEqual(Sim.coinCount(Sim.run(engine, seconds: 0.5)), 1)
    }

    func testScoreIsMetresPlusTenPerCoin() {
        XCTAssertEqual(Score.total(metres: 123, coins: 4, config: config), 163)
        let engine = Sim.engine()
        engine.world.player.x = 500 // 10 m
        engine.world.coinsCollected = 2
        XCTAssertEqual(engine.world.score(config: config), 30)
    }

    func testCoinsNeverRestoreLives() {
        let engine = Sim.engine()
        engine.world.lives.loseLife(invincibility: 0)
        engine.world.coins = (0..<100).map { Coin(id: $0, x: 60 + Double($0) * 10, y: 30) }
        Sim.run(engine, seconds: 5)
        XCTAssertEqual(engine.world.coinsCollected, 100)
        XCTAssertEqual(engine.world.lives.remaining, 2)
    }
}
