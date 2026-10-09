import Foundation

/// Source of random numbers, injectable so tests can use a fixed seed.
protocol RandomSource: AnyObject {
    /// Uniform value in 0..<1.
    func nextUnit() -> Double
}

extension RandomSource {
    func double(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + (range.upperBound - range.lowerBound) * nextUnit()
    }

    func chance(_ probability: Double) -> Bool {
        nextUnit() < probability
    }

    /// Picks a key with probability proportional to its weight. Weights must sum to more than zero.
    func pick<Key: Hashable & Comparable>(weighted weights: [Key: Double]) -> Key {
        let entries = weights.filter { $0.value > 0 }.sorted { $0.key < $1.key }
        let total = entries.reduce(0) { $0 + $1.value }
        precondition(total > 0, "At least one weight must be positive")
        var roll = nextUnit() * total
        for entry in entries {
            if roll < entry.value { return entry.key }
            roll -= entry.value
        }
        return entries[entries.count - 1].key
    }
}

final class SystemRandomSource: RandomSource {
    private var generator = SystemRandomNumberGenerator()

    func nextUnit() -> Double {
        Double.random(in: 0..<1, using: &generator)
    }
}
