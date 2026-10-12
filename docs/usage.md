# Using ADBuddy

Setup and workflow details for the features shown in the [README](../README.md).

## Android SDK setup

ADBuddy requires macOS 14 or newer and an Android SDK containing `platform-tools/adb`.
Enable USB debugging on a physical device and approve the connection on the device,
or start an Android emulator.

ADBuddy checks `ANDROID_HOME`, then `ANDROID_SDK_ROOT`, then
`~/Library/Android/sdk`. It does not rely on the GUI application inheriting
a useful shell `PATH`. Missing tools and unavailable devices appear in the app.

## Install APK

Choose **Install APK** from the toolbar or menu bar, open an APK through Finder,
or drop one onto a usable connected-device row. The install sheet supports one
ordinary `.apk` file at a time and can target multiple devices. It uses
`adb install -r`, retaining app data while replacing an existing compatible
build. ADBuddy does not enable app downgrades or uninstall an app implicitly.

Select **Open after install** to launch the app when its APK exposes a launcher
activity and the Android SDK includes `aapt2` in `build-tools`. A successful
install remains successful if that optional launch step is unavailable. Split
APKs, `.apks` archives, and Android App Bundles are not supported yet.

## Media destination

Screenshots and screen recordings share one destination. It defaults to
`~/Screenshots`. The destination, automatic clipboard-copy and Finder
reveal preferences, and screen-recording options are saved in `UserDefaults`.
Automatic screenshot and recording copying defaults to enabled; automatic
Finder reveal defaults to disabled. Use **ADBuddy → Settings…** to change them,
using the Screenshots tab for shared media settings or Logcat for severity colors.
The General tab controls menu bar visibility and success banners. Recording
options are chosen when starting a recording and remembered for next time.

## Logcat

Select **Open Logcat** beside a connected device in the main window or its
menu-bar submenu. Each device serial gets its own window with up to 5,000 recent
messages followed by its live stream. The toolbar provides an editable
application-ID filter, a minimum severity, local search with `⌘F`, a one-click
crash and exception filter, pause/resume, clear, follow, and column controls.
PID, TID, and Application ID are hidden by default. Column visibility, order,
widths, and message wrapping are saved across windows and app launches.
Select rows and press `⌘C` to copy readable text.

Logcat keeps at most 50,000 entries per window. Disconnecting a device retains
its visible logs; reconnecting the same serial resumes that window automatically.

## Foreground app actions

Use the app-actions menu beside a usable device, or its **Foreground App** menu
in the menu bar, for lifecycle actions without entering a package name.
ADBuddy resolves the app currently in the foreground on that device when an
action begins. It can start, kill, restart, clear app data, or clear data and
restart that app. Uninstall shows a confirmation with the resolved package name
before removing it.

## Create and manage emulators

Choose **Create Android Emulator** in the main toolbar. Select a device type,
hardware profile, Android image, unique name, and maximum storage size.
Choose **Create** to leave it stopped or **Create & Start** to launch it.
Images already installed are marked with a drive icon; downloadable images
are marked with a download icon. Disk space is allocated as needed.

Creation and deletion require Node.js 24 or newer. The Android SDK emulator
tools, system images, SDK-compatible Java, and accepted SDK licenses are also
required. Creation can download a selected image, but does not accept licenses
for you or replace an existing emulator. Settings → Emulators lets you select
a Node executable or configure Java.

Start a stopped emulator from its play button or by double-clicking its row.
Its menu also offers Cold Boot, Reveal in Finder, and confirmed deletion.
Running emulators have a stop button; double-click one to reveal its window.
Wipe Data and Start requires confirmation because it removes installed apps
and settings. Advanced AVD configuration and snapshot management are not included.

## macOS emulator appearance

Settings → Emulators shows an `ugly` or `pretty` appearance tag and offers
**Learn More…** using bundled `@androperator/emulator-macos-tweaks` 1.0.3-local.
The preview compares original and tweaked icons and links to the open-source
project. Version and backup information live under **Details**.

Healthy applied tweaks open an info-only preview with **Done** and **Repair…**.
Applying or repairing requires a fresh signing acknowledgment before **Make Pretty**:
Google's signature is replaced by a local ad-hoc signature while retaining
entitlements and hardened runtime. **Restore Original** reinstates the exact
original and its Google signature. No developer certificate or private key is used.

The patch affects all launches through the selected SDK, including Terminal and
Android Studio. Restart running emulators to see changes. The local compatibility build supports Apple Silicon Android Emulator 37.x
when its executable structure and embedded icons match the patch profile.
Settings and the preview show the installed version and any compatibility failure.
Node.js 22+ is required for tweaks, including later emulator launches with AVD names.
The existing Node executable setting is shared with creation and deletion (24+).
If that Node installation moves, select the new Node and use **Repair…** to apply again.

Backups are shared with the standalone CLI in
`~/Library/Application Support/emulator-icon-macos/backups`. Keep them in place
while patched; they contain the original and the naming/icon runtime. Closing or
updating ADBuddy does not remove them. SDK updates may remove the patch; restore
will not overwrite an unrecognized updated executable. A patch installed using a
custom CLI backup directory must be managed through that CLI directory.

## Agent access

The bundled local MCP server lets an agent list devices and emulators, start
and stop emulators, and capture screenshots or recordings. It shares the app’s
media destination and saved recording defaults. See [MCP setup](mcp.md).

## More detail

- [Logcat controls and behavior](logcat.md)
- [Supported workflows and scope](product-scope.md)
- [Recording backend and limitations](recording-backend.md)
- [Emulator helper provenance](../vendor/emulator/README.md)
- [Emulator appearance tweaks attribution](../vendor/emulator-tweaks/README.md)
