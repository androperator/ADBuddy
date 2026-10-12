# Changelog

## [1.0.1] - 2026-10-13

ADBuddy accepted more Apple Silicon emulator builds for macOS appearance tweaks and explained unsupported SDKs more clearly. Installation and release documentation also clarified the Homebrew distribution path.

### macOS App

- **Fixed:** Enabled appearance tweaks for structurally compatible Android Emulator 37.x builds on Apple Silicon, without requiring an exact emulator revision or executable hash. Exact backups, signing checks, and restoration protections were preserved.
- **Fixed:** Showed installed and supported emulator versions and the specific compatibility failure in Settings and the preview. Disabled the signing acceptance section when Apply was unavailable.
- **Fixed:** Kept the published 1.0.0 app identity, shared preferences compatibility, and signed bundled native helpers intact while incorporating its release preparation into main and connecting the published release history.

### Documentation

- **Added:** Documented Homebrew cask installation, upgrades, checksum validation, and the cask update stage in end-to-end releases.
- **Changed:** Corrected distribution and recording-source links and clarified optional Node.js requirements.
- **Changed:** Updated appearance compatibility guidance for the bundled tweaks 1.0.3 package, including installed versions and failure details.

Pull requests:
- [chore(release): merge published 1.0.0 release preparation](https://github.com/androperator/ADBuddy/pull/18)
- [docs(distribution): correct links and document Homebrew installation](https://github.com/androperator/ADBuddy/pull/19)
- [docs(release): include Homebrew cask updates and validation](https://github.com/androperator/ADBuddy/pull/20)
- [test(logcat): avoid missing transient reconnect failure state](https://github.com/androperator/ADBuddy/pull/22)
- [fix(emulators): broaden appearance tweak compatibility and explain unsupported SDKs](https://github.com/androperator/ADBuddy/pull/23)

## [1.0.0] - 2026-10-11

ADBuddy 1.0 added optional emulator icons and names, improved emulator window handling, and made everyday device workflows easier to discover. This milestone also included the emulator creation, device controls, and Settings improvements introduced in 0.3.0.

### macOS App

- **Added:** Switched connected devices between light and dark mode directly from their row or the menu bar, including devices using an automatic theme schedule.
- **Added:** Created emulators from hardware profiles and Android images, with custom names, storage settings, and separate **Create** and **Create & Start** actions. Stopped emulators could be deleted after confirmation, while shared system images were retained.
- **Added:** Guided Node.js setup with installation instructions and retry controls when the required runtime was missing, unusable, or too old.
- **Added:** Showed app information, source links, and credits in an About tab. Settings no longer focused a tab automatically when opened, while keyboard navigation remained available.
- **Added:** Showed allocated disk usage beside stopped and running emulators, including snapshots but excluding shared SDK images.
- **Added:** Offered optional device icons and AVD names in the macOS Dock and app switcher through **Settings → Emulators**. Supported builds could be patched after a signing acknowledgment, repaired, or restored to their original files and signature.
- **Changed:** Bundled the emulator creation/deletion helper so a separate helper installation was no longer needed. Node.js 24+ remained an external requirement, with explicit runtime and helper overrides available in Settings.
- **Changed:** Placed APK installation first in the toolbar, explained when it was unavailable, and grouped severity colors under a dedicated Logcat settings tab.
- **Fixed:** Signed the native emulator-appearance helpers inside the bundled archive so the app could pass Apple notarization while retaining integrity checks.
- **Fixed:** Kept the main view compatible with the stable Xcode toolchain without changing its behavior.
- **Fixed:** Rendered toolbar icons and section dividers consistently at launch.
- **Fixed:** Recognized emulator host windows whose executable names matched their AVD names, preserving window reveal and standalone/embedded detection with appearance tweaks installed.
- **Fixed:** Let the device list fill a resized main window so enlarging it revealed more devices.

### Documentation

- **Added:** Documented the device dark-theme toggle and its behavior with automatic theme schedules.
- **Added:** Documented emulator creation, hardware filtering, storage limits, safe deletion, and validation steps.
- **Added:** Documented automatic macOS unit-test checks for pull requests and changes to the main branch.
- **Added:** Documented the bundled emulator helper, external Node.js requirements, runtime overrides, and package provenance.
- **Added:** Documented authored release notes and a resumable signing, notarization, and publication workflow.
- **Added:** Documented Node.js setup guidance and retry controls.
- **Added:** Documented the About tab and Settings navigation.
- **Added:** Documented emulator disk-usage measurements and their exclusions.
- **Added:** Recorded the published 0.3.0 release notes and synchronized release examples.
- **Added:** Documented emulator appearance compatibility, signing acknowledgment, backups, repair, and restoration.
- **Changed:** Updated the Settings and Logcat guides for the dedicated Logcat tab and APK toolbar behavior.
- **Changed:** Identified Apache 2.0 as the project license and linked bundled-component license notices.
- **Changed:** Replaced the README feature inventory with short workflow descriptions and screenshots, and moved detailed setup and usage instructions into a separate guide.
- **Changed:** Documented signed dependency packaging, upstream provenance, and offline signing checks.

### MCP Helper

- **Changed:** Kept the reported server version aligned with the published app version.

Pull requests:
- [feat: add inline device dark theme toggle](https://github.com/androperator/adbuddy/pull/1)
- [feat(emulators): add creation and safe deletion workflows](https://github.com/androperator/adbuddy/pull/2)
- [ci(tests): run macOS tests on every pull request](https://github.com/androperator/adbuddy/pull/3)
- [feat(emulators): bundle pinned helper with external Node support](https://github.com/androperator/adbuddy/pull/4)
- [feat(release): add authored notes and resumable publication](https://github.com/androperator/adbuddy/pull/5)
- [feat(emulators): guide Node.js setup and clarify settings](https://github.com/androperator/adbuddy/pull/6)
- [fix(ui): stabilize main toolbar and section dividers](https://github.com/androperator/adbuddy/pull/7)
- [feat(settings): add About tab and avoid automatic keyboard focus](https://github.com/androperator/adbuddy/pull/8)
- [fix(ui): clarify APK availability and group Logcat settings](https://github.com/androperator/adbuddy/pull/9)
- [feat(emulators): show disk usage beside Android version](https://github.com/androperator/adbuddy/pull/10)
- [chore(release): record the published 0.3.0 release](https://github.com/androperator/adbuddy/pull/11)
- [fix(emulator): recognize AVD-named host windows](https://github.com/androperator/adbuddy/pull/12)
- [test(media): await explicit Finder reveal completion](https://github.com/androperator/adbuddy/pull/13)
- [feat(emulators): bundle opt-in macOS appearance tweaks](https://github.com/androperator/adbuddy/pull/14)
- [chore(license): adopt Apache 2.0](https://github.com/androperator/adbuddy/pull/15)
- [fix(window): expand device list when resizing the main window](https://github.com/androperator/adbuddy/pull/16)
- [docs(readme): showcase device workflows with screenshots](https://github.com/androperator/adbuddy/pull/17)

## [0.3.0] - 2026-10-10

ADBuddy added emulator creation and safe deletion, showed emulator disk usage, and made device controls and Settings clearer. Emulator creation and deletion used the bundled helper and required a separately installed Node.js 24 or newer.

### macOS App

- **Added:** Created Android emulators in a native window with hardware and system-image choices, suggested names, configurable storage capacity, and separate **Create** and **Create & Start** actions. Installed images remained available when the online catalog failed, and creation did not accept SDK licenses automatically.
- **Added:** Deleted stopped emulators after a confirmation naming the device, while retaining shared SDK system images and checking that the emulator had not started before deletion.
- **Added:** Toggled each connected device's dark theme from its row or the menu bar.
- **Added:** Showed allocated disk usage in GiB beside Android version details for stopped and running emulators. Measurements included AVD files and snapshots, excluded shared SDK images, and refreshed in the background about every 30 seconds.
- **Added:** Guided Node.js installation and provided retry controls when the runtime was missing, unusable, or older than version 24.
- **Added:** Included an About tab with the app version, source link, credits, and Android automation information.
- **Changed:** Bundled the pinned `@androperator/emulator` 0.2.0 helper for creation and deletion. Node.js 24+ remained an external prerequisite; Settings showed the active helper and runtime paths and supported explicit overrides.
- **Changed:** Put Node.js setup first in Emulator settings, with Java, custom helper paths, and diagnostics under Advanced.
- **Changed:** Grouped severity color controls in the renamed Logcat settings tab and placed **Install APK** before **Create Emulator** and **Settings** in the main toolbar.
- **Fixed:** Rendered toolbar icons clearly at launch and kept the toolbar separator and device-section dividers visible and consistent.
- **Fixed:** Showed APK installation as clearly disabled, with an explanatory tooltip, when no usable device was connected.
- **Fixed:** Avoided automatically focusing a Settings tab when the window opened, while preserving keyboard Tab navigation.

### Documentation

- **Added:** Documented emulator creation, hardware filtering, catalog loading, storage configuration, safe deletion, and their validation steps.
- **Added:** Documented automatic macOS unit-test checks for pull requests and updates to the main branch.
- **Added:** Documented release-note authoring and a release workflow that resumed from verified completed stages without replacing tags or uploaded assets.
- **Added:** Documented emulator disk-usage measurements and their exclusions.
- **Changed:** Updated device-setting documentation for the inline dark-theme toggle.
- **Changed:** Documented the pinned emulator helper, external Node.js prerequisite, runtime discovery, override behavior, and packaging provenance.
- **Changed:** Updated the product scope for Node.js installation guidance and retry controls.
- **Changed:** Updated Settings documentation for the About tab and the dedicated Logcat tab.

Pull requests:
- [feat: add inline device dark theme toggle](https://github.com/androperator/adbuddy/pull/1)
- [feat(emulators): add creation and safe deletion workflows](https://github.com/androperator/adbuddy/pull/2)
- [ci(tests): run macOS tests on every pull request](https://github.com/androperator/adbuddy/pull/3)
- [feat(emulators): bundle pinned helper with external Node support](https://github.com/androperator/adbuddy/pull/4)
- [feat(release): add authored notes and resumable publication](https://github.com/androperator/adbuddy/pull/5)
- [feat(emulators): guide Node.js setup and clarify settings](https://github.com/androperator/adbuddy/pull/6)
- [fix(ui): stabilize main toolbar and section dividers](https://github.com/androperator/adbuddy/pull/7)
- [feat(settings): add About tab and avoid automatic keyboard focus](https://github.com/androperator/adbuddy/pull/8)
- [fix(ui): clarify APK availability and group Logcat settings](https://github.com/androperator/adbuddy/pull/9)
- [feat(emulators): show disk usage beside Android version](https://github.com/androperator/adbuddy/pull/10)
