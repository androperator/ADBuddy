import Foundation

struct AndroidAutoDeviceSetup: Equatable, Sendable {
    let version: String?
    let serverRunning: Bool?

    var hasFullApp: Bool {
        guard let version else { return false }
        return !version.isEmpty && !version.lowercased().contains("stub")
    }
    var guidance: String {
        if !hasFullApp {
            return "Install or update Android Auto from Google Play on this device. Google Play emulators require signing in first; the preinstalled stub cannot run Android Auto."
        }
        if serverRunning == false {
            return "Open Android Auto settings, enable developer mode by tapping Version ten times, then choose Start head unit server from the menu. Enable Add new cars and keep the device unlocked."
        }
        if serverRunning == nil {
            return "Android Auto is installed, but the head unit server could not be checked. Start it in Android Auto developer settings and keep the device unlocked."
        }
        return "Android Auto's head unit server is ready. Start Android Auto, then complete any connection setup on the device."
    }
}

struct AndroidAutoDeviceSetupService: Sendable {
    typealias Execute = @Sendable (String, [String]) async -> ProcessResult
    let adbPath: String
    var execute: Execute = { await ProcessRunner().run(executablePath: $0, arguments: $1) }
    static let package = "com.google.android.projection.gearhead"

    func check(serial: String) async throws -> AndroidAutoDeviceSetup {
        let result = await execute(adbPath, ["-s", serial, "shell", "dumpsys", "package", Self.package])
        try validate(result)
        let text = String(decoding: result.standardOutput, as: UTF8.self)
        let version = text.split(separator: "\n").compactMap { line -> String? in
            let value = line.trimmingCharacters(in: .whitespaces)
            guard value.hasPrefix("versionName=") else { return nil }
            return String(value.dropFirst("versionName=".count))
        }.first
        guard let version, !version.lowercased().contains("stub") else {
            return AndroidAutoDeviceSetup(version: version, serverRunning: false)
        }
        let sockets = await execute(adbPath, ["-s", serial, "shell", "cat", "/proc/net/tcp", "/proc/net/tcp6"])
        let output = String(decoding: sockets.standardOutput, as: UTF8.self)
        let running: Bool? = sockets.succeeded && output.contains("local_address") ? Self.hasHeadUnitListener(output) : nil
        return AndroidAutoDeviceSetup(version: version, serverRunning: running)
    }

    static func hasHeadUnitListener(_ output: String) -> Bool {
        output.split(separator: "\n").contains { line in
            let fields = line.split(whereSeparator: { $0.isWhitespace })
            return fields.count >= 4 && fields[1].uppercased().hasSuffix(":149D") && fields[3] == "0A"
        }
    }

    func openSettings(serial: String) async throws {
        try await open(serial: serial, arguments: ["-a", "com.android.settings.action.SETTINGS", "-p", Self.package])
    }

    func openUpdate(serial: String) async throws {
        try await open(serial: serial, arguments: ["-a", "android.intent.action.VIEW", "-d", "market://details?id=\(Self.package)", "-p", "com.android.vending"])
    }

    private func open(serial: String, arguments: [String]) async throws {
        let result = await execute(adbPath, ["-s", serial, "shell", "am", "start"] + arguments)
        try validate(result)
        let output = String(decoding: result.standardOutput + result.standardError, as: UTF8.self)
        if output.contains("Error:") || output.contains("Exception") { throw EmulatorCreationError(output) }
    }

    private func validate(_ result: ProcessResult) throws {
        if result.wasCancelled { throw CancellationError() }
        guard result.succeeded else {
            throw EmulatorCreationError(result.failureDescription ?? String(decoding: result.standardError, as: UTF8.self))
        }
    }
}
