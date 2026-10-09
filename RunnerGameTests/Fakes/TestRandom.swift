@testable import RunnerGame

/// Deterministic pseudo-random numbers (SplitMix64).
final class SeededRandom: RandomSource {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    func nextUnit() -> Double {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return Double(z >> 11) / Double(1 << 53)
    }
}

/// Returns the given values in order, repeating.
final class ScriptedRandom: RandomSource {
    private let values: [Double]
    private var index = 0

    init(_ values: [Double]) {
        precondition(!values.isEmpty)
        self.values = values
    }

    func nextUnit() -> Double {
        defer { index = (index + 1) % values.count }
        return values[index]
    }
}
