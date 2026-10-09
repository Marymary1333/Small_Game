import Foundation

enum HazardType: CaseIterable, Comparable, Hashable {
    case barrel, bird, rock, narrowSpikes, wideSpikes
}

enum RockPhase: Equatable {
    /// High above, invisible, waiting for the player to get close.
    case waiting
    /// Shadow shown on the ground; the rock drops when time runs out.
    case warning(remaining: Double)
    case falling
    case landed
}

/// A hazard in world coordinates. `x` is the left edge, `y` the bottom (0 = ground).
struct Hazard: Identifiable, Equatable {
    let id: Int
    let type: HazardType
    var x: Double
    var y: Double
    let width: Double
    let height: Double
    /// World velocity; negative moves toward the player.
    var vx: Double
    var vy: Double = 0
    /// Only set for rocks.
    var rockPhase: RockPhase?

    var maxX: Double { x + width }

    /// Nil while a rock is still waiting or only its shadow is shown.
    func hitbox(config: GameConfig) -> Hitbox? {
        if let phase = rockPhase {
            switch phase {
            case .waiting, .warning: return nil
            case .falling, .landed: break
            }
        }
        return Hitbox(minX: x, minY: y, width: width, height: height).inset(by: config.hitboxInset)
    }

    /// True while a rock's ground shadow should be shown.
    var showsShadow: Bool {
        switch rockPhase {
        case .warning, .falling: return true
        default: return false
        }
    }
}

extension Hazard {
    static func barrel(id: Int, x: Double, config: GameConfig) -> Hazard {
        Hazard(id: id, type: .barrel, x: x, y: 0,
               width: config.barrelSize, height: config.barrelSize, vx: -config.barrelRollSpeed)
    }

    static func bird(id: Int, x: Double, config: GameConfig) -> Hazard {
        Hazard(id: id, type: .bird, x: x, y: config.birdBottom,
               width: config.birdWidth, height: config.birdHeight, vx: -config.birdFlySpeed)
    }

    static func rock(id: Int, x: Double, config: GameConfig) -> Hazard {
        Hazard(id: id, type: .rock, x: x, y: config.rockDropHeight,
               width: config.rockSize, height: config.rockSize, vx: 0, rockPhase: .waiting)
    }

    static func spikes(id: Int, type: HazardType, x: Double, width: Double, config: GameConfig) -> Hazard {
        precondition(type == .narrowSpikes || type == .wideSpikes)
        return Hazard(id: id, type: type, x: x, y: 0, width: width, height: config.spikeHeight, vx: 0)
    }
}
