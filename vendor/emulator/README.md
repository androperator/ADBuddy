# Bundled emulator helper

[bundled-dependencies.json](../../bundled-dependencies.json) is the source of truth
for the helper version, archive location, download URL, checksum and
helper provenance. A copy ships in `Contents/Resources/Emulator` for inspection.

ADBuddy vendors the unmodified published `@androperator/emulator` 0.3.0 npm
archive named by the manifest. Import verifies npm SHA-512 integrity, and
packaging checks SHA-256 before extracting the exact archived bytes. The
manifest records the upstream source repository and release commit.
The helper supports protocol 1 and catalog.profiles/catalog.images/dhu. It uses only
Node built-ins and relative modules, with no npm production runtime dependencies.
The archive includes Apache-2.0 LICENSE, NOTICE and upstream provenance.
TypeScript and @types/node are build-only dependencies and excluded from the app.

Normal packaging uses these exact archived bytes without npm or a local helper
checkout. To verify source tests, check out the source commit in the manifest, run `npm ci`
against its lockfile, then `npm run build` and `npm test` with Node 24+. The checked-in npm
archive is the pin; packaging never repacks it.
Update the pin only after contract tests and packaged runtime verification.

`scripts/prepare_emulator_backend.sh` packages only the JavaScript helper and
notices. Node.js 24+ must be installed separately; no runtime binaries, Node
licenses, downloads or signing entitlements are included. Node resolution and
explicit overrides are documented in [development.md](../../docs/development.md).
SDK tools, system images and Java remain external.

To update a dependency, change its manifest entry, vendor the matching helper
archive when applicable, and verify upstream integrity and license notices.
Run the packaged-runtime tests documented in [development.md](../../docs/development.md).
Tests compare the running helper version with the manifest and check that its bundled
copy matches the repository file. Scripts and tests do not carry separate pins.
