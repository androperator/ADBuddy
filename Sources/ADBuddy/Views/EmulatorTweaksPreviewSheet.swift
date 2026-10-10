import SwiftUI

struct EmulatorTweaksPreviewSheet: View {
    @Binding var acceptsSigning: Bool
    let canApply: Bool
    let cancel: () -> Void
    let apply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Make Android emulators feel at home on macOS.")
                    .font(.title2.bold())
                Text("Distinct device icons and AVD names in the Dock and Cmd-Tab.")
                    .foregroundStyle(.secondary)
            }.padding(24)

            VStack(alignment: .leading, spacing: 16) {
                Text("ADBuddy bundles an open-source utility that adds these appearance tweaks.")
                    .font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(alignment: .top, spacing: 16) {
                    preview("With", filename: "emulator-app-switcher-after",
                            description: "Distinct tablet, phone and watch icons with the selected phone labeled Pixel_9.")
                    preview("Without", filename: "emulator-app-switcher-before",
                            description: "Three identical circular Android emulator icons with the generic qemu-system-aarch64 label.")
                }
                Text("Applies to every launch through this Android SDK, including Terminal and Android Studio. Restart running emulators to see the change. Supported builds only; Node.js must remain installed for AVD naming.")
                    .font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }.padding(.horizontal, 24).padding(.bottom, 20)

            Divider()
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Signing and restoration", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    Text("Applying replaces Google’s signature with a local ad-hoc signature, preserving entitlements and hardened runtime. The emulator is no longer Google-signed or notarized, and macOS’s security check (Gatekeeper) may treat it differently. No developer certificate or private key is used. Restore Original reinstates the exact backed-up executable and Google’s signature.")
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                    Toggle("I accept the ad-hoc signing tradeoff", isOn: $acceptsSigning)
                }
                .padding(16)
                .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.orange.opacity(0.65), lineWidth: 1)
                }
                HStack {
                    if !canApply {
                        Text("Apply is unavailable for the current SDK. Check its status in Settings.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Cancel", action: cancel).keyboardShortcut(.cancelAction)
                    Button("Apply Tweaks", action: apply)
                        .disabled(!canApply || !acceptsSigning)
                        .keyboardShortcut(.defaultAction)
                }
            }.padding(24)
        }
        .frame(width: 640)
    }

    @ViewBuilder
    private func preview(_ title: String, filename: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Link(destination: URL(string: "https://github.com/androperator/android-emulator-macos-tweaks")!) {
                    Text("androperator-emulator-tweaks").font(.system(.caption, design: .monospaced).bold())
                }
            }
            if let url = Bundle.main.url(forResource: filename, withExtension: "png", subdirectory: "EmulatorTweaks"),
               let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable().scaledToFill()
                    .frame(height: 84).clipped()
                    .accessibilityLabel(description)
            } else {
                Text(description).font(.callout)
            }
        }
    }
}
