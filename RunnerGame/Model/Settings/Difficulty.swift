import Foundation

/// Difficulty level chosen in Settings.
enum Difficulty: String, Codable, CaseIterable, Identifiable {
    case easy, normal, hard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .normal: return "Normal"
        case .hard: return "Hard"
        }
    }

    /// Tuning table. Values are starting points to be tuned with the user during play-testing.
    var profile: DifficultyProfile {
        switch self {
        case .easy:
            return DifficultyProfile(
                startSpeed: 360, speedRampPer100m: 12, maxSpeed: 700,
                gapTime: 1.6...2.4,
                hazardWeights: [.barrel: 4, .narrowSpikes: 3, .bird: 2, .wideSpikes: 1, .rock: 1],
                coinPatternChance: 0.5
            )
        case .normal:
            return DifficultyProfile(
                startSpeed: 460, speedRampPer100m: 18, maxSpeed: 850,
                gapTime: 1.2...1.9,
                hazardWeights: [.barrel: 3, .narrowSpikes: 2, .bird: 3, .wideSpikes: 2, .rock: 2],
                coinPatternChance: 0.5
            )
        case .hard:
            return DifficultyProfile(
                startSpeed: 560, speedRampPer100m: 26, maxSpeed: 1000,
                gapTime: 0.9...1.5,
                hazardWeights: [.barrel: 3, .narrowSpikes: 2, .bird: 3, .wideSpikes: 3, .rock: 3],
                coinPatternChance: 0.5
            )
        }
    }
}

/// Numbers that define how a difficulty level plays.
struct DifficultyProfile: Equatable {
    /// World scroll speed at the start of a run, points per second.
    var startSpeed: Double
    /// Speed added for every 100 metres run.
    var speedRampPer100m: Double
    /// Speed never exceeds this.
    var maxSpeed: Double
    /// Extra time between one hazard passing and the next arriving, on top of the recovery time.
    var gapTime: ClosedRange<Double>
    /// Relative spawn weights per hazard type.
    var hazardWeights: [HazardType: Double]
    /// Probability that a hazard comes with a coin pattern.
    var coinPatternChance: Double

    func speed(atMetres metres: Double) -> Double {
        min(maxSpeed, startSpeed + speedRampPer100m * metres / 100)
    }
}
