---
name: release-adbuddy
description: Prepare, publish, or resume an ADBuddy release end to end, including version synchronization, authored notes, signed macOS archives, GitHub verification, and Homebrew cask updates and validation. Also handles version-only bumps and explicitly scoped packaging or upload requests.
---

# ADBuddy releases

`VERSION` is the release version source of truth. The packaging scripts use it
for app bundle metadata and archive names. The MCP server and current release
examples must remain synchronized. Read [docs/release.md](../../../docs/release.md)
for signing, notarization, and distribution requirements.

## Choose the scope

- A version-bump request runs **Version bump** only.
- A request to release or publish version X runs **Release end to end**, including
  version preparation and the Homebrew cask update after verified publication.
  This scope includes cask validation, a tap branch commit and push, and opening
  or updating its PR. Honor explicit exclusions. A request to resume an authorized
  release continues that same version and scope.
- For packaging, tag-only, or asset-upload requests, perform the necessary
  prerequisites and stop at the requested stage. Packaging alone does not
  authorize pushing a tag or publishing a GitHub Release.
- Version-only, packaging-only, tag-only, and upload-only requests do not update
  the tap unless requested. Do not advance to the next development version.
  ADBuddy has one version source, with no separate published-version follow-up.
- Do not merge the tap PR, enable auto-merge, or push directly to its default
  branch unless the user explicitly requests it.

Use the version and release commit already selected by the user. For publication,
require a stable bare `major.minor.patch` version, such as `0.2.2`. Ask only if the
intended version or source commit remains ambiguous; do not infer a new version
on resume.

## Version bump

1. Inspect `git status --short` and preserve unrelated changes. If `VERSION`
   already matches the target, run the helper with `--check` instead of bumping
   again. Verify the synchronized files are committed; matching working files
   alone do not complete this stage.
2. Otherwise run:

   ```bash
   python3 .agents/skills/release-adbuddy/scripts/set_release_version.py <new-version>
   ```

   The helper validates the current synchronized version and updates only
   `VERSION`, MCP `serverInfo`, current release-document examples, and the
   packaging-script version example. If synchronization is inconsistent, inspect
   and repair the affected version fields before retrying; preserve other edits.
3. Review changed files, run `git diff --check`, and run `scripts/test.sh` when
   version fields changed. Stage only the version changes and commit separately:

   ```text
   chore(release): bump version to <new-version>
   ```

The helper does not commit, tag, or publish. If the target is already committed
and synchronized, do not create an empty or duplicate version commit.

## Release end to end

### Establish state and resume

Inspect the worktree, committed version surfaces, target changelog entry, prior
validation evidence, local archives, local and remote `v<version>` tags, and the
GitHub Release. Use the configured repository, not a hard-coded owner.
Read-only checks include `git ls-remote --tags origin` and:

```bash
gh release view v<version> --json tagName,name,body,isDraft,isPrerelease,isImmutable,assets,url
```

A network or authentication error does not prove that a tag or release is absent.
Resolve it before publication. Compare tag targets as peeled commit SHAs, not
annotated tag object IDs or GitHub's `targetCommitish` branch name.

Resume at the first incomplete stage below. Recheck dependencies before skipping
a stage. Record the release commit, completed checks, artifact SHA-256 values,
and remote state in progress updates so a later run can verify them. Never infer
completion from a filename or an earlier claim alone.

| Stage | Evidence required to skip it |
|---|---|
| Version | Target version and all synchronized surfaces are committed and pass the helper's `--check`. |
| Notes | Exactly one complete target entry can be extracted from the intended commit and covers the release range. |
| Validation and packaging | Passing checks and all four public archives are tied to the exact release commit, with recorded hashes and signing/notarization verification. |
| Tag | The local and remote tag, where present, resolve to the validated release commit. Push only if the remote tag is absent. |
| GitHub Release | The release uses that tag and authored body; all four assets are present and their downloaded bytes match the validated hashes. |
| Homebrew cask | The target universal ZIP URL, version, and downloaded SHA-256 are committed in the public tap, or in an existing PR at the validated HEAD. Record whether publication is merged or pending. |

If an existing release or tag identifies another commit, stop and report the
conflict. Never move or delete a release tag. If resuming a tagged release, use
its exact commit for any necessary local validation or rebuilding; do not bump
the current branch back to an older version. If the published release already
passes all checks, continue with any unfinished cask stage without rebuilding or
republishing.

### Complete the remaining stages

1. **Prepare the version.** Run **Version bump** when needed, then validate with:

   ```bash
   python3 .agents/skills/release-adbuddy/scripts/set_release_version.py <version> --check
   ```

2. **Author release notes.** Select the previous published release tag that is
   an ancestor of the intended release commit. If the target entry is absent or
   incomplete, use [release-notes-author](../release-notes-author/SKILL.md) with
   that tag and the intended end ref, review the entry, and commit it. Reuse a
   complete entry. After all preparation commits, record the exact clean release
   commit and extract its body:

   ```bash
   python3 .agents/skills/release-notes-author/scripts/extract_release_notes.py <version> <commit> > /tmp/adbuddy-release-notes.md
   ```

   Stop if extraction fails. If the user selected an immutable commit that lacks
   preparation, explain that a new release commit is needed before tagging.

3. **Validate and package.** Run `scripts/test.sh` on the clean release commit
   unless passing results for that exact commit are already established. Build
   the public artifacts with notarization:

   ```bash
   ADBUDDY_NOTARY_PROFILE="<Keychain profile>" scripts/package_release.sh
   ```

   Do not use `--local` or `--skip-notarization` for publication. The script
   builds both architectures and the universal app, notarizes and staples each,
   verifies signatures and Gatekeeper acceptance, and prints archive hashes.
   Keep all four matching assets:
   `dist/release/ADBuddy-macos-<architecture>-<version>.zip`, where architecture
   is `arm64`, `x86_64`, or `universal`, plus
   `dist/release/ADBuddy-recording-sources-<version>.zip`.
   Reuse archives only with evidence linking their hashes and successful public
   packaging to this commit; otherwise rebuild before any upload. Record the
   hashes and preserve the verified archives for interrupted uploads.

4. **Create or finish pushing the tag.** Recheck remote state immediately before
   mutation. If the local tag is absent, create it at the validated commit:

   ```bash
   git tag -a v<version> <commit> -m "Release v<version>"
   ```

   Reuse a matching existing tag. If the remote tag is absent, push that tag only:

   ```bash
   git push origin refs/tags/v<version>
   ```

5. **Create or finish the GitHub Release.** If absent, create it with the existing
   remote tag and all four verified archives:

   ```bash
   gh release create v<version> dist/release/ADBuddy-macos-universal-<version>.zip \
     dist/release/ADBuddy-macos-arm64-<version>.zip \
     dist/release/ADBuddy-macos-x86_64-<version>.zip \
     dist/release/ADBuddy-recording-sources-<version>.zip \
     --verify-tag --title "ADBuddy <version>" \
     --notes-file /tmp/adbuddy-release-notes.md
   ```

   On resume, inspect an existing release before mutation. If its tag and body
   match, use `gh release upload v<version> <missing-assets...>` for missing
   assets only, after checking the existing assets against the recorded hashes.
   Do not use `--clobber`, replace existing assets, or rewrite published notes.
   An explicit request to resume publication authorizes completing these missing
   uploads. Publish a matching draft only after verifying all four assets, using
   `gh release edit v<version> --draft=false --verify-tag`.
   Conflicting notes, mismatched assets, or an immutable incomplete release need
   explicit repair direction; report the exact state and stop.

6. **Verify publication.** Inspect the live release and confirm the tag commit,
   authored body, non-draft/non-prerelease status, and all four asset names.
   Download the assets to a temporary directory and compare SHA-256 values with
   the verified local archives or recorded release hashes. Report the release
   URL, commit, hashes, and any runtime checks not performed. Public completion
   requires these checks; failed or incomplete uploads are not a completed
   release. Clean-machine and native Intel runtime checks remain separate from
   packaging verification as described in `docs/release.md`.

7. **Update and validate the Homebrew cask.** After stage 6 succeeds, use
   `androperator/homebrew-tap`, normally at the sibling `../homebrew-tap` checkout
   (`/Users/chrislacy/src/androperator/homebrew-tap` on this host). Verify its
   remote and read its repository instructions. Fetch its `origin/main`, preserve
   unrelated work, and use a release-specific task branch. The tap's npm updater
   touches only CLI/emulator formulae; do not change them for an ADBuddy release.

   Update `Casks/adbuddy.rb` to the target version and
   `ADBuddy-macos-universal-<version>.zip` URL from the verified GitHub Release.
   Set `sha256` from the downloaded ZIP bytes and compare it with stage 6's
   recorded hash. Preserve the macOS minimum, `app "ADBuddy.app"`, and cleanup
   behavior unless the release changes them. The app identity is
   `com.androperator.adbuddy`; the shared preferences domain intentionally remains
   `com.clawperator.adbuddy`. Keep Node optional in the cask.

   Before running Homebrew checks, verify it resolves the candidate checkout and
   target URL/checksum rather than another installed tap. If necessary, use a
   separate test tap or test host instead of replacing an unrelated checkout.
   From the candidate tap checkout, run:

   ```bash
   git diff --check
   ruby -c Casks/adbuddy.rb
   HOMEBREW_NO_AUTO_UPDATE=1 brew style --cask androperator/tap/adbuddy
   HOMEBREW_NO_AUTO_UPDATE=1 brew audit --cask --online androperator/tap/adbuddy
   ```

   Extract the ZIP with `ditto` and check version, identifier, both architectures, signature,
   Gatekeeper acceptance, and stapling. When no ADBuddy cask is already installed,
   test installation with `--appdir=<temporary-directory>` and uninstall that
   test installation without `--zap`. Preserve existing apps, preferences, and
   captures. If an existing installation prevents a safe install/upgrade check,
   report that limit and validate the archive and cask without replacing it.

   Commit only the cask and necessary tap documentation, push the task branch,
   and open or update a PR against the tap's `main`. Include the release URL,
   universal ZIP hash, validation, and any untested runtime or upgrade behavior.
   Verify the PR HEAD matches the validated commit. A matching published cask or
   matching validated PR can be reused on resume; do not create duplicate commits
   or PRs. Do not downgrade a newer public cask when resuming an older release;
   report that the target has been superseded. Conflicting target-version URLs
   or checksums require investigation before publication.

   Report the app release and tap PR separately. An open PR means cask publication
   is pending. When merge is explicitly authorized, verify the merged public cask
   contains the validated version, URL and checksum, and perform a safe public-tap
   installation check or state why an existing installation prevents it.

If any external step fails, inspect its resulting state and report the first
incomplete stage. Preserve successful prior stages. Continue only within the
existing authorization; a later resume request can finish the same release
without recreating its tag or repeating completed work. Do not push app release
preparation branches unless explicitly requested; tap branch publication follows
the end-to-end scope above.
