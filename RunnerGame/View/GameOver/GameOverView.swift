import SwiftUI

struct GameOverView: View {
    let summary: GameOverSummary
    let onPlayAgain: () -> Void
    let onMainMenu: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Game Over")
                .font(.system(size: 48, weight: .heavy, design: .rounded))

            if summary.isNewBest {
                Text("New best!")
                    .font(.title2.bold())
                    .foregroundStyle(.orange)
            }

            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 8) {
                row("Score", "\(summary.result.score)")
                row("Distance", "\(summary.result.metres) m")
                row("Coins", "\(summary.result.coins)")
                row("Best score", summary.bestScore.map(String.init) ?? "—")
            }
            .font(.title3)

            HStack(spacing: 12) {
                Button(action: onPlayAgain) { Text("Play Again").frame(width: 140) }
                    .keyboardShortcut(.defaultAction)
                Button(action: onMainMenu) { Text("Main Menu").frame(width: 140) }
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func row(_ title: String, _ value: String) -> some View {
        GridRow {
            Text(title).foregroundStyle(.secondary)
            Text(value).monospacedDigit().bold()
        }
    }
}
