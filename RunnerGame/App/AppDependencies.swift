import Foundation

/// Composition root: the only place concrete services are created.
@MainActor
enum AppDependencies {
    static func makeAppViewModel() -> AppViewModel {
        let config = GameConfig.standard
        return AppViewModel(
            audio: ToneSynthAudioService(),
            settingsStore: UserDefaultsSettingsStore(),
            scoreStore: UserDefaultsScoreStore(),
            makeEngine: { difficulty in
                GameEngine(config: config, difficulty: difficulty, random: SystemRandomSource())
            }
        )
    }
}
