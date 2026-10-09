import Foundation
import Observation

@MainActor
@Observable
final class MenuViewModel {
    private(set) var bestScore: Int?

    @ObservationIgnored var onPlay: () -> Void = {}

    init(bestScore: Int?) {
        self.bestScore = bestScore
    }

    var bestScoreText: String {
        bestScore.map { "Best score: \($0)" } ?? "No best score yet"
    }

    func updateBestScore(_ score: Int?) {
        bestScore = score
    }

    func play() {
        onPlay()
    }
}
