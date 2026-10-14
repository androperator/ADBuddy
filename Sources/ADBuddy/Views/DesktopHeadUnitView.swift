import SwiftUI

struct DesktopHeadUnitView: View {
    @Environment(DeviceStore.self) private var devices
    @Environment(AppPreferences.self) private var preferences
    @Environment(DesktopHeadUnitStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var serial = ""

    private var availableDevices: [AndroidDevice] { devices.devices.filter(\.isUsable) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Android Auto").font(.title2.bold())
            Text("Run the Desktop Head Unit with Android Auto on a connected phone. Android Automotive OS emulators are created separately using Create Android Emulator.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("On your phone, update Android Auto, enable its developer mode, choose Start head unit server, enable Add new cars to Android Auto, and unlock the screen. Accept connection prompts on the phone.")
                .fixedSize(horizontal: false, vertical: true)
            Link("Android Auto setup guide", destination: URL(string: "https://developer.android.com/training/cars/testing/dhu")!)
            Picker("Device", selection: $serial) {
                Text("Choose a device").tag("")
                ForEach(availableDevices) { device in Text(device.displayName).tag(device.serial) }
            }
            .disabled(store.activeSerial != nil)
            if let status = store.status {
                Label(status.executableReady ? "Desktop Head Unit installed" : "Desktop Head Unit needs installation or executable permissions",
                      systemImage: status.executableReady ? "checkmark.circle" : "arrow.down.circle")
                if !status.executableReady {
                    Button("Install Desktop Head Unit") {
                        store.refresh(sdk: devices.resolvedSDK, configuration: preferences.emulatorHelperConfiguration, install: true)
                    }
                    .disabled(store.isBusy || store.activeSerial != nil)
                    Text("Requires Node.js 24+, SDK-compatible Java and accepted SDK licenses. Downloads Google's SDK package.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            if store.isBusy { ProgressView("Checking or installing Desktop Head Unit…") }
            if let message = store.message {
                ScrollView { Text(message).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }
                    .frame(maxHeight: 100)
            }
            if let active = store.activeSerial {
                Text("Desktop Head Unit session: \(active)").font(.caption)
                Text("Waiting for Android Auto or running. The phone must have its head unit server enabled.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                Button("Refresh") { store.refresh(sdk: devices.resolvedSDK, configuration: preferences.emulatorHelperConfiguration) }
                    .disabled(store.isBusy || store.activeSerial != nil)
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.cancelAction)
                if store.activeSerial != nil {
                    Button("Stop") { store.stop() }
                } else {
                    Button("Start Android Auto") {
                        store.start(serial: serial, sdk: devices.resolvedSDK, configuration: preferences.emulatorHelperConfiguration)
                    }
                    .disabled(store.isBusy || store.status?.executableReady != true || !availableDevices.contains(where: { $0.serial == serial }))
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(24).frame(width: 500)
        .task {
            serial = store.activeSerial ?? availableDevices.first?.serial ?? ""
            store.refresh(sdk: devices.resolvedSDK, configuration: preferences.emulatorHelperConfiguration)
        }
    }
}
