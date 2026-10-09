import Foundation

/// Things that happened during an engine step. The engine has no side effects;
/// ViewModels react to these (sounds, HUD, screen changes, visual effects).
enum GameEvent: Equatable {
    case jumped
    case doubleJumped
    case coinCollected(Coin)
    case lifeLost(brokenHazard: Hazard)
    case gameOver
}
