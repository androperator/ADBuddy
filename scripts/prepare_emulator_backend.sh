#!/usr/bin/env bash
# Package checksum-verified immutable emulator helpers; Node remains external.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DESTINATION="${1:?usage: prepare_emulator_backend.sh Contents}"
MANIFEST="$ROOT_DIR/bundled-dependencies.json"
manifest_value() {
  /usr/bin/plutil -extract "$1" raw -o - "$MANIFEST"
}
mkdir -p "$DESTINATION/Resources/Emulator"
HELPER="$ROOT_DIR/$(manifest_value emulator.archive)"
HELPER_CHECKSUM="$(manifest_value emulator.sha256)"
[[ "$(shasum -a 256 "$HELPER" | cut -d ' ' -f 1)" == "$HELPER_CHECKSUM" ]] || {
  echo "Emulator helper checksum mismatch: $HELPER" >&2; exit 1;
}
rm -rf "$DESTINATION/Resources/Emulator/package"
tar -xzf "$HELPER" -C "$DESTINATION/Resources/Emulator"
cp "$MANIFEST" "$DESTINATION/Resources/Emulator/bundled-dependencies.json"
cp "$ROOT_DIR/vendor/emulator/README.md" "$DESTINATION/Resources/Emulator/Provenance.md"

# Keep native tweaks assets inside their immutable archive; do not re-sign them.
TWEAKS="$ROOT_DIR/$(manifest_value emulatorTweaks.archive)"
[[ "$(shasum -a 256 "$TWEAKS" | cut -d ' ' -f 1)" == "$(manifest_value emulatorTweaks.sha256)" ]] || {
  echo "Emulator tweaks checksum mismatch: $TWEAKS" >&2; exit 1;
}
mkdir -p "$DESTINATION/Resources/EmulatorTweaks"
cp "$TWEAKS" "$DESTINATION/Resources/EmulatorTweaks/package.tgz"
cp "$MANIFEST" "$DESTINATION/Resources/EmulatorTweaks/bundled-dependencies.json"
cp "$ROOT_DIR/vendor/emulator-tweaks/README.md" "$DESTINATION/Resources/EmulatorTweaks/Provenance.md"

cp "$ROOT_DIR/Resources/EmulatorTweaks/"*.png "$DESTINATION/Resources/EmulatorTweaks/"
