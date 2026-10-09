import Foundation
import Observation

enum AppAlert: Identifiable, Equatable {
    case settingsReset
    case bestScoreReset
    case soundUnavailable

    var id: Self { self }

    var title: String {
        switch self {
        case .settingsReset: return "Settings Reset"
        case .bestScoreReset: return "Best Score Reset"
        case .soundUnavailable: return "Sound Unavailable"
        }
    }

    var message: String {
        switch self {
        case .settingsReset: return "Settings couldn't be loaded and were reset."
        case .bestScoreReset: return "The best score couldn't be loaded and was reset."
        case .soundUnavailable: return "Sound is unavailable. The game will run without sound."
        }
    }
}

struct GameOverSummary: Equatable {
    let result: RunResult
    /// Nil only when no run has ever scored above zero.
    let bestScore: Int?
    let isNewBest: Bool
}

enum Screen: Equatable {
    case menu
    case playing(GameViewModel)
    case gameOver(GameOverSummary)

    static func == (lhs: Screen, rhs: Screen) -> Bool {
        switch (lhs, rhs) {
        case (.menu, .menu): return true
        case let (.playing(a), .playing(b)): return a === b
        case let (.gameOver(a), .gameOver(b)): return a == b
        default: return false
        }
    }
}

/// Screen navigation and app-wide state. Created once by the App layer.
@MainActor
@Observable
final class AppViewModel {
    private(set) var screen: Screen = .menu
    private(set) var alerts: [AppAlert] = []
    private(set) var bestScore: Int?

    let settings: SettingsViewModel
    let menu: MenuViewModel

    @ObservationIgnored private let audio: AudioService
    @ObservationIgnored private let scoreStore: ScoreStore
    @ObservationIgnored private let makeEngine: (Difficulty) -> GameEngine
    @ObservationIgnored private(set) var soundEnabled = false

    init(audio: AudioService, settingsStore: SettingsStore, scoreStore: ScoreStore,
         makeEngine: @escaping (Difficulty) -> GameEngine) {
        self.audio = audio
        self.scoreStore = scoreStore
        self.makeEngine = makeEngine
        self.settings = SettingsViewModel(store: settingsStore, audio: audio)
        self.menu = MenuViewModel(bestScore: nil)
        menu.onPlay = { [weak self] in self?.play() }
    }

    /// Loads persisted state and starts audio. Call once at launch.
    func launch() {
        if settings.didResetUnreadableSettings {
            alerts.append(.settingsReset)
        }

        switch scoreStore.loadBestScore() {
        case .notSaved:
            bestScore = nil
        case .loaded(let score):
            bestScore = score
        case .unreadable:
            bestScore = nil
            scoreStore.clearBestScore()
            alerts.append(.bestScoreReset)
        }
        menu.updateBestScore(bestScore)

        do {
            try audio.start()
            soundEnabled = true
            settings.enableSound()
        } catch {
            soundEnabled = false
            alerts.append(.soundUnavailable)
        }
    }

    var currentAlert: AppAlert? { alerts.first }

    func dismissAlert() {
        guard !alerts.isEmpty else { return }
        alerts.removeFirst()
    }

    func play() {
        let engine = makeEngine(settings.settings.difficulty)
        let game = GameViewModel(engine: engine, audio: audio, soundEnabled: soundEnabled, settings: settings)
        game.onGameOver = { [weak self] result in self?.finishRun(result) }
        game.onRestart = { [weak self] in self?.play() }
        game.onQuitToMenu = { [weak self] in self?.showMenu() }
        screen = .playing(game)
        game.begin()
    }

    func showMenu() {
        screen = .menu
    }

    func appDidResignActive() {
        if case .playing(let game) = screen {
            game.pauseForFocusLoss()
        }
    }

    private func finishRun(_ result: RunResult) {
        let previous = bestScore
        let isNewBest = previous.map { result.score > $0 } ?? (result.score > 0)
        if isNewBest {
            bestScore = result.score
            scoreStore.saveBestScore(result.score)
            menu.updateBestScore(result.score)
        }
        screen = .gameOver(GameOverSummary(result: result, bestScore: bestScore, isNewBest: isNewBest))
    }
}
