import Foundation

/// Isolate the SDK's DHU and its descendants from system-wide input access.
/// Older DHU SDL builds open all HID devices before filtering for controllers.
enum DesktopHeadUnitInputProtection {
    static let executable = "/usr/bin/sandbox-exec"
    static let profile = """
    (version 1)
    (allow default)
    (deny hid-control)
    (deny iokit-open
        (iokit-user-client-class "IOHIDLibUserClient")
        (iokit-user-client-class "IOHIDUserClient")
        (iokit-user-client-class "IOHIDEventSystemUserClient"))
    (deny mach-lookup
        (global-name "com.apple.tccd")
        (global-name "com.apple.tccd.system"))
    """

    static func arguments(invocation: EmulatorHelperInvocation, command: [String]) -> [String] {
        ["-p", profile, invocation.node, invocation.script] + command
    }
}
