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
