import XCTest
@testable import RunnerGame

final class SpawnerTests: XCTestCase {
    private let config = Sim.config

    func testSequencesAlwaysLeaveRecoveryTime() {
        for difficulty in Difficulty.allCases {
            let profile = difficulty.profile
            let spawner = Spawner(config: config, random: SeededRandom(seed: 42))
            var world = World(config: config, startSpeed: profile.startSpeed)
            var t = 0.0
            while t < 600 {
                world.elapsed += config.fixedStep
                world.speed = profile.speed(atMetres: world.player.x / config.pointsPerMetre)
                world.player.x += world.speed * config.fixedStep
                spawner.update(world: &world, profile: profile)
                world.hazards.removeAll { $0.maxX < world.player.x - 400 }
                world.coins.removeAll()
                t += config.fixedStep
            }
            let schedule = spawner.schedule
            XCTAssertGreaterThan(schedule.count, 100, "\(difficulty)")
            for (previous, next) in zip(schedule, schedule.dropFirst()) {
                XCTAssertGreaterThanOrEqual(
                    next.arrival - previous.clear,
                    config.recoveryTime + profile.gapTime.lowerBound - 1e-9,
                    "\(difficulty): \(previous.type) then \(next.type)"
                )
            }
        }
    }

    func testHazardsSpawnOffScreen() {
        let profile = Difficulty.hard.profile
        let spawner = Spawner(config: config, random: SeededRandom(seed: 3))
        var world = World(config: config, startSpeed: profile.startSpeed)
        var seen = Set<Int>()
        for _ in 0..<(120 * 120) {
            world.elapsed += config.fixedStep
            world.player.x += world.speed * config.fixedStep
            spawner.update(world: &world, profile: profile)
            for hazard in world.hazards where !seen.contains(hazard.id) {
                seen.insert(hazard.id)
                XCTAssertGreaterThan(hazard.x - world.player.x, 1280 - 320, "spawned inside the visible area")
            }
        }
        XCTAssertFalse(seen.isEmpty)
    }

    func testHighCoinsNeedDoubleJump() {
        let coinBottom = config.highCoinCentreY - config.coinSize / 2 + config.insetMargin(config.coinSize)
        let headInset = config.insetMargin(config.playerStandingHeight)
        let singleTop = config.singleJumpPeak + config.playerStandingHeight - headInset
        let doubleTop = config.doubleJumpPeak + config.playerStandingHeight - headInset
        XCTAssertGreaterThan(coinBottom, singleTop)
        XCTAssertLessThan(coinBottom, doubleTop)
    }

    /// Every hazard is a bird with a risky coin underneath; a player who always ducks collects coins and is never hit.
    func testRiskyCoinsUnderBirdsAreSurvivable() {
        // Easy weights sorted barrel 4, bird 2, rock 1, narrow 3, wide 1 (total 11): 0.4 → bird. 0.1 → coin pattern. 0.5 → gap.
        let engine = GameEngine(config: config, difficulty: .easy, random: ScriptedRandom([0.4, 0.1, 0.5]))
        let events = Sim.run(engine, seconds: 30, duck: true)
        XCTAssertFalse(Sim.lostLife(events))
        XCTAssertGreaterThan(Sim.coinCount(events), 5)
    }

    /// Rocks with a coin above: jumping at the right time collects the coin without being hit.
    func testRiskyCoinAboveRockIsSurvivable() {
        let spawnerConfig = config
        var found = false
        var jumpTime = 2.0
        while jumpTime < 3.5, !found {
            // 0.6 → rock (cumulative barrel 4, bird 6, rock 7 of 11). 0.1 → coin pattern. 0.99 → long gap.
            let engine = GameEngine(config: spawnerConfig, difficulty: .easy, random: ScriptedRandom([0.6, 0.1, 0.99]))
            let events = Sim.run(engine, seconds: 4.5, jumpAt: [jumpTime])
            if !Sim.lostLife(events), Sim.coinCount(events) == 1 { found = true }
            jumpTime += 0.01
        }
        XCTAssertTrue(found)
    }
}
