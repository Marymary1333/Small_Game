import XCTest
@testable import RunnerGame

@MainActor
final class GameViewModelTests: XCTestCase {
    private let config = Sim.config

    private func makeGame(soundEnabled: Bool = true) -> (GameViewModel, GameEngine, FakeAudioService, SettingsViewModel) {
        let audio = FakeAudioService()
        let settings = SettingsViewModel(store: InMemorySettingsStore(), audio: audio)
        let engine = Sim.engine()
        let game = GameViewModel(engine: engine, audio: audio, soundEnabled: soundEnabled, settings: settings)
        return (game, engine, audio, settings)
    }

    func testCoinPlaysChimeAndUpdatesHUD() {
        let (game, engine, audio, _) = makeGame()
        engine.world.coins = [Coin(id: 1, x: 30, y: 30)]
        game.tick(dt: 1.0 / 60)
        XCTAssertEqual(audio.playedEffects, [.coin])
        XCTAssertEqual(game.coins, 1)
        XCTAssertEqual(game.score, 10)
    }

    func testLifeLostPlaysBuzzAndUpdatesHUD() {
        let (game, engine, audio, _) = makeGame()
        engine.world.hazards = [.barrel(id: 1, x: 20, config: config)]
        game.tick(dt: 1.0 / 60)
        XCTAssertEqual(audio.playedEffects, [.lifeLost])
        XCTAssertEqual(game.lives, 2)
        XCTAssertTrue(game.frameEvents.contains { if case .lifeLost = $0 { return true } else { return false } })
    }

    func testJumpPlaysNoSound() {
        let (game, engine, audio, _) = makeGame()
        game.upPressed()
        game.tick(dt: 1.0 / 60)
        XCTAssertFalse(engine.world.player.isOnGround)
        XCTAssertEqual(audio.playedEffects, [])
    }

    func testGameOverStopsMusicAndReportsResult() {
        let (game, engine, audio, _) = makeGame()
        engine.world.lives.loseLife(invincibility: 0)
        engine.world.lives.loseLife(invincibility: 0)
        engine.world.hazards = [.barrel(id: 1, x: 20, config: config)]
        var result: RunResult?
        game.onGameOver = { result = $0 }
        game.tick(dt: 1.0 / 60)
        XCTAssertTrue(game.isGameOver)
        XCTAssertEqual(game.lives, 0)
        XCTAssertTrue(audio.calls.contains(.stopMusic))
        XCTAssertEqual(result, RunResult(score: game.score, metres: game.metres, coins: game.coins))
    }

    func testSoundDisabledMakesNoAudioCallsButGameplayContinues() {
        let (game, engine, audio, _) = makeGame(soundEnabled: false)
        engine.world.coins = [Coin(id: 1, x: 30, y: 30)]
        engine.world.hazards = [.barrel(id: 2, x: 20, config: config)]
        game.begin()
        game.tick(dt: 1.0 / 60)
        game.escapePressed()
        game.escapePressed()
        game.quitToMenu()
        XCTAssertEqual(audio.calls, [])
        XCTAssertEqual(game.coins, 1)
        XCTAssertEqual(game.lives, 2)
    }

    func testMusicPlaysOnlyDuringRun() {
        let (game, _, audio, _) = makeGame()
        game.begin()
        XCTAssertEqual(audio.calls, [.playMusic])
        game.escapePressed()
        XCTAssertEqual(audio.calls.last, .pauseMusic)
        game.escapePressed()
        XCTAssertEqual(audio.calls.last, .playMusic)
        game.quitToMenu()
        XCTAssertEqual(audio.calls.last, .stopMusic)
    }

    func testEscapeTogglesPauseAndPauseFreezesWorld() {
        let (game, engine, _, _) = makeGame()
        game.tick(dt: 1.0 / 60)
        game.escapePressed()
        XCTAssertTrue(game.isPaused)
        let frozen = engine.world
        game.tick(dt: 1.0 / 60)
        game.upPressed()
        game.tick(dt: 1.0 / 60)
        XCTAssertEqual(engine.world, frozen)
        game.escapePressed()
        XCTAssertFalse(game.isPaused)
    }

    func testFocusLossPauses() {
        let (game, _, _, _) = makeGame()
        game.pauseForFocusLoss()
        XCTAssertTrue(game.isPaused)
        game.pauseForFocusLoss()
        XCTAssertTrue(game.isPaused, "focus loss never resumes")
    }

    func testDifficultyChangeAppliesImmediately() {
        let (game, engine, _, settings) = makeGame()
        settings.difficulty = .hard
        game.tick(dt: 1.0 / 60)
        XCTAssertEqual(engine.difficulty, .hard)
    }

    func testRestartAndQuitCallbacks() {
        let (game, _, _, _) = makeGame()
        var restarted = false
        var quit = false
        game.onRestart = { restarted = true }
        game.onQuitToMenu = { quit = true }
        game.restart()
        game.quitToMenu()
        XCTAssertTrue(restarted)
        XCTAssertTrue(quit)
    }
}
