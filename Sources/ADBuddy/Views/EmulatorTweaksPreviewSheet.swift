import SwiftUI

struct EmulatorTweaksPreviewSheet: View {
    @Binding var acceptsSigning: Bool
    let isApplied: Bool
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
                    preview("Without", tag: "ugly", color: .orange, filename: "emulator-app-switcher-before",
                            description: "Three identical circular Android emulator icons with the generic qemu-system-aarch64 label.")
                    preview("With", tag: "pretty", color: .green, filename: "emulator-app-switcher-after",
                            description: "Distinct tablet, phone and watch icons with the selected phone labeled Pixel_9.")
                }
                Text("Applies to every launch through this Android SDK, including Terminal and Android Studio. Restart running emulators to see the change. Supported builds only; Node.js must remain installed for AVD naming.")
                    .font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }.padding(.horizontal, 24).padding(.bottom, 20)

            Divider()
            if isApplied {
                HStack {
                    Text("Your emulators are already pretty.").foregroundStyle(.secondary)
                    Spacer()
                    Button("Done", action: cancel).keyboardShortcut(.defaultAction)
                }.padding(24)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Signing and restoration", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                        Text("Changing the emulator’s icons and app names modifies its executable, so Google’s original signature can no longer remain valid. ADBuddy replaces it with a local ad-hoc signature so macOS can run the modified emulator.\n\nThe patch preserves entitlements and hardened runtime. No developer certificate or private key is used. The emulator is no longer Google-signed or notarized, and macOS’s security check (Gatekeeper) may treat it differently.\n\nRestore Original reinstates the exact backed-up executable, including Google’s signature.")
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
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
                        Button("Make Pretty", action: apply)
                            .disabled(!canApply || !acceptsSigning)
                            .keyboardShortcut(.defaultAction)
                    }
                }.padding(24)
            }
        }
        .frame(width: 960)
    }

    @ViewBuilder
    private func preview(_ title: String, tag: String, color: Color, filename: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(tag)
                    .font(.caption.bold())
                    .foregroundStyle(color)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 5))
                Text(title).font(.headline)
                Link(destination: URL(string: "https://github.com/androperator/android-emulator-macos-tweaks")!) {
                    Text("androperator-emulator-tweaks:").font(.system(.caption, design: .monospaced).bold())
                }
            }
            if let url = Bundle.main.url(forResource: filename, withExtension: "png", subdirectory: "EmulatorTweaks"),
               let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable().scaledToFill()
                    .frame(height: 130).clipped()
                    .accessibilityLabel(description)
            } else {
                Text(description).font(.callout)
            }
        }
    }
}
