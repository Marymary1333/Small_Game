import XCTest
@testable import RunnerGame

final class PlayerMovementTests: XCTestCase {
    private let config = Sim.config

    func testJumpRisesToPeakAndReturnsToGround() {
        let engine = Sim.engine()
        var peak = 0.0
        _ = engine.step(dt: config.fixedStep, input: GameInput(jumpPressed: true))
        for _ in 0..<240 {
            _ = engine.step(dt: config.fixedStep, input: GameInput())
            peak = max(peak, engine.world.player.y)
        }
        XCTAssertEqual(peak, config.singleJumpPeak, accuracy: 1)
        XCTAssertTrue(engine.world.player.isOnGround)
        XCTAssertEqual(engine.world.player.y, 0)
    }

    func testDoubleJumpOncePerAirtime() {
        let engine = Sim.engine()
        XCTAssertEqual(Sim.run(engine, seconds: 0.1, jumpAt: [0]), [.jumped])
        XCTAssertEqual(Sim.run(engine, seconds: 0.1, jumpAt: [0]), [.doubleJumped])
        XCTAssertEqual(Sim.run(engine, seconds: 0.1, jumpAt: [0]), [])
    }

    func testLandingResetsDoubleJump() {
        let engine = Sim.engine()
        Sim.run(engine, seconds: 0.1, jumpAt: [0])
        Sim.run(engine, seconds: 0.1, jumpAt: [0])
        Sim.run(engine, seconds: 3)
        XCTAssertTrue(engine.world.player.isOnGround)
        XCTAssertEqual(Sim.run(engine, seconds: 0.1, jumpAt: [0]), [.jumped])
        XCTAssertEqual(Sim.run(engine, seconds: 0.1, jumpAt: [0]), [.doubleJumped])
    }

    func testDoubleJumpReachesHigherThanSingle() {
        let engine = Sim.engine()
        var peak = 0.0
        let apex = config.jumpVelocity / config.gravity
        var t = 0.0
        var jumps = [0.0, apex]
        while t < 2.5 {
            var press = false
            if let next = jumps.first, t >= next { press = true; jumps.removeFirst() }
            _ = engine.step(dt: config.fixedStep, input: GameInput(jumpPressed: press))
            peak = max(peak, engine.world.player.y)
            t += config.fixedStep
        }
        XCTAssertEqual(peak, config.doubleJumpPeak, accuracy: 3)
    }

    func testDuckOnGroundShrinksHitbox() {
        let engine = Sim.engine()
        Sim.run(engine, seconds: 0.1, duck: true)
        XCTAssertTrue(engine.world.player.isDucking)
        XCTAssertEqual(engine.world.player.height(config: config), config.playerDuckingHeight)
    }

    func testCannotDuckInAir() {
        let engine = Sim.engine()
        Sim.run(engine, seconds: 0.05, jumpAt: [0])
        Sim.run(engine, seconds: 0.2, duck: true)
        XCTAssertFalse(engine.world.player.isOnGround)
        XCTAssertFalse(engine.world.player.isDucking)
    }

    func testJumpPressShorterThanOneStepIsNotLost() {
        let engine = Sim.engine()
        let events = engine.step(dt: config.fixedStep / 4, input: GameInput(jumpPressed: true))
        XCTAssertEqual(events, [])
        XCTAssertEqual(engine.step(dt: config.fixedStep, input: GameInput()), [.jumped])
    }
}
