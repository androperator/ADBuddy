import Foundation
import Observation

@MainActor
@Observable
final class EmulatorTweaksStore {
    private(set) var status: EmulatorTweaksStatus?
    private(set) var isBusy = false
    private(set) var message: String?

    func run(_ command: EmulatorTweaksService.Command, nodePath: String, acceptsSigning: Bool = false) async {
        guard !isBusy else { return }
        isBusy = true
        message = nil
        defer { isBusy = false }
        do {
            guard case .found(let sdk) = AndroidSDKLocator().resolve() else {
                throw EmulatorCreationError("Android SDK is unavailable. Check ANDROID_HOME or install the SDK in ~/Library/Android/sdk.")
            }
            let (node, _) = try EmulatorHelperInvocation.resolveNode(nodePath: nodePath)
            let service = EmulatorTweaksService(sdk: sdk, node: node)
            status = try await service.run(command, acceptsSigning: acceptsSigning)
        } catch {
            status = nil
            message = error.localizedDescription
            AppLogger.emulator.error("Emulator tweaks failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
