import Foundation
import Observation

struct RunResult: Equatable {
    let score: Int
    let metres: Int
    let coins: Int
}

@MainActor
@Observable
final class GameViewModel {
    // HUD state: changes a few times per second at most, so SwiftUI observes it.
    private(set) var lives: Int
    private(set) var metres = 0
    private(set) var coins = 0
    private(set) var score = 0
    private(set) var isPaused = false
    private(set) var isGameOver = false

    // Per-frame state: read by the SpriteKit scene each frame, not observed.
    var world: World { engine.world }
    @ObservationIgnored private(set) var frameEvents: [GameEvent] = []
    @ObservationIgnored let config: GameConfig

    @ObservationIgnored var onGameOver: (RunResult) -> Void = { _ in }
    @ObservationIgnored var onRestart: () -> Void = {}
    @ObservationIgnored var onQuitToMenu: () -> Void = {}

    @ObservationIgnored private let engine: GameEngine
    @ObservationIgnored private let audio: AudioService
    @ObservationIgnored private let soundEnabled: Bool
    @ObservationIgnored private let settingsProvider: SettingsProviding
    @ObservationIgnored private var jumpPressed = false
    @ObservationIgnored private var duckHeld = false

    init(engine: GameEngine, audio: AudioService, soundEnabled: Bool, settings: SettingsProviding) {
        self.engine = engine
        self.config = engine.config
        self.audio = audio
        self.soundEnabled = soundEnabled
        self.settingsProvider = settings
        self.lives = engine.world.lives.remaining
    }

    var theme: BackgroundTheme { settingsProvider.settings.theme }
    var character: CharacterSkin { settingsProvider.settings.character }

    // MARK: Lifecycle

    func begin() {
        if soundEnabled { audio.playMusic() }
    }

    func tick(dt: Double) {
        frameEvents = []
        guard !isPaused, !isGameOver else { return }
        engine.difficulty = settingsProvider.settings.difficulty
        let events = engine.step(dt: dt, input: GameInput(jumpPressed: jumpPressed, duckHeld: duckHeld))
        jumpPressed = false
        frameEvents = events

        for event in events {
            switch event {
            case .coinCollected:
                if soundEnabled { audio.play(.coin) }
            case .lifeLost:
                if soundEnabled { audio.play(.lifeLost) }
            case .gameOver:
                isGameOver = true
                if soundEnabled { audio.stopMusic() }
            case .jumped, .doubleJumped:
                break
            }
        }
        refreshHUD()
        if isGameOver {
            onGameOver(RunResult(score: score, metres: metres, coins: coins))
        }
    }

    // MARK: Input intents

    func upPressed() {
        guard !isPaused, !isGameOver else { return }
        jumpPressed = true
    }

    func downChanged(isHeld: Bool) {
        duckHeld = isHeld
    }

    func escapePressed() {
        guard !isGameOver else { return }
        isPaused ? resume() : pause()
    }

    func pauseForFocusLoss() {
        guard !isGameOver, !isPaused else { return }
        pause()
    }

    // MARK: Pause menu

    func resume() {
        guard isPaused else { return }
        isPaused = false
        if soundEnabled { audio.playMusic() }
    }

    func restart() {
        if soundEnabled { audio.stopMusic() }
        onRestart()
    }

    func quitToMenu() {
        if soundEnabled { audio.stopMusic() }
        onQuitToMenu()
    }

    // MARK: Private

    private func pause() {
        isPaused = true
        duckHeld = false
        if soundEnabled { audio.pauseMusic() }
    }

    private func refreshHUD() {
        let w = engine.world
        if lives != w.lives.remaining { lives = w.lives.remaining }
        let m = w.metres(config: config)
        if metres != m { metres = m }
        if coins != w.coinsCollected { coins = w.coinsCollected }
        let s = w.score(config: config)
        if score != s { score = s }
    }
}
