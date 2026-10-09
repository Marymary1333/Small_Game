import SwiftUI

@main
struct RunnerGameApp: App {
    @State private var appViewModel: AppViewModel

    init() {
        let viewModel = AppDependencies.makeAppViewModel()
        viewModel.launch()
        _appViewModel = State(initialValue: viewModel)
    }

    var body: some Scene {
        WindowGroup {
            RootView(app: appViewModel)
                .frame(minWidth: 960, minHeight: 540)
        }
        .windowResizability(.contentMinSize)
        .commands {
            DebugCommands()
        }

        Settings {
            SettingsView(viewModel: appViewModel.settings)
        }
    }
}

/// Development-only tools.
struct DebugCommands: Commands {
    @AppStorage(DebugOptions.showHitboxesKey) private var showHitboxes = false

    var body: some Commands {
        #if DEBUG
        CommandMenu("Debug") {
            Toggle("Show Hitboxes", isOn: $showHitboxes)
                .keyboardShortcut("h", modifiers: [.command, .shift])
        }
        #endif
    }
}

enum DebugOptions {
    static let showHitboxesKey = "debug.showHitboxes"
}
