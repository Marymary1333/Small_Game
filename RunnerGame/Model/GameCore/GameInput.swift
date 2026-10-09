import Foundation

/// Player input for one engine step.
struct GameInput: Equatable {
    /// ↑ was pressed since the last step (edge, consumed by the engine).
    var jumpPressed: Bool = false
    /// ↓ is currently held.
    var duckHeld: Bool = false
}
