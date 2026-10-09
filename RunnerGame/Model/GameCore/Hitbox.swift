import Foundation

/// Axis-aligned rectangle in world coordinates. y = 0 is the ground surface, y grows upward.
struct Hitbox: Equatable {
    var minX: Double
    var minY: Double
    var width: Double
    var height: Double

    var maxX: Double { minX + width }
    var maxY: Double { minY + height }

    /// True when the rectangles share interior area. Touching edges do not count.
    func overlaps(_ other: Hitbox) -> Bool {
        minX < other.maxX && maxX > other.minX &&
        minY < other.maxY && maxY > other.minY
    }

    /// Shrinks the box by `fraction` of its size in total, keeping the centre.
    func inset(by fraction: Double) -> Hitbox {
        let dx = width * fraction / 2
        let dy = height * fraction / 2
        return Hitbox(minX: minX + dx, minY: minY + dy, width: width - 2 * dx, height: height - 2 * dy)
    }
}
