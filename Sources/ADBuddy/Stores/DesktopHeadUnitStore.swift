import Foundation
import Observation

struct DesktopHeadUnitStatus: Decodable, Sendable {
    let executable: String
    let installed: Bool
    let executableReady: Bool
}

@MainActor
@Observable
final class DesktopHeadUnitStore {
    private(set) var status: DesktopHeadUnitStatus?
    private(set) var isBusy = false
    private(set) var activeSerial: String?
    private(set) var message: String?
    private(set) var connectionEnded = false
    private(set) var deviceSetup: AndroidAutoDeviceSetup?
    private(set) var isCheckingDevice = false
    @ObservationIgnored private var deviceCheckID = UUID()
    @ObservationIgnored private var session: Task<Void, Never>?
    @ObservationIgnored private var setup: Task<Void, Never>?
    @ObservationIgnored private let deviceExecute: AndroidAutoDeviceSetupService.Execute

    init(deviceExecute: @escaping AndroidAutoDeviceSetupService.Execute = {
        await ProcessRunner().run(executablePath: $0, arguments: $1)
    }) {
        self.deviceExecute = deviceExecute
    }

    private func service(sdk: AndroidSDK?, configuration: EmulatorHelperConfiguration) async throws -> EmulatorCreationService {
        guard let sdk else { throw EmulatorCreationError("Locate an Android SDK in Settings before using Android Auto.") }
        let service = EmulatorCreationService(invocation: try EmulatorHelperInvocation.resolve(configuration: configuration, sdk: sdk))
        let version = try await service.check(requiresCatalogs: false)
        guard version.capabilities?.contains("dhu") == true else {
            throw EmulatorCreationError("The selected emulator helper does not support Android Auto. Select a DHU-capable helper in Settings → Emulators.")
        }
        return service
    }

    func refresh(sdk: AndroidSDK?, configuration: EmulatorHelperConfiguration, install: Bool = false) {
        guard !isBusy, activeSerial == nil else { return }
        isBusy = true
        message = nil
        setup = Task {
            defer { isBusy = false; setup = nil }
            do {
                let service = try await service(sdk: sdk, configuration: configuration)
                status = try await service.call([install ? "dhu-install" : "dhu-status"])
                if install { AppLogger.emulator.info("Installed Android Auto Desktop Head Unit") }
            } catch { message = error.localizedDescription }
        }
    }

    func checkDevice(serial: String, sdk: AndroidSDK?, clearMessage: Bool = true) async {
        let checkID = UUID()
        deviceCheckID = checkID
        deviceSetup = nil
        if clearMessage { message = nil; connectionEnded = false }
        guard !serial.isEmpty, let sdk else { isCheckingDevice = false; return }
        isCheckingDevice = true
        do {
            let setup = try await AndroidAutoDeviceSetupService(adbPath: sdk.adbPath, execute: deviceExecute).check(serial: serial)
            guard deviceCheckID == checkID, !Task.isCancelled else { return }
            deviceSetup = setup
        } catch {
            if deviceCheckID == checkID, !Task.isCancelled, clearMessage || message == nil { message = error.localizedDescription }
        }
        if deviceCheckID == checkID { isCheckingDevice = false }
    }

    func openDeviceSetup(serial: String, sdk: AndroidSDK?, update: Bool) {
        guard let sdk, !serial.isEmpty, activeSerial == nil else { return }
        Task {
            do {
                let service = AndroidAutoDeviceSetupService(adbPath: sdk.adbPath, execute: deviceExecute)
                if update { try await service.openUpdate(serial: serial) }
                else { try await service.openSettings(serial: serial) }
                message = nil
            } catch { message = error.localizedDescription }
        }
    }

    func start(serial: String, sdk: AndroidSDK?, configuration: EmulatorHelperConfiguration) {
        guard !isBusy, activeSerial == nil, !serial.isEmpty else { return }
        activeSerial = serial
        message = nil
        connectionEnded = false
        session = Task {
            var didLaunch = false
            defer { activeSerial = nil; session = nil }
            do {
                guard let sdk else { throw EmulatorCreationError("Locate an Android SDK in Settings before using Android Auto.") }
                let setup = try await AndroidAutoDeviceSetupService(adbPath: sdk.adbPath, execute: deviceExecute).check(serial: serial)
                deviceSetup = setup
                guard setup.hasFullApp, setup.serverRunning != false else {
                    throw EmulatorCreationError(setup.guidance)
                }
                let service = try await service(sdk: sdk, configuration: configuration)
                guard !Task.isCancelled else { return }
                AppLogger.emulator.info("Starting Android Auto Desktop Head Unit")
                struct Result: Decodable, Sendable { let serial: String; let stopped: Bool }
                didLaunch = true
                let result: Result = try await service.call(["dhu-start", serial])
                guard result.serial == serial, result.stopped else {
                    throw EmulatorCreationError("The helper did not confirm the Desktop Head Unit closed.")
                }
                guard !Task.isCancelled else { return }
                connectionEnded = true
                message = "The Desktop Head Unit closed or disconnected. Check the device and its head unit server before trying again."
            } catch {
                if !Task.isCancelled { connectionEnded = didLaunch; message = error.localizedDescription }
            }
        }
    }

    func stop() { session?.cancel() }

    func stopAll() async {
        setup?.cancel()
        session?.cancel()
        await setup?.value
        await session?.value
    }
}
