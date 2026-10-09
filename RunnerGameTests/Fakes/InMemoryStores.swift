@testable import RunnerGame

final class InMemorySettingsStore: SettingsStore {
    var stored: StoredValue<GameSettings>
    private(set) var saved: [GameSettings] = []

    init(_ stored: StoredValue<GameSettings> = .notSaved) {
        self.stored = stored
    }

    func loadSettings() -> StoredValue<GameSettings> { stored }

    func saveSettings(_ settings: GameSettings) {
        saved.append(settings)
        stored = .loaded(settings)
    }
}

final class InMemoryScoreStore: ScoreStore {
    var stored: StoredValue<Int>
    private(set) var clearCount = 0

    init(_ stored: StoredValue<Int> = .notSaved) {
        self.stored = stored
    }

    func loadBestScore() -> StoredValue<Int> { stored }
    func saveBestScore(_ score: Int) { stored = .loaded(score) }

    func clearBestScore() {
        clearCount += 1
        stored = .notSaved
    }
}
