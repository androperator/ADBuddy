import CryptoKit
import Foundation

struct EmulatorTweaksStatus: Decodable, Sendable {
    let state: String
    let revision: String?
    let names: String
    let namingHealthy: Bool?
    let icons: String?
    let runtimeHealthy: Bool?
    let backup: String?

    var canApply: Bool { state == "original" || state == "patched" }
    var canRestore: Bool { state == "patched" }
    var summary: String {
        switch state {
        case "original": "Original emulator - tweaks are not applied."
        case "patched": namingHealthy == false || runtimeHealthy == false
            ? "Tweaks need repair. Restore remains available."
            : "Tweaks applied: \(icons == "auto" ? "automatic device icons" : "phone icon")\(names == "avd" ? " and AVD names" : "")."
        default: "This emulator build is unsupported. No files will be changed."
        }
    }
}

struct EmulatorTweaksService: Sendable {
    enum Command: String { case status, apply, restore }
    typealias Execute = EmulatorCreationService.Execute
    let sdk: AndroidSDK
    let node: String
    let bundleURL: URL
    private let execute: Execute

    init(sdk: AndroidSDK, node: String, bundleURL: URL = Bundle.main.bundleURL,
         execute: @escaping Execute = { executable, arguments, environment in
             await ProcessRunner().run(executablePath: executable, arguments: arguments,
                                       identifier: UUID().uuidString, environment: environment, onStarted: nil)
         }) {
        self.sdk = sdk
        self.node = node
        self.bundleURL = bundleURL
        self.execute = execute
    }

    func run(_ command: Command, acceptsSigning: Bool = false) async throws -> EmulatorTweaksStatus {
        if command == .apply && !acceptsSigning {
            throw EmulatorCreationError("Applying tweaks requires acknowledgment of ad-hoc signing.")
        }
        let nodeVersion = await execute(node, ["--version"], ProcessInfo.processInfo.environment)
        let version = String(decoding: nodeVersion.standardOutput, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        guard nodeVersion.succeeded, let major = Int(version.dropFirst().split(separator: ".").first ?? ""), major >= 22 else {
            throw EmulatorCreationError("Node.js 22 or newer is required for emulator tweaks. Check the Node executable path above.")
        }
        let resources = bundleURL.appendingPathComponent("Contents/Resources/EmulatorTweaks")
        struct Manifest: Decodable {
            struct Package: Decodable { let name: String; let version: String; let sha256: String }
            let emulatorTweaks: Package
        }
        let manifest = try JSONDecoder().decode(Manifest.self, from: Data(contentsOf: resources.appendingPathComponent("bundled-dependencies.json"))).emulatorTweaks
        let archive = resources.appendingPathComponent("package.tgz")
        let digest = SHA256.hash(data: try Data(contentsOf: archive)).map { String(format: "%02x", $0) }.joined()
        guard manifest.name == "@androperator/emulator-macos-tweaks", manifest.version == "1.0.2", digest == manifest.sha256 else {
            throw EmulatorCreationError("Bundled emulator tweaks are invalid. Reinstall ADBuddy.")
        }
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent("ADBuddyTweaks-\(UUID())")
        try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: temporary) }
        let unpack = await execute("/usr/bin/tar", ["-xzf", archive.path, "-C", temporary.path], ProcessInfo.processInfo.environment)
        guard unpack.succeeded else { throw EmulatorCreationError(unpack.failureDescription ?? "Could not unpack emulator tweaks.") }
        let cli = temporary.appendingPathComponent("package/bin/androperator-emulator-tweaks.js").path
        var arguments = [cli, command.rawValue, "--sdk", sdk.rootPath, "--json"]
        if command == .apply { arguments.append("--accept-adhoc-signing") }
        AppLogger.emulator.info("Running emulator tweaks \(command.rawValue, privacy: .public)")
        let result = await execute(node, arguments, ProcessInfo.processInfo.environment)
        guard result.succeeded else {
            let detail = String(decoding: result.standardError, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            throw EmulatorCreationError(detail.isEmpty ? result.failureDescription ?? "Emulator tweaks failed." : detail)
        }
        return try JSONDecoder().decode(EmulatorTweaksStatus.self, from: result.standardOutput)
    }
}
