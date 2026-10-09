import Foundation

protocol ScoreStore: AnyObject {
    func loadBestScore() -> StoredValue<Int>
    func saveBestScore(_ score: Int)
    func clearBestScore()
}

final class UserDefaultsScoreStore: ScoreStore {
    private let defaults: UserDefaults
    private let key = "bestScore.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadBestScore() -> StoredValue<Int> {
        guard let object = defaults.object(forKey: key) else { return .notSaved }
        guard let score = object as? Int, score >= 0 else { return .unreadable }
        return .loaded(score)
    }

    func saveBestScore(_ score: Int) {
        defaults.set(score, forKey: key)
    }

    func clearBestScore() {
        defaults.removeObject(forKey: key)
    }
}
