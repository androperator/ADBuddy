import SwiftUI

struct EmulatorTweaksSettingsSection: View {
    let nodePath: String
    @State private var store = EmulatorTweaksStore()
    @State private var showsSigningConfirmation = false
    @State private var acceptsSigning = false

    private var isHealthyPatch: Bool {
        guard let status = store.status else { return false }
        return status.state == "patched" && status.namingHealthy != false && status.runtimeHealthy != false
    }

    private var appearanceTag: String {
        if isHealthyPatch { return "pretty" }
        if store.status?.state == "original" { return "ugly" }
        if store.status == nil && store.isBusy { return "checking" }
        return store.status == nil || store.status?.state == "patched" ? "needs attention" : "unsupported"
    }

    private var tagColor: Color {
        if isHealthyPatch { return .green }
        return store.status?.state == "original" ? .orange : .secondary
    }

    private var supportDescription: String {
        guard let status = store.status else {
            return store.isBusy ? "Checking whether appearance tweaks are available…" : "Appearance status is unavailable. Refresh to check your SDK."
        }
        if status.state == "original" { return "Want to see pretty emulator icons in the Dock?" }
        if isHealthyPatch { return "Appearance tweaks are enabled. Restart running emulators to see their icons and names." }
        return status.summary
    }

    private func showPreview() {
        acceptsSigning = false
        showsSigningConfirmation = true
    }

    var body: some View {
        Section {
            HStack {
                Text(supportDescription)
                    .font(.callout).foregroundStyle(.secondary)
                Button("Learn More", action: showPreview)
                    .buttonStyle(.link)
            }.disabled(store.isBusy)
            if store.status?.canRestore == true {
                HStack {
                    Button("Restore Original") {
                        Task { await store.run(.restore, nodePath: nodePath) }
                    }
                }.disabled(store.isBusy)
            }
            if let message = store.message {
                Text(message).font(.callout).textSelection(.enabled)
            }
            if let status = store.status {
                DisclosureGroup("Details") {
                    if let revision = status.revision {
                        Text("Installed emulator software: \(revision)").font(.caption)
                    }
                    if let backup = status.backup {
                        Text("Backup location: \(backup)")
                            .font(.caption).textSelection(.enabled)
                    }
                }
            }
        } header: {
            HStack(spacing: 8) {
                Text("macOS emulator icon appearance")
                Button(action: showPreview) {
                    Text(appearanceTag)
                        .font(.caption.bold())
                        .foregroundStyle(tagColor)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(tagColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .help("Learn more about emulator appearance")
                .disabled(store.isBusy)
                Button {
                    Task { await store.run(.status, nodePath: nodePath) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh appearance status")
                .accessibilityLabel("Refresh appearance status")
                .disabled(store.isBusy)
                if store.isBusy { ProgressView().controlSize(.small) }
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
