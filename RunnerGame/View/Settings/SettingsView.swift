import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("Volume") {
                volumeSlider("Music", value: $viewModel.musicVolume)
                volumeSlider("Effects", value: $viewModel.effectsVolume)
            }

            Section("Game") {
                Picker("Difficulty", selection: $viewModel.difficulty) {
                    ForEach(Difficulty.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.segmented)

                Picker("Background", selection: $viewModel.theme) {
                    ForEach(BackgroundTheme.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.segmented)

                Picker("Character", selection: $viewModel.character) {
                    ForEach(CharacterSkin.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
    }

    private func volumeSlider(_ title: String, value: Binding<Double>) -> some View {
        LabeledContent(title) {
            HStack {
                Slider(value: value, in: 0...1)
                Text("\(Int((value.wrappedValue * 100).rounded()))%")
                    .monospacedDigit()
                    .frame(width: 44, alignment: .trailing)
            }
        }
    }
}
