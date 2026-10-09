import XCTest
@testable import RunnerGame

final class DifficultyTests: XCTestCase {
    func testSpeedStartsAtProfileStartSpeed() {
        for difficulty in Difficulty.allCases {
            XCTAssertEqual(difficulty.profile.speed(atMetres: 0), difficulty.profile.startSpeed)
        }
    }

    func testSpeedRampsPerHundredMetresAndCaps() {
        for difficulty in Difficulty.allCases {
            let p = difficulty.profile
            XCTAssertEqual(p.speed(atMetres: 100), p.startSpeed + p.speedRampPer100m, accuracy: 1e-9)
            XCTAssertEqual(p.speed(atMetres: 1_000_000), p.maxSpeed)
        }
    }

    func testHarderLevelsAreFasterAndDenser() {
        let e = Difficulty.easy.profile, n = Difficulty.normal.profile, h = Difficulty.hard.profile
        XCTAssertLessThan(e.startSpeed, n.startSpeed)
        XCTAssertLessThan(n.startSpeed, h.startSpeed)
        XCTAssertGreaterThan(e.gapTime.lowerBound, n.gapTime.lowerBound)
        XCTAssertGreaterThan(n.gapTime.lowerBound, h.gapTime.lowerBound)
    }

    func testEngineSpeedFollowsDistance() {
        let engine = Sim.engine(.normal)
        Sim.run(engine, seconds: 10)
        let metres = engine.world.player.x / Sim.config.pointsPerMetre
        XCTAssertEqual(engine.world.speed, Difficulty.normal.profile.speed(atMetres: metres), accuracy: 1)
        XCTAssertGreaterThan(engine.world.speed, Difficulty.normal.profile.startSpeed)
    }

    func testWideSpikesStayClearableAtMaxSpeed() {
        let config = Sim.config
        for difficulty in Difficulty.allCases {
            let speed = difficulty.profile.maxSpeed
            let clearHeight = config.clearanceHeight(forHazardHeight: config.spikeHeight)
            let doubleClear = speed * config.doubleJumpTimeAbove(height: clearHeight) - config.playerHitboxWidth
            let wideHitbox = config.wideSpikeWidth(speed: speed) * (1 - config.hitboxInset)
            XCTAssertLessThan(wideHitbox, doubleClear, "\(difficulty)")
        }
    }
}
