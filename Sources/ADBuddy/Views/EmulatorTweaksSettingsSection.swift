import SwiftUI

struct EmulatorTweaksSettingsSection: View {
    let nodePath: String
    @State private var store = EmulatorTweaksStore()
    @State private var showsSigningConfirmation = false
    @State private var acceptsSigning = false

    var body: some View {
        Section("macOS emulator appearance") {
            Text("Optional device icons and AVD names in the Dock and Cmd-Tab.")
            Text(store.status?.summary ?? "Check the SDK to see whether tweaks are available.")
                .font(.callout).foregroundStyle(.secondary)
            if let revision = store.status?.revision {
                Text("Android Emulator \(revision)").font(.caption)
            }
            HStack {
                Button("Refresh Status") {
                    Task { await store.run(.status, nodePath: nodePath) }
                }
                Button("Apply Tweaks…") {
                    acceptsSigning = false
                    showsSigningConfirmation = true
                }.disabled(store.status?.canApply != true)
                Button("Restore Original") {
                    Task { await store.run(.restore, nodePath: nodePath) }
                }.disabled(store.status?.canRestore != true)
                if store.isBusy { ProgressView().controlSize(.small) }
            }.disabled(store.isBusy)
            if let message = store.message {
                Text(message).font(.callout).textSelection(.enabled)
            }
            Text("Affects every launch through this SDK, including Terminal and Android Studio. Supported builds only; backups can also be restored with the standalone CLI. Node.js must remain installed for AVD naming.")
                .font(.caption).foregroundStyle(.secondary)
            if let backup = store.status?.backup {
                DisclosureGroup("Backup location") {
                    Text(backup).font(.caption).textSelection(.enabled)
                }
            }
        }
        .task(id: nodePath) { await store.run(.status, nodePath: nodePath) }
        .sheet(isPresented: $showsSigningConfirmation) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Apply Emulator Tweaks?").font(.headline)
                Text("This replaces Google’s signature with a local ad-hoc signature while preserving entitlements and hardened runtime. The modified emulator is no longer Google-signed or notarized, and Gatekeeper may treat it differently. No developer certificate or private key is used.")
                Text("The exact original is backed up. Restore Original reinstates its bytes and Google’s signature. Running emulators keep their current appearance until restarted.")
                Toggle("I accept the ad-hoc signing tradeoff", isOn: $acceptsSigning)
                HStack {
                    Spacer()
                    Button("Cancel") { showsSigningConfirmation = false }
                        .keyboardShortcut(.cancelAction)
                    Button("Apply Tweaks") {
                        showsSigningConfirmation = false
                        Task { await store.run(.apply, nodePath: nodePath, acceptsSigning: true) }
                    }
                    .disabled(!acceptsSigning)
                    .keyboardShortcut(.defaultAction)
                }
            }.padding(24).frame(width: 470)
        }
    }
}
