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
    @ObservationIgnored private var session: Task<Void, Never>?
    @ObservationIgnored private var setup: Task<Void, Never>?

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

    func start(serial: String, sdk: AndroidSDK?, configuration: EmulatorHelperConfiguration) {
        guard !isBusy, activeSerial == nil, !serial.isEmpty else { return }
        activeSerial = serial
        message = nil
        session = Task {
            defer { activeSerial = nil; session = nil }
            do {
                let service = try await service(sdk: sdk, configuration: configuration)
                guard !Task.isCancelled else { return }
                AppLogger.emulator.info("Starting Android Auto Desktop Head Unit")
                struct Result: Decodable, Sendable { let serial: String; let stopped: Bool }
                let result: Result = try await service.call(["dhu-start", serial])
                guard result.serial == serial, result.stopped else {
                    throw EmulatorCreationError("The helper did not confirm the Desktop Head Unit closed.")
                }
                message = "Desktop Head Unit closed."
            } catch {
                if !Task.isCancelled { message = error.localizedDescription }
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
