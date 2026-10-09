import XCTest
@testable import RunnerGame

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testEmptyStoreUsesFirstLaunchSettingsWithoutReset() {
        let store = InMemorySettingsStore(.notSaved)
        let vm = SettingsViewModel(store: store, audio: FakeAudioService())
        XCTAssertEqual(vm.settings, GameSettings(musicVolume: 0.7, effectsVolume: 0.7, difficulty: .easy, theme: .forest, character: .cat))
        XCTAssertFalse(vm.didResetUnreadableSettings)
        XCTAssertEqual(store.saved, [])
    }

    func testUnreadableSettingsResetAndSave() {
        let store = InMemorySettingsStore(.unreadable)
        let vm = SettingsViewModel(store: store, audio: FakeAudioService())
        XCTAssertEqual(vm.settings, .firstLaunch)
        XCTAssertTrue(vm.didResetUnreadableSettings)
        XCTAssertEqual(store.saved, [.firstLaunch])
    }

    func testSavedSettingsAreUsed() {
        let saved = GameSettings(musicVolume: 0.1, effectsVolume: 0.9, difficulty: .hard, theme: .space, character: .bear)
        let vm = SettingsViewModel(store: InMemorySettingsStore(.loaded(saved)), audio: FakeAudioService())
        XCTAssertEqual(vm.settings, saved)
    }

    func testChangesAreSaved() {
        let store = InMemorySettingsStore()
        let vm = SettingsViewModel(store: store, audio: FakeAudioService())
        vm.theme = .snow
        vm.character = .fox
        vm.difficulty = .normal
        XCTAssertEqual(store.saved.last, GameSettings(musicVolume: 0.7, effectsVolume: 0.7, difficulty: .normal, theme: .snow, character: .fox))
    }

    func testVolumesReachAudioOnlyAfterSoundEnabled() {
        let audio = FakeAudioService()
        let vm = SettingsViewModel(store: InMemorySettingsStore(), audio: audio)
        vm.musicVolume = 0.3
        XCTAssertEqual(audio.calls, [])
        vm.enableSound()
        XCTAssertEqual(audio.calls, [.musicVolume(0.3), .effectsVolume(0.7)])
        vm.effectsVolume = 0.2
        XCTAssertEqual(audio.calls.suffix(2), [.musicVolume(0.3), .effectsVolume(0.2)])
    }

    func testUserDefaultsSettingsRoundTrip() throws {
        let (defaults, name) = try freshDefaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let store = UserDefaultsSettingsStore(defaults: defaults)
        XCTAssertEqual(store.loadSettings(), .notSaved)
        let settings = GameSettings(musicVolume: 0.25, effectsVolume: 0.5, difficulty: .hard, theme: .snow, character: .fox)
        store.saveSettings(settings)
        XCTAssertEqual(UserDefaultsSettingsStore(defaults: defaults).loadSettings(), .loaded(settings))
    }

    func testCorruptedSettingsAreUnreadable() throws {
        let (defaults, name) = try freshDefaults()
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(Data("not json".utf8), forKey: "settings.v1")
        XCTAssertEqual(UserDefaultsSettingsStore(defaults: defaults).loadSettings(), .unreadable)
        defaults.set(42, forKey: "settings.v1")
        XCTAssertEqual(UserDefaultsSettingsStore(defaults: defaults).loadSettings(), .unreadable)
    }

    func testBestScoreStore() throws {
        let (defaults, name) = try freshDefaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let store = UserDefaultsScoreStore(defaults: defaults)
        XCTAssertEqual(store.loadBestScore(), .notSaved)
        store.saveBestScore(321)
        XCTAssertEqual(store.loadBestScore(), .loaded(321))
        defaults.set("oops", forKey: "bestScore.v1")
        XCTAssertEqual(store.loadBestScore(), .unreadable)
        defaults.set(-5, forKey: "bestScore.v1")
        XCTAssertEqual(store.loadBestScore(), .unreadable)
        store.clearBestScore()
        XCTAssertEqual(store.loadBestScore(), .notSaved)
    }

    private func freshDefaults() throws -> (UserDefaults, String) {
        let name = "RunnerGameTests.\(UUID().uuidString)"
        return (try XCTUnwrap(UserDefaults(suiteName: name)), name)
    }
}
