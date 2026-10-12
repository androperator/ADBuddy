# Bundled emulator macOS tweaks

ADBuddy vendors the unmodified published `@androperator/emulator-macos-tweaks`
1.0.3 npm archive with broader 37.x compatibility. Version, registry URL, integrity, SHA-256 and source commit are
pinned in [bundled-dependencies.json](../../bundled-dependencies.json).

The archive includes its Apache-2.0 LICENSE and NOTICE.md artwork attribution.
Packaging first verifies the upstream checksum. Public release packaging signs
the native launcher and icon helper in a temporary copy with Developer ID,
hardened runtime, and secure timestamps so Apple can notarize the nested code.
It refreshes the internal native-asset hashes and the packaged archive checksum;
the bundled dependency manifest retains the upstream checksums separately under
`upstreamArchive`. JavaScript, artwork, licenses, and original-emulator hashes are
unchanged. Local release packaging uses ad-hoc signatures. Development builds
retain the original archive.

The app verifies the packaged archive before extracting a temporary command
installation, and the CLI verifies the updated native-asset hashes. The outer
app signature seals both the archive and manifest. Temporary installations are removed after use;
the patch's own runtime and exact original backups remain in the CLI backup folder.

Node.js is external. Naming records its absolute executable path at apply time.
No SDK changes happen during packaging, status checks, or extraction.
