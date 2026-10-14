import XCTest
@testable import ADBuddy

final class AndroidAutoDeviceSetupTests: XCTestCase {
    private static func result(_ text: String, status: Int32 = 0) -> ProcessResult {
        ProcessResult(standardOutput: Data(text.utf8), standardError: Data(), exitStatus: status, durationMilliseconds: 1, failureDescription: nil, wasCancelled: false)
    }

    func testStubRequiresPlayUpdateWithoutCheckingServer() async throws {
        let service = AndroidAutoDeviceSetupService(adbPath: "/sdk/adb") { executable, arguments in
            XCTAssertEqual(executable, "/sdk/adb")
            XCTAssertEqual(arguments, ["-s", "emulator-5554", "shell", "dumpsys", "package", "com.google.android.projection.gearhead"])
            return Self.result("    versionName=1.2.542030-stub\n")
        }
        let setup = try await service.check(serial: "emulator-5554")
        XCTAssertFalse(setup.hasFullApp)
        XCTAssertTrue(setup.guidance.contains("signing in"))
    }

    func testMissingPackageRequiresInstallation() async throws {
        let service = AndroidAutoDeviceSetupService(adbPath: "/sdk/adb") { _, _ in Self.result("Unable to find package") }
        let setup = try await service.check(serial: "device")
        XCTAssertNil(setup.version)
        XCTAssertFalse(setup.hasFullApp)
    }

    func testFullAppChecksListenerOnSelectedDevice() async throws {
        let service = AndroidAutoDeviceSetupService(adbPath: "/sdk/adb") { _, arguments in
            XCTAssertEqual(Array(arguments.prefix(2)), ["-s", "phone"])
            if arguments.contains("dumpsys") { return Self.result("versionName=16.0.1\n") }
            XCTAssertEqual(arguments, ["-s", "phone", "shell", "cat", "/proc/net/tcp", "/proc/net/tcp6"])
            return Self.result("sl local_address rem_address st\n0: 0100007F:149D 00000000:0000 0A\n")
        }
        let setup = try await service.check(serial: "phone")
        XCTAssertTrue(setup.hasFullApp)
        XCTAssertEqual(setup.serverRunning, true)
    }

    func testListenerParserRequiresLocalPortAndListeningState() {
        XCTAssertTrue(AndroidAutoDeviceSetupService.hasHeadUnitListener("0: 00000000000000000000000000000000:149D 00000000000000000000000000000000:0000 0A"))
        XCTAssertFalse(AndroidAutoDeviceSetupService.hasHeadUnitListener("0: 0100007F:149D 00000000:0000 01"))
        XCTAssertFalse(AndroidAutoDeviceSetupService.hasHeadUnitListener("0: 0100007F:8888 0100007F:149D 0A"))
    }

    func testUnreadableSocketTableIsUnknownRatherThanStopped() async throws {
        let service = AndroidAutoDeviceSetupService(adbPath: "/sdk/adb") { _, arguments in
            if arguments.contains("dumpsys") { return Self.result("versionName=16.0.1") }
            return Self.result("Permission denied", status: 1)
        }
        let setup = try await service.check(serial: "phone")
        XCTAssertNil(setup.serverRunning)
        XCTAssertTrue(setup.guidance.contains("could not be checked"))
    }

    func testDeviceActionsUseSelectedSerialAndExplicitPackage() async throws {
        let settings = AndroidAutoDeviceSetupService(adbPath: "/sdk/adb") { _, arguments in
            XCTAssertEqual(arguments, ["-s", "selected", "shell", "am", "start", "-a", "com.android.settings.action.SETTINGS", "-p", "com.google.android.projection.gearhead"])
            return Self.result("Starting: Intent")
        }
        try await settings.openSettings(serial: "selected")
        let update = AndroidAutoDeviceSetupService(adbPath: "/sdk/adb") { _, arguments in
            XCTAssertEqual(arguments, ["-s", "selected", "shell", "am", "start", "-a", "android.intent.action.VIEW", "-d", "market://details?id=com.google.android.projection.gearhead", "-p", "com.android.vending"])
            return Self.result("Starting: Intent")
        }
        try await update.openUpdate(serial: "selected")
    }

    func testActivityErrorIsReportedEvenWithZeroExitStatus() async {
        let service = AndroidAutoDeviceSetupService(adbPath: "/sdk/adb") { _, _ in Self.result("Error: Activity not started, unable to resolve Intent") }
        do {
            try await service.openSettings(serial: "selected")
            XCTFail("Expected an activity error")
        } catch { XCTAssertTrue(error.localizedDescription.contains("unable to resolve")) }
    }
}
