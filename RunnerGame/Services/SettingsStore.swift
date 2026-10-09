import Foundation

protocol SettingsStore: AnyObject {
    func loadSettings() -> StoredValue<GameSettings>
    func saveSettings(_ settings: GameSettings)
}

final class UserDefaultsSettingsStore: SettingsStore {
    private let defaults: UserDefaults
    private let key = "settings.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSettings() -> StoredValue<GameSettings> {
        guard defaults.object(forKey: key) != nil else { return .notSaved }
        guard let data = defaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(GameSettings.self, from: data) else {
            return .unreadable
        }
        return .loaded(settings)
    }

    func saveSettings(_ settings: GameSettings) {
        do {
            defaults.set(try JSONEncoder().encode(settings), forKey: key)
        } catch {
            // GameSettings holds only finite numbers and enums; encoding failure is a programming error.
            preconditionFailure("GameSettings failed to encode: \(error)")
        }
    }
}
