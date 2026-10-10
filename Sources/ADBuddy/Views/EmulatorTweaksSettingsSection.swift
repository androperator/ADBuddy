import SwiftUI

struct EmulatorTweaksSettingsSection: View {
    let nodePath: String
    @State private var store = EmulatorTweaksStore()
    @State private var showsSigningConfirmation = false
    @State private var acceptsSigning = false

    var body: some View {
        Section("macOS emulator appearance") {
            Text(store.status?.summary ?? "Check the SDK to see whether tweaks are available.")
                .font(.callout).foregroundStyle(.secondary)
            if let revision = store.status?.revision {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Installed emulator software: \(revision)")
                    Text("This is the Android SDK’s emulator version. It determines whether appearance tweaks are supported.")
                        .foregroundStyle(.secondary)
                }.font(.caption)
            }
            HStack {
                Button("Refresh Status") {
                    Task { await store.run(.status, nodePath: nodePath) }
                }
                Button("Learn More…") {
                    acceptsSigning = false
                    showsSigningConfirmation = true
                }
                Button("Restore Original") {
                    Task { await store.run(.restore, nodePath: nodePath) }
                }.disabled(store.status?.canRestore != true)
                if store.isBusy { ProgressView().controlSize(.small) }
            }.disabled(store.isBusy)
            if let message = store.message {
                Text(message).font(.callout).textSelection(.enabled)
            }
            if let backup = store.status?.backup {
                DisclosureGroup("Backup location") {
                    Text(backup).font(.caption).textSelection(.enabled)
                }
            }
        }
        .task(id: nodePath) { await store.run(.status, nodePath: nodePath) }
        .sheet(isPresented: $showsSigningConfirmation) {
            EmulatorTweaksPreviewSheet(
                acceptsSigning: $acceptsSigning,
                canApply: store.status?.canApply == true && !store.isBusy,
                cancel: { showsSigningConfirmation = false },
                apply: {
                    showsSigningConfirmation = false
                    Task { await store.run(.apply, nodePath: nodePath, acceptsSigning: true) }
                }
            )
        }
    }
}
