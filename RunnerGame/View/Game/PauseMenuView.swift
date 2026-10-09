import SwiftUI

struct PauseMenuView: View {
    let onResume: () -> Void
    let onRestart: () -> Void
    let onQuitToMenu: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Paused")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.bottom, 8)

                Button(action: onResume) { Text("Resume").frame(width: 180) }
                Button(action: onRestart) { Text("Restart").frame(width: 180) }
                Button(action: onQuitToMenu) { Text("Quit to Menu").frame(width: 180) }
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
