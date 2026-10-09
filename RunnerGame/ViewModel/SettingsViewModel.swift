import Foundation
import Observation

/// Read access to the current settings for other ViewModels.
@MainActor
protocol SettingsProviding: AnyObject {
    var settings: GameSettings { get }
}

@MainActor
@Observable
final class SettingsViewModel: SettingsProviding {
    private(set) var settings: GameSettings
    /// True when saved settings could not be read and were reset (confirmed fallback).
    let didResetUnreadableSettings: Bool

    @ObservationIgnored private let store: SettingsStore
    @ObservationIgnored private let audio: AudioService
    @ObservationIgnored private var soundEnabled = false

    init(store: SettingsStore, audio: AudioService) {
        self.store = store
        self.audio = audio
        switch store.loadSettings() {
        case .notSaved:
            settings = .firstLaunch
            didResetUnreadableSettings = false
        case .loaded(let saved):
            settings = saved
            didResetUnreadableSettings = false
        case .unreadable:
            settings = .firstLaunch
            didResetUnreadableSettings = true
            store.saveSettings(.firstLaunch)
        }
    }

    /// Called once audio has started successfully; pushes the current volumes.
    func enableSound() {
        soundEnabled = true
        applyVolumes()
    }

    var musicVolume: Double {
        get { settings.musicVolume }
        set { update { $0.musicVolume = newValue } }
    }

    var effectsVolume: Double {
        get { settings.effectsVolume }
        set { update { $0.effectsVolume = newValue } }
    }

    var difficulty: Difficulty {
        get { settings.difficulty }
        set { update { $0.difficulty = newValue } }
    }

    var theme: BackgroundTheme {
        get { settings.theme }
        set { update { $0.theme = newValue } }
    }

    var character: CharacterSkin {
        get { settings.character }
        set { update { $0.character = newValue } }
    }

    private func update(_ change: (inout GameSettings) -> Void) {
        var next = settings
        change(&next)
        guard next != settings else { return }
        settings = next
        store.saveSettings(next)
        applyVolumes()
    }

    private func applyVolumes() {
        guard soundEnabled else { return }
        audio.setMusicVolume(settings.musicVolume)
        audio.setEffectsVolume(settings.effectsVolume)
    }
}
