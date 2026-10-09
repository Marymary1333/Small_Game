import AppKit
import SwiftUI

struct RootView: View {
    let app: AppViewModel

    var body: some View {
        ZStack {
            switch app.screen {
            case .menu:
                MainMenuView(viewModel: app.menu)
            case .playing(let game):
                GameView(viewModel: game)
                    .id(ObjectIdentifier(game))
            case .gameOver(let summary):
                GameOverView(summary: summary, onPlayAgain: app.play, onMainMenu: app.showMenu)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            app.appDidResignActive()
        }
        .alert(
            Text(app.currentAlert?.title ?? ""),
            isPresented: Binding(
                get: { app.currentAlert != nil },
                set: { isPresented in if !isPresented { app.dismissAlert() } }
            ),
            presenting: app.currentAlert
        ) { _ in
            Button("OK") {}
        } message: { alert in
            Text(alert.message)
        }
    }
}
