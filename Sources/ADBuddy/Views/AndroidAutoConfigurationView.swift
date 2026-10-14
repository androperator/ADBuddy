import AppKit
import SwiftUI

struct AndroidAutoConfigurationView: View {
    @Environment(DeviceStore.self) private var devices
    @Environment(AppPreferences.self) private var preferences
    @Environment(DesktopHeadUnitStore.self) private var store
    @State private var serial = ""
    @State private var showsSetupHelp = false
    @State private var showsDetails = false

    private var availableDevices: [AndroidDevice] { devices.devices.filter(\.isUsable) }
    private var canCheck: Bool { !serial.isEmpty && store.activeSerial == nil && !store.isCheckingDevice }

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
        .onChange(of: availableDevices.map(\.serial)) { _, serials in
            if store.activeSerial == nil, !serials.contains(serial) { serial = serials.first ?? "" }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            recheckOnFocus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { notification in
            if (notification.object as? NSWindow)?.title == "Create Android Emulator" { recheckOnFocus() }
        }
    }

    private func recheckOnFocus() {
        guard canCheck else { return }
        Task { await store.checkDevice(serial: serial, sdk: devices.resolvedSDK, clearMessage: false) }
    }

    private var configuration: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Android device", selection: $serial) {
                Text("Choose a device").tag("")
                ForEach(availableDevices) { device in Text(device.displayName).tag(device.serial) }
            }
            .disabled(store.activeSerial != nil)

            readiness

            if store.message != nil {
                HStack {
                    Label(store.connectionEnded ? "Connection ended" : "Setup needs attention", systemImage: "exclamationmark.circle")
                    Button("Details") { showsDetails = true }
                        .buttonStyle(.link)
                        .popover(isPresented: $showsDetails) {
                            ScrollView {
                                Text(store.message ?? "")
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding().frame(width: 360, height: 180)
                        }
                }
            }

            DisclosureGroup("Setup help", isExpanded: $showsSetupHelp) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Use an updated Android Auto app on a phone or Google Play emulator. The emulator's preinstalled stub requires an update from Google Play.")
                    Text("In Android Auto settings, tap Version ten times to enable developer mode, then choose Start head unit server from the menu. Enable Add new cars and keep the device unlocked. Complete connection prompts on the device.")
                    Link("Android Auto setup guide", destination: URL(string: "https://developer.android.com/training/cars/testing/dhu")!)
                }
                .font(.callout).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            }
        }
    }

    @ViewBuilder private var readiness: some View {
        if store.activeSerial != nil {
            Label("Session in progress", systemImage: "display")
        } else if let status = store.status, !status.executableReady {
            statusRow("Desktop Head Unit", value: "Not installed") {
                Button("Install") {
                    store.refresh(sdk: devices.resolvedSDK, configuration: preferences.emulatorHelperConfiguration, install: true)
                }.disabled(store.isBusy)
            }
        } else if store.isCheckingDevice {
            ProgressView("Checking device…").controlSize(.small)
        } else if let setup = store.deviceSetup {
            if !setup.hasFullApp {
                statusRow("Android Auto", value: setup.version == nil ? "Not installed" : "Update required") {
                    Button("Open Google Play") { store.openDeviceSetup(serial: serial, sdk: devices.resolvedSDK, update: true) }
                }
            } else if setup.serverRunning == true, store.status?.executableReady == true {
                Label("Server detected", systemImage: "checkmark.circle")
            } else {
                statusRow("Android Auto", value: "Installed") { EmptyView() }
                statusRow("Head unit server", value: setup.serverRunning == false ? "Not running" : "Couldn’t check") {
                    Button("Open Settings") { store.openDeviceSetup(serial: serial, sdk: devices.resolvedSDK, update: false) }
                }
            }
        } else if serial.isEmpty {
            Text("Connect an Android device.").foregroundStyle(.secondary)
        }
    }

    private func statusRow<Action: View>(_ label: String, value: String, @ViewBuilder action: () -> Action) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary).frame(width: 124, alignment: .leading)
            Text(value)
            Spacer()
            action()
        }
    }

    private var actions: some View {
        HStack {
            if store.isBusy {
                ProgressView("Setting up Android Auto…").controlSize(.small)
            } else if store.activeSerial == nil {
                Button(store.connectionEnded ? "Check Device" : "Check Again") {
                    Task {
                        store.refresh(sdk: devices.resolvedSDK, configuration: preferences.emulatorHelperConfiguration)
                        await store.checkDevice(serial: serial, sdk: devices.resolvedSDK)
                    }
                }.disabled(!canCheck)
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
