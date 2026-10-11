#!/usr/bin/env python3
"""Sign a packaged copy of the pinned tweaks archive and refresh its checksums."""
import base64
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def sign_archive(contents, identity):
    resources = contents / 'Resources/EmulatorTweaks'
    archive = resources / 'package.tgz'
    manifest_path = resources / 'bundled-dependencies.json'
    dependencies = json.loads(manifest_path.read_text())
    package = dependencies['emulatorTweaks']
    if digest(archive) != package['sha256']:
        raise ValueError('Emulator tweaks archive checksum mismatch before signing')
    upstream = {'sha256': package['sha256'], 'integrity': package['integrity']}
    with tempfile.TemporaryDirectory(prefix='ADBuddySignedTweaks-') as temporary:
        root = Path(temporary)
        subprocess.run(['/usr/bin/tar', '-xzf', str(archive), '-C', str(root)], check=True)
        assets = root / 'package/assets'
        launcher_manifest_path = assets / 'launcher/manifest.json'
        runtime_manifest_path = assets / 'runtime/manifest.json'
        launcher_manifest = json.loads(launcher_manifest_path.read_text())
        runtime_manifest = json.loads(runtime_manifest_path.read_text())
        launcher = assets / 'launcher/launcher'
        runtime = assets / 'runtime/helper.dylib'
        if digest(launcher) != launcher_manifest['sha256']:
            raise ValueError('Emulator launcher checksum mismatch before signing')
        for name, expected in runtime_manifest['files'].items():
            if digest(assets / 'runtime' / name) != expected:
                raise ValueError(f'Emulator runtime checksum mismatch: {name}')
        timestamp = '--timestamp=none' if identity == '-' else '--timestamp'
        for binary in (launcher, runtime):
            subprocess.run(['/usr/bin/codesign', '--force', '--options', 'runtime', timestamp,
                            '--sign', identity, str(binary)], check=True)
            subprocess.run(['/usr/bin/codesign', '--verify', '--strict', str(binary)], check=True)
        launcher_manifest['sha256'] = digest(launcher)
        runtime_manifest['files']['helper.dylib'] = digest(runtime)
        launcher_manifest_path.write_text(json.dumps(launcher_manifest, indent=2) + '\n')
        runtime_manifest_path.write_text(json.dumps(runtime_manifest, indent=2) + '\n')
        signed_archive = root / 'signed.tgz'
        subprocess.run(['/usr/bin/tar', '-czf', str(signed_archive), '-C', str(root), 'package'],
                       env={**os.environ, 'COPYFILE_DISABLE': '1'}, check=True)
        data = signed_archive.read_bytes()
        package['upstreamArchive'] = upstream
        package['sha256'] = hashlib.sha256(data).hexdigest()
        package['integrity'] = 'sha512-' + base64.b64encode(hashlib.sha512(data).digest()).decode()
        archive.write_bytes(data)
        manifest_path.write_text(json.dumps(dependencies, indent=2) + '\n')
    print('Signed emulator tweaks native assets and refreshed packaged checksums')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit('usage: sign_emulator_tweaks.py <app Contents> <signing identity>')
    sign_archive(Path(sys.argv[1]).resolve(), sys.argv[2])
