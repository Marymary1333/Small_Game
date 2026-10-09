import SpriteKit
import SwiftUI

struct GameView: View {
    let viewModel: GameViewModel

    @State private var scene: GameScene
    @FocusState private var isFocused: Bool
    @AppStorage(DebugOptions.showHitboxesKey) private var showHitboxes = false

    init(viewModel: GameViewModel) {
        self.viewModel = viewModel
        _scene = State(initialValue: GameScene(viewModel: viewModel))
    }

    var body: some View {
        ZStack(alignment: .top) {
            SpriteView(scene: scene, preferredFramesPerSecond: 120)
                .ignoresSafeArea()

            HUDView(lives: viewModel.lives, maxLives: viewModel.config.maxLives,
                    score: viewModel.score, metres: viewModel.metres, coins: viewModel.coins)

            if viewModel.isPaused {
                PauseMenuView(
                    onResume: viewModel.resume,
                    onRestart: viewModel.restart,
                    onQuitToMenu: viewModel.quitToMenu
                )
            }
        }
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onAppear {
            isFocused = true
            scene.showHitboxes = showHitboxes
        }
        .onChange(of: viewModel.isPaused) { _, paused in
            if !paused { isFocused = true }
        }
        .onChange(of: showHitboxes) { _, show in
            scene.showHitboxes = show
        }
        .onKeyPress(keys: [.upArrow, .downArrow, .escape], phases: [.down, .up]) { press in
            switch (press.key, press.phase) {
            case (.upArrow, .down): viewModel.upPressed()
            case (.downArrow, .down): viewModel.downChanged(isHeld: true)
            case (.downArrow, .up): viewModel.downChanged(isHeld: false)
            case (.escape, .down): viewModel.escapePressed()
            default: break
            }
            return .handled
        }
    }
}

struct HUDView: View {
    let lives: Int
    let maxLives: Int
    let score: Int
    let metres: Int
    let coins: Int

    var body: some View {
        HStack(alignment: .top) {
            HStack(spacing: 6) {
                ForEach(0..<maxLives, id: \.self) { index in
                    Image(systemName: index < lives ? "heart.fill" : "heart")
                        .foregroundStyle(.red)
                }
            }
            .font(.title)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Score \(score)").font(.title2.bold())
                Text("\(metres) m")
                Text("Coins \(coins)")
            }
            .monospacedDigit()
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.6), radius: 2)
        }
        .padding(20)
        .allowsHitTesting(false)
    }
}
