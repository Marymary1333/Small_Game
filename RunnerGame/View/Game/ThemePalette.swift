import SpriteKit

/// Phase 1 colours for each background theme.
struct ThemePalette {
    let sky: SKColor
    let skyDecoration: SKColor
    let far: SKColor
    let near: SKColor
    let nearAccent: SKColor
    let ground: SKColor
    let groundMark: SKColor

    static func palette(for theme: BackgroundTheme) -> ThemePalette {
        switch theme {
        case .forest:
            return ThemePalette(
                sky: SKColor(red: 0.62, green: 0.84, blue: 0.96, alpha: 1),
                skyDecoration: SKColor(white: 1, alpha: 0.9),
                far: SKColor(red: 0.18, green: 0.42, blue: 0.26, alpha: 1),
                near: SKColor(red: 0.13, green: 0.55, blue: 0.22, alpha: 1),
                nearAccent: SKColor(red: 0.42, green: 0.27, blue: 0.14, alpha: 1),
                ground: SKColor(red: 0.30, green: 0.62, blue: 0.24, alpha: 1),
                groundMark: SKColor(red: 0.22, green: 0.48, blue: 0.18, alpha: 1)
            )
        case .snow:
            return ThemePalette(
                sky: SKColor(red: 0.86, green: 0.92, blue: 0.97, alpha: 1),
                skyDecoration: SKColor(white: 1, alpha: 0.95),
                far: SKColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1),
                near: SKColor(red: 0.22, green: 0.40, blue: 0.34, alpha: 1),
                nearAccent: SKColor(white: 1, alpha: 1),
                ground: SKColor(white: 0.97, alpha: 1),
                groundMark: SKColor(red: 0.80, green: 0.86, blue: 0.92, alpha: 1)
            )
        case .space:
            return ThemePalette(
                sky: SKColor(red: 0.04, green: 0.04, blue: 0.12, alpha: 1),
                skyDecoration: SKColor(white: 1, alpha: 0.9),
                far: SKColor(red: 0.55, green: 0.35, blue: 0.70, alpha: 1),
                near: SKColor(red: 0.30, green: 0.30, blue: 0.36, alpha: 1),
                nearAccent: SKColor(red: 0.20, green: 0.20, blue: 0.25, alpha: 1),
                ground: SKColor(red: 0.45, green: 0.45, blue: 0.50, alpha: 1),
                groundMark: SKColor(red: 0.35, green: 0.35, blue: 0.40, alpha: 1)
            )
        }
    }
}
