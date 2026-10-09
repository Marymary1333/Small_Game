@testable import RunnerGame

final class FakeAudioService: AudioService {
    enum Call: Equatable {
        case start, play(SoundEffect), playMusic, pauseMusic, stopMusic
        case musicVolume(Double), effectsVolume(Double)
    }

    var startError: Error?
    private(set) var calls: [Call] = []

    var playedEffects: [SoundEffect] {
        calls.compactMap { if case .play(let effect) = $0 { return effect } else { return nil } }
    }

    func start() throws {
        calls.append(.start)
        if let startError { throw startError }
    }

    func play(_ effect: SoundEffect) { calls.append(.play(effect)) }
    func playMusic() { calls.append(.playMusic) }
    func pauseMusic() { calls.append(.pauseMusic) }
    func stopMusic() { calls.append(.stopMusic) }
    func setMusicVolume(_ volume: Double) { calls.append(.musicVolume(volume)) }
    func setEffectsVolume(_ volume: Double) { calls.append(.effectsVolume(volume)) }
}
