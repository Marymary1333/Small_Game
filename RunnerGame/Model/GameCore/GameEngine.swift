import Foundation

/// Runs the game rules with a fixed time step. No UI, audio or persistence.
final class GameEngine {
    let config: GameConfig
    /// Can change mid-run; applies from the next step.
    var difficulty: Difficulty
    /// Internal setter so tests can build exact scenarios.
    var world: World

    private let spawner: Spawner
    private let spawningEnabled: Bool
    private var accumulator: Double = 0
    private var pendingJump = false

    init(config: GameConfig = .standard, difficulty: Difficulty, random: RandomSource, spawningEnabled: Bool = true) {
        self.config = config
        self.difficulty = difficulty
        self.spawningEnabled = spawningEnabled
        self.spawner = Spawner(config: config, random: random)
        self.world = World(config: config, startSpeed: difficulty.profile.startSpeed)
    }

    var spawnSchedule: [(type: HazardType, arrival: Double, clear: Double)] { spawner.schedule }

    /// Advances by `dt` seconds of real time. A jump press is kept until the next simulation step runs.
    func step(dt: Double, input: GameInput) -> [GameEvent] {
        if input.jumpPressed { pendingJump = true }
        guard !world.isGameOver else { return [] }

        accumulator += min(dt, config.maxFrameDelta)
        var events: [GameEvent] = []
        while accumulator >= config.fixedStep, !world.isGameOver {
            accumulator -= config.fixedStep
            events += simulate(config.fixedStep, duckHeld: input.duckHeld)
        }
        return events
    }

    private func simulate(_ h: Double, duckHeld: Bool) -> [GameEvent] {
        var events: [GameEvent] = []
        let profile = difficulty.profile

        world.elapsed += h
        world.speed = profile.speed(atMetres: world.player.x / config.pointsPerMetre)

        let input = GameInput(jumpPressed: pendingJump, duckHeld: duckHeld)
        pendingJump = false
        if let jump = world.player.apply(input, config: config) {
            events.append(jump)
        }
        world.player.x += world.speed * h
        world.player.integrate(dt: h, config: config)
        world.lives.tick(dt: h)

        updateHazards(h)
        if spawningEnabled {
            spawner.update(world: &world, profile: profile)
        }

        // Resolve on a local copy: passing several parts of a class property inout at once
        // violates Swift's exclusive-access rule.
        var resolved = world
        let hits = Collision.resolve(
            player: resolved.player, hazards: &resolved.hazards, coins: &resolved.coins,
            lives: &resolved.lives, config: config
        )
        world = resolved
        for event in hits {
            switch event {
            case .coinCollected: world.coinsCollected += 1
            case .gameOver: world.isGameOver = true
            default: break
            }
        }
        events += hits

        let behind = world.player.x - config.despawnBehindDistance
        world.hazards.removeAll { $0.maxX < behind }
        world.coins.removeAll { $0.x + config.coinSize < behind }
        return events
    }

    private func updateHazards(_ h: Double) {
        let front = world.player.x + config.playerWidth
        let trigger = spawner.rockTriggerDistance(speed: world.speed)
        for i in world.hazards.indices {
            world.hazards[i].x += world.hazards[i].vx * h
            guard let phase = world.hazards[i].rockPhase else { continue }
            switch phase {
            case .waiting:
                if world.hazards[i].x - front <= trigger {
                    world.hazards[i].rockPhase = .warning(remaining: config.rockWarningDuration)
                }
            case .warning(let remaining):
                let left = remaining - h
                world.hazards[i].rockPhase = left <= 0 ? .falling : .warning(remaining: left)
            case .falling:
                var vy = world.hazards[i].vy - config.gravity * h
                vy = max(vy, -config.rockMaxFallSpeed)
                world.hazards[i].vy = vy
                world.hazards[i].y += vy * h
                if world.hazards[i].y <= 0 {
                    world.hazards[i].y = 0
                    world.hazards[i].vy = 0
                    world.hazards[i].rockPhase = .landed
                }
            case .landed:
                break
            }
        }
    }
}
