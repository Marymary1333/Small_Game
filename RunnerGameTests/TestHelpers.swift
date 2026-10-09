import XCTest
@testable import RunnerGame

enum Sim {
    static let config = GameConfig.standard

    /// Engine with no automatic spawning, for hand-built scenarios.
    static func engine(_ difficulty: Difficulty = .easy) -> GameEngine {
        GameEngine(config: config, difficulty: difficulty, random: SeededRandom(seed: 1), spawningEnabled: false)
    }

    /// Runs the engine for `seconds` in fixed steps. Jumps are pressed at the given times; duck is held throughout if `duck`.
    @discardableResult
    static func run(_ engine: GameEngine, seconds: Double, jumpAt: [Double] = [], duck: Bool = false) -> [GameEvent] {
        let step = config.fixedStep
        var pending = jumpAt.sorted()
        var events: [GameEvent] = []
        var t = 0.0
        while t < seconds {
            var press = false
            if let next = pending.first, t >= next {
                press = true
                pending.removeFirst()
            }
            events += engine.step(dt: step, input: GameInput(jumpPressed: press, duckHeld: duck))
            t += step
        }
        return events
    }

    static func lostLife(_ events: [GameEvent]) -> Bool {
        events.contains { if case .lifeLost = $0 { return true } else { return false } }
    }

    static func coinCount(_ events: [GameEvent]) -> Int {
        events.filter { if case .coinCollected = $0 { return true } else { return false } }.count
    }
}
