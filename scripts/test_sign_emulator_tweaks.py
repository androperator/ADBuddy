#!/usr/bin/env python3
"""Validate signed tweaks packaging without changing an SDK or using credentials."""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import tempfile
import unittest

from sign_emulator_tweaks import sign_archive

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(sys.platform == 'darwin', 'Requires macOS codesign')
class SignedTweaksTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.contents = Path(self.temporary.name) / 'Contents'
        self.resources = self.contents / 'Resources/EmulatorTweaks'
        self.resources.mkdir(parents=True)
        self.manifest = json.loads((ROOT / 'bundled-dependencies.json').read_text())
        self.original = (ROOT / self.manifest['emulatorTweaks']['archive']).read_bytes()
        (self.resources / 'package.tgz').write_bytes(self.original)
        (self.resources / 'bundled-dependencies.json').write_text(json.dumps(self.manifest))

    def testSignedArchiveRetainsPayloadAndPassesUpstreamIntegrityChecks(self):
        sign_archive(self.contents, '-')
        archive = self.resources / 'package.tgz'
        metadata = json.loads((self.resources / 'bundled-dependencies.json').read_text())['emulatorTweaks']
        self.assertEqual(metadata['upstreamArchive']['sha256'], hashlib.sha256(self.original).hexdigest())
        self.assertEqual(metadata['sha256'], hashlib.sha256(archive.read_bytes()).hexdigest())
        changed = {'package/assets/launcher/launcher', 'package/assets/launcher/manifest.json',
                   'package/assets/runtime/helper.dylib', 'package/assets/runtime/manifest.json'}
        with tarfile.open(ROOT / self.manifest['emulatorTweaks']['archive']) as original, tarfile.open(archive) as signed:
            old = {m.name: original.extractfile(m).read() for m in original if m.isfile()}
            new = {m.name: signed.extractfile(m).read() for m in signed if m.isfile()}
        self.assertEqual(old.keys(), new.keys())
        for name in old.keys() - changed:
            self.assertEqual(old[name], new[name], name)
        unpack = Path(self.temporary.name) / 'unpack'
        unpack.mkdir()
        subprocess.run(['/usr/bin/tar', '-xzf', str(archive), '-C', str(unpack)], check=True)
        node = shutil.which('node')
        self.assertIsNotNone(node, 'Node is required to validate the packaged CLI')
        script = """
import {pathToFileURL} from 'node:url';
import {join} from 'node:path';
const root = process.argv[1];
const {readNamingBundle} = await import(pathToFileURL(join(root, 'src/names.js')));
const {readRuntime} = await import(pathToFileURL(join(root, 'src/runtime.js')));
const {macOS} = await import(pathToFileURL(join(root, 'src/platform.js')));
await readNamingBundle(root, macOS);
await readRuntime(join(root, 'assets/runtime'), macOS);
"""
        subprocess.run([node, '--input-type=module', '-e', script, str(unpack / 'package')], check=True)
        self.assertEqual((ROOT / self.manifest['emulatorTweaks']['archive']).read_bytes(), self.original)

    def testCorruptArchiveIsRejectedWithoutChangingManifest(self):
        (self.resources / 'package.tgz').write_bytes(b'corrupt')
        before = (self.resources / 'bundled-dependencies.json').read_bytes()
        with self.assertRaisesRegex(ValueError, 'checksum mismatch'):
            sign_archive(self.contents, '-')
        self.assertEqual((self.resources / 'bundled-dependencies.json').read_bytes(), before)

    def testSigningFailureLeavesOriginalArchiveAndManifestUntouched(self):
        before = (self.resources / 'bundled-dependencies.json').read_bytes()
        with self.assertRaises(subprocess.CalledProcessError):
            sign_archive(self.contents, 'ADBuddy deliberately nonexistent test identity')
        self.assertEqual((self.resources / 'package.tgz').read_bytes(), self.original)
        self.assertEqual((self.resources / 'bundled-dependencies.json').read_bytes(), before)


if __name__ == '__main__':
    unittest.main()
