import SwiftUI

struct MainMenuView: View {
    let viewModel: MenuViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text("RunnerGame")
                .font(.system(size: 56, weight: .heavy, design: .rounded))

            Text(viewModel.bestScoreText)
                .font(.title3)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                Button(action: viewModel.play) {
                    Text("Play").frame(width: 200)
                }
                .keyboardShortcut(.defaultAction)

                SettingsLink {
                    Text("Settings").frame(width: 200)
                }
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
