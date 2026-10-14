import SwiftUI

struct AndroidAutoConfigurationView: View {
    @Environment(DeviceStore.self) private var devices
    @Environment(AppPreferences.self) private var preferences
    @Environment(DesktopHeadUnitStore.self) private var store
    @State private var serial = ""

    private var availableDevices: [AndroidDevice] { devices.devices.filter(\.isUsable) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                configuration
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
            }
            .clipped()
            .padding(.top, 12)
            Divider()
            actions
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
        }
        .task(id: serial) { await store.checkDevice(serial: serial, sdk: devices.resolvedSDK) }
        .task {
            serial = store.activeSerial ?? availableDevices.first?.serial ?? ""
            store.refresh(sdk: devices.resolvedSDK, configuration: preferences.emulatorHelperConfiguration)
        }
    }

    private var configuration: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose a phone or Google Play emulator to run Android Auto.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("On your phone, update Android Auto, enable its developer mode, choose Start head unit server, enable Add new cars to Android Auto, and unlock the screen. Accept connection prompts on the phone.")
                .fixedSize(horizontal: false, vertical: true)
            Link("Android Auto setup guide", destination: URL(string: "https://developer.android.com/training/cars/testing/dhu")!)
            Picker("Android device", selection: $serial) {
                Text("Choose a device").tag("")
                ForEach(availableDevices) { device in Text(device.displayName).tag(device.serial) }
            }
            .disabled(store.activeSerial != nil)
            if store.isCheckingDevice {
                ProgressView("Checking device setup…").controlSize(.small)
            } else if let setup = store.deviceSetup {
                Text(setup.guidance)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Button("Update Android Auto") {
                    store.openDeviceSetup(serial: serial, sdk: devices.resolvedSDK, update: true)
                }
                Button("Open Android Auto Settings") {
                    store.openDeviceSetup(serial: serial, sdk: devices.resolvedSDK, update: false)
                }
                Button("Check Device") {
                    Task { await store.checkDevice(serial: serial, sdk: devices.resolvedSDK) }
                }
            }
            .disabled(serial.isEmpty || store.activeSerial != nil || store.isCheckingDevice)
            if let status = store.status {
                Label(status.executableReady ? "Android Auto emulator installed" : "Android Auto emulator needs setup",
                      systemImage: status.executableReady ? "checkmark.circle" : "arrow.down.circle")
                if !status.executableReady {
                    Button("Install Android Auto Emulator") {
                        store.refresh(sdk: devices.resolvedSDK, configuration: preferences.emulatorHelperConfiguration, install: true)
                    }
                    .disabled(store.isBusy || store.activeSerial != nil)
                    Text("Requires Node.js 24+, SDK-compatible Java and accepted SDK licenses. Downloads Google's SDK package.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            if let message = store.message {
                Text(message)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let active = store.activeSerial {
                Text("Android Auto session: \(active)").font(.caption)
                Text("Waiting for Android Auto or running. The phone must have its head unit server enabled.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var actions: some View {
        HStack {
            if store.isBusy {
                ProgressView("Setting up Android Auto…")
                    .controlSize(.small)
            } else {
                Button("Refresh") { store.refresh(sdk: devices.resolvedSDK, configuration: preferences.emulatorHelperConfiguration) }
                    .disabled(store.activeSerial != nil)
            }
            Spacer()
            if store.activeSerial != nil {
                Button("Stop") { store.stop() }
            } else {
                Button("Start Android Auto") {
                    store.start(serial: serial, sdk: devices.resolvedSDK, configuration: preferences.emulatorHelperConfiguration)
                }
                .disabled(store.isBusy || store.isCheckingDevice || store.deviceSetup?.hasFullApp != true || store.deviceSetup?.serverRunning == false || store.status?.executableReady != true || !availableDevices.contains(where: { $0.serial == serial }))
                .keyboardShortcut(.defaultAction)
            }
        }
    }
}
