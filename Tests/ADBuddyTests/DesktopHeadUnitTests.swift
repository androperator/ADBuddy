import XCTest
@testable import ADBuddy

final class DesktopHeadUnitTests: XCTestCase {
    @MainActor
    func testAndroidAutoIsAvailableWithoutAVDCatalogAndDoesNotSelectAVDInputs() {
        let store = EmulatorCreationStore()
        XCTAssertTrue(store.availableHardwareTypes.contains(.androidAuto))
        store.hardwareType = .androidAuto
        store.selectHardwareType()
        XCTAssertNil(store.selectedProfile)
        XCTAssertNil(store.selectedImage)
        XCTAssertTrue(store.availableImages.isEmpty)
    }

    func testStatusDecodesThroughHelperContract() async throws {
        let invocation = EmulatorHelperInvocation(node: "/node", script: "/helper", environment: [:])
        let service = EmulatorCreationService(invocation: invocation) { executable, arguments, _ in
            XCTAssertEqual(executable, "/node")
            XCTAssertEqual(arguments, ["/helper", "dhu-status"])
            return ProcessResult(standardOutput: Data(#"{"protocolVersion":1,"ok":true,"data":{"executable":"/sdk/extras/google/auto/desktop-head-unit","installed":false,"executableReady":false}}"#.utf8), standardError: Data(), exitStatus: 0, durationMilliseconds: 1, failureDescription: nil, wasCancelled: false)
        }
        let status: DesktopHeadUnitStatus = try await service.call(["dhu-status"])
        XCTAssertFalse(status.installed)
        XCTAssertFalse(status.executableReady)
        XCTAssertEqual(status.executable, "/sdk/extras/google/auto/desktop-head-unit")
    }

    func testLaunchUsesInputProtectionAndPreservesDeviceAndEnvironment() async throws {
        let invocation = EmulatorHelperInvocation(node: "/node path", script: "/helper path", environment: ["ADB_PATH": "/sdk/adb"])
        let service = EmulatorCreationService(invocation: invocation) { executable, arguments, environment in
            XCTAssertEqual(executable, "/usr/bin/sandbox-exec")
            XCTAssertEqual(arguments, ["-p", DesktopHeadUnitInputProtection.profile, "/node path", "/helper path", "dhu-start", "phone-serial"])
            XCTAssertEqual(environment, invocation.environment)
            return ProcessResult(standardOutput: Data(#"{"protocolVersion":1,"ok":true,"data":{"serial":"phone-serial","stopped":true}}"#.utf8), standardError: Data(), exitStatus: 0, durationMilliseconds: 1, failureDescription: nil, wasCancelled: false)
        }
        struct Result: Decodable, Sendable { let serial: String; let stopped: Bool }
        let result: Result = try await service.call(["dhu-start", "phone-serial"])
        XCTAssertEqual(result.serial, "phone-serial")
        XCTAssertTrue(result.stopped)
    }

    func testInputProtectionFailureDoesNotRetryUnrestricted() async {
        let service = EmulatorCreationService(invocation: .init(node: "/node", script: "/helper", environment: [:])) { executable, _, _ in
            XCTAssertEqual(executable, DesktopHeadUnitInputProtection.executable)
            return ProcessResult(standardOutput: Data(), standardError: Data("policy rejected".utf8), exitStatus: 1, durationMilliseconds: 1, failureDescription: nil, wasCancelled: false)
        }
        do {
            let _: DesktopHeadUnitStatus = try await service.call(["dhu-start", "phone"])
            XCTFail("An input-protection failure must prevent launch")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("macOS input protection"))
            XCTAssertTrue(error.localizedDescription.contains("policy rejected"))
        }
    }

    func testProtectionDeniesGlobalInputAndPermissionRequestsInRealChildProcess() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("dhu-input-protection-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appendingPathComponent("probe.c")
        let binary = directory.appendingPathComponent("probe")
        try """
        #include <stdio.h>
        #include <unistd.h>
        #include <IOKit/hidsystem/IOHIDLib.h>
        extern int sandbox_check(pid_t, const char *, int, ...);
        int main(void) {
            int denied = sandbox_check(getpid(), "hid-control", 0);
            int granted = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent);
            printf("hid-control-denied=%d;listen-access=%d", denied, granted);
            return denied > 0 && granted == 0 ? 0 : 1;
        }
        """.write(to: source, atomically: true, encoding: .utf8)
        let runner = ProcessRunner()
        let compiled = await runner.run(executablePath: "/usr/bin/xcrun", arguments: ["clang", source.path, "-framework", "IOKit", "-framework", "CoreFoundation", "-o", binary.path])
        XCTAssertTrue(compiled.succeeded, String(decoding: compiled.standardError, as: UTF8.self))
        guard compiled.succeeded else { return }
        let result = await runner.run(executablePath: DesktopHeadUnitInputProtection.executable, arguments: ["-p", DesktopHeadUnitInputProtection.profile, binary.path])
        XCTAssertTrue(result.succeeded, String(decoding: result.standardError, as: UTF8.self))
        XCTAssertEqual(String(decoding: result.standardOutput, as: UTF8.self), "hid-control-denied=1;listen-access=0")
    }

    @MainActor
    func testMissingSDKReportsFailureAndClearsBusyState() async {
        let store = DesktopHeadUnitStore()
        store.refresh(sdk: nil, configuration: EmulatorHelperConfiguration(helperPath: "", nodePath: "", javaHome: ""))
        await store.stopAll()
        XCTAssertFalse(store.isBusy)
        XCTAssertNil(store.status)
        XCTAssertTrue(store.message?.contains("Android SDK") == true)
    }

    @MainActor
    func testFailedLaunchReleasesSessionReservation() async {
        let store = DesktopHeadUnitStore()
        store.start(serial: "phone", sdk: nil, configuration: EmulatorHelperConfiguration(helperPath: "", nodePath: "", javaHome: ""))
        for _ in 0..<20 where store.activeSerial != nil { await Task.yield() }
        XCTAssertNil(store.activeSerial)
        XCTAssertTrue(store.message?.contains("Android SDK") == true)
    }
}
