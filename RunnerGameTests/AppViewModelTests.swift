import XCTest
@testable import RunnerGame

@MainActor
final class AppViewModelTests: XCTestCase {
    private struct StartFailure: Error {}

    private var audio: FakeAudioService!
    private var settingsStore: InMemorySettingsStore!
    private var scoreStore: InMemoryScoreStore!
    private var prepareEngine: (GameEngine) -> Void = { _ in }

    override func setUp() {
        super.setUp()
        audio = FakeAudioService()
        settingsStore = InMemorySettingsStore()
        scoreStore = InMemoryScoreStore()
        prepareEngine = { _ in }
    }

    private func makeApp() -> AppViewModel {
        AppViewModel(audio: audio, settingsStore: settingsStore, scoreStore: scoreStore) { [unowned self] difficulty in
            let engine = GameEngine(config: Sim.config, difficulty: difficulty, random: SeededRandom(seed: 9), spawningEnabled: false)
            self.prepareEngine(engine)
            return engine
        }
    }

    func testCleanLaunchHasNoAlertsAndStartsAudio() {
        let app = makeApp()
        app.launch()
        XCTAssertEqual(app.alerts, [])
        XCTAssertTrue(app.soundEnabled)
        XCTAssertEqual(audio.calls, [.start, .musicVolume(0.7), .effectsVolume(0.7)])
        XCTAssertNil(app.bestScore)
        XCTAssertEqual(app.screen, .menu)
    }

    func testAudioFailureShowsAlertAndDisablesSound() {
        audio.startError = StartFailure()
        let app = makeApp()
        app.launch()
        XCTAssertEqual(app.alerts, [.soundUnavailable])
        XCTAssertFalse(app.soundEnabled)
        XCTAssertEqual(audio.calls, [.start])
    }

    func testUnreadableSettingsAndScoreShowAlertsAndReset() {
        settingsStore.stored = .unreadable
        scoreStore.stored = .unreadable
        let app = makeApp()
        app.launch()
        XCTAssertEqual(app.alerts, [.settingsReset, .bestScoreReset])
        XCTAssertEqual(app.settings.settings, .firstLaunch)
        XCTAssertEqual(scoreStore.clearCount, 1)
        XCTAssertNil(app.bestScore)
        app.dismissAlert()
        XCTAssertEqual(app.currentAlert, .bestScoreReset)
        app.dismissAlert()
        XCTAssertNil(app.currentAlert)
    }

    func testSavedBestScoreShownOnMenu() {
        scoreStore.stored = .loaded(250)
        let app = makeApp()
        app.launch()
        XCTAssertEqual(app.menu.bestScoreText, "Best score: 250")
    }

    func testRunEndingSavesNewBest() throws {
        let app = makeApp()
        app.launch()
        prepareEngine = { engine in
            engine.world.player.x = 500 * Sim.config.pointsPerMetre
            engine.world.lives.loseLife(invincibility: 0)
            engine.world.lives.loseLife(invincibility: 0)
            engine.world.hazards = [.barrel(id: 1, x: engine.world.player.x + 20, config: Sim.config)]
        }
        app.menu.play()
        guard case .playing(let game) = app.screen else { return XCTFail("expected playing") }
        game.tick(dt: 1.0 / 60)

        guard case .gameOver(let summary) = app.screen else { return XCTFail("expected game over") }
        XCTAssertTrue(summary.isNewBest)
        XCTAssertEqual(summary.bestScore, summary.result.score)
        XCTAssertEqual(scoreStore.stored, .loaded(summary.result.score))
        XCTAssertEqual(app.menu.bestScore, summary.result.score)
    }

    func testLowerScoreIsNotNewBest() {
        scoreStore.stored = .loaded(1_000_000)
        let app = makeApp()
        app.launch()
        prepareEngine = { engine in
            engine.world.lives.loseLife(invincibility: 0)
            engine.world.lives.loseLife(invincibility: 0)
            engine.world.hazards = [.barrel(id: 1, x: 20, config: Sim.config)]
        }
        app.play()
        guard case .playing(let game) = app.screen else { return XCTFail("expected playing") }
        game.tick(dt: 1.0 / 60)
        guard case .gameOver(let summary) = app.screen else { return XCTFail("expected game over") }
        XCTAssertFalse(summary.isNewBest)
        XCTAssertEqual(summary.bestScore, 1_000_000)
        XCTAssertEqual(scoreStore.stored, .loaded(1_000_000))
    }

    func testFocusLossPausesRunningGame() {
        let app = makeApp()
        app.launch()
        app.play()
        guard case .playing(let game) = app.screen else { return XCTFail("expected playing") }
        app.appDidResignActive()
        XCTAssertTrue(game.isPaused)
    }

    func testPauseMenuNavigation() {
        let app = makeApp()
        app.launch()
        app.play()
        guard case .playing(let first) = app.screen else { return XCTFail("expected playing") }
        first.restart()
        guard case .playing(let second) = app.screen else { return XCTFail("expected playing") }
        XCTAssertFalse(first === second)
        second.quitToMenu()
        XCTAssertEqual(app.screen, .menu)
    }
}
