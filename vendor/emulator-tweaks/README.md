# Bundled emulator macOS tweaks

ADBuddy includes the unmodified published `@androperator/emulator-macos-tweaks`
1.0.2 npm archive. Version, registry URL, integrity, SHA-256 and source commit are
pinned in [bundled-dependencies.json](../../bundled-dependencies.json).

The archive includes its Apache-2.0 LICENSE and NOTICE.md artwork attribution.
Packaging verifies its checksum and copies it intact into Resources/EmulatorTweaks.
The app verifies it again before extracting a temporary command installation.
Keeping the native assets archived preserves their manifest hashes and ad-hoc
signatures during ADBuddy signing. Temporary installations are removed after use;
the patch's own runtime and exact original backups remain in the CLI backup folder.

Node.js is external. Naming records its absolute executable path at apply time.
No SDK changes happen during packaging, status checks, or extraction.
