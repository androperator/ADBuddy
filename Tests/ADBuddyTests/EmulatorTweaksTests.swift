import CryptoKit
import Foundation
import XCTest
@testable import ADBuddy
@testable import ADBuddyCore

final class EmulatorTweaksTests: XCTestCase {
    func testApplyRequiresConsentBeforeRunningAnyProcess() async throws {
        let executor = TweaksExecutor()
        let service = EmulatorTweaksService(sdk: sdk, node: "/node", execute: executor.run)
        do {
            _ = try await service.run(.apply)
            XCTFail("Apply must require signing consent")
        } catch { XCTAssertTrue(error.localizedDescription.contains("acknowledgment")) }
        let calls = await executor.calls
        XCTAssertTrue(calls.isEmpty)
    }

    func testCommandsUseExplicitSDKAndOnlyApplyAcceptsSigning() async throws {
        let bundle = try fixture()
        defer { try? FileManager.default.removeItem(at: bundle) }
        for command in [EmulatorTweaksService.Command.status, .apply, .restore] {
            let executor = TweaksExecutor()
            let service = EmulatorTweaksService(sdk: sdk, node: "/selected/node", bundleURL: bundle, execute: executor.run)
            let result = try await service.run(command, acceptsSigning: command == .apply)
            XCTAssertEqual(result.state, "patched")
            let calls = await executor.calls
            XCTAssertEqual(calls[0], ["/selected/node", "--version"])
            XCTAssertEqual(calls[1][0], "/usr/bin/tar")
            let arguments = try XCTUnwrap(calls.last)
            XCTAssertEqual(arguments[0], "/selected/node")
            XCTAssertEqual(Array(arguments.dropFirst(2).prefix(4)), [command.rawValue, "--sdk", sdk.rootPath, "--json"])
            XCTAssertEqual(arguments.contains("--accept-adhoc-signing"), command == .apply)
            XCTAssertFalse(FileManager.default.fileExists(atPath: calls[1].last!))
        }
    }

    func testCorruptArchiveAndOldNodeCannotReachCLI() async throws {
        let bundle = try fixture()
        defer { try? FileManager.default.removeItem(at: bundle) }
        try Data("corrupt".utf8).write(to: bundle.appendingPathComponent("Contents/Resources/EmulatorTweaks/package.tgz"))
        let executor = TweaksExecutor()
        do {
            _ = try await EmulatorTweaksService(sdk: sdk, node: "/node", bundleURL: bundle, execute: executor.run).run(.restore)
            XCTFail("Corrupt package must fail")
        } catch { XCTAssertTrue(error.localizedDescription.contains("invalid")) }
        let calls = await executor.calls
        XCTAssertEqual(calls.count, 1)
        let old = TweaksExecutor(nodeVersion: "v20.0.0")
        do {
            _ = try await EmulatorTweaksService(sdk: sdk, node: "/node", bundleURL: bundle, execute: old.run).run(.status)
            XCTFail("Old Node must fail")
        } catch { XCTAssertTrue(error.localizedDescription.contains("22")) }
        let oldCalls = await old.calls
        XCTAssertEqual(oldCalls.count, 1)
    }

    func testFailureAndMalformedResponsesRemainVisibleAndCleanTemporaryFiles() async throws {
        let bundle = try fixture()
        defer { try? FileManager.default.removeItem(at: bundle) }
        for response in [ProcessResult(standardOutput: Data(), standardError: Data("Unsupported SDK".utf8), exitStatus: 1, durationMilliseconds: 1, failureDescription: nil, wasCancelled: false), TweaksExecutor.result("not json")] {
            let executor = TweaksExecutor(response: response)
            do {
                _ = try await EmulatorTweaksService(sdk: sdk, node: "/node", bundleURL: bundle, execute: executor.run).run(.apply, acceptsSigning: true)
                XCTFail("Invalid result must fail")
            } catch { }
            let calls = await executor.calls
            XCTAssertFalse(FileManager.default.fileExists(atPath: calls[1].last!))
        }
    }

    func testStatusAllowsRestoreWhenRuntimeIsUnhealthy() throws {
        let status = try JSONDecoder().decode(EmulatorTweaksStatus.self, from: Data("""
        {"state":"patched","names":"avd","icons":"auto","namingHealthy":false,"runtimeHealthy":false}
        """.utf8))
        XCTAssertTrue(status.canRestore)
        XCTAssertTrue(status.summary.contains("repair"))
    }

    func testUnsupportedStatusExplainsInstalledVersionAndCompatibility() throws {
        let status = try JSONDecoder().decode(EmulatorTweaksStatus.self, from: Data("""
        {"state":"unsupported","names":"off","revision":"37.1.10","supportedVersions":["37.x"],"compatibilityReason":"Expected exactly one 32px icon; found 0"}
        """.utf8))
        XCTAssertFalse(status.canApply)
        XCTAssertTrue(status.summary.contains("37.1.10"))
        XCTAssertTrue(status.summary.contains("37.x"))
        XCTAssertTrue(status.summary.contains("found 0"))
    }

    private var sdk: AndroidSDK { AndroidSDK(rootPath: "/SDK with spaces;literal", adbPath: "/SDK/adb", source: .standardLocation) }
    private func fixture() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("TweaksTests-\(UUID())")
        let resources = root.appendingPathComponent("Contents/Resources/EmulatorTweaks")
        try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
        let bytes = Data("immutable archive fixture".utf8)
        let hash = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
        try bytes.write(to: resources.appendingPathComponent("package.tgz"))
        try Data("""
        {"emulatorTweaks":{"name":"@androperator/emulator-macos-tweaks","version":"1.0.3-local","sha256":"\(hash)"}}
        """.utf8).write(to: resources.appendingPathComponent("bundled-dependencies.json"))
        return root
    }
}

private actor TweaksExecutor {
    private(set) var calls: [[String]] = []
    let nodeVersion: String
    let response: ProcessResult
    init(nodeVersion: String = "v24.0.0", response: ProcessResult = result("{\"state\":\"patched\",\"names\":\"avd\",\"icons\":\"auto\"}")) {
        self.nodeVersion = nodeVersion
        self.response = response
    }
    func run(_ executable: String, _ arguments: [String], _ environment: [String: String]) async -> ProcessResult {
        calls.append([executable] + arguments)
        if arguments == ["--version"] { return Self.result(nodeVersion) }
        if executable == "/usr/bin/tar" { return Self.result("") }
        return response
    }
    nonisolated static func result(_ text: String) -> ProcessResult {
        ProcessResult(standardOutput: Data(text.utf8), standardError: Data(), exitStatus: 0,
                      durationMilliseconds: 1, failureDescription: nil, wasCancelled: false)
    }
}
