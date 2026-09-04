# THE RELEASE LAW

**Owner law, set 2026-09-04 (v0.3.3 round):** GitHub Releases are NOT automatic
anymore and NOT per-build by default.

## The rule

- A push to `main` builds via CI - that is the default delivery. **Wait for the
  green build. That is all.**
- **No GitHub Release is created automatically.** Not on version bumps, not on
  patches, not on CI success.
- A Release (tag + release page + APK assets + notes) is created **only when the
  owner explicitly asks for one** ("make a release", "ship the release", etc.).
- Exception that proves the law: re-arming an EXISTING release with fresh APKs
  (the v0.3.2 PATCH IV hotfix pattern) still counts as owner-requested only.

## Why

The owner noticed releases started being cut for every build somewhere around
the v0.1.0 context reset and never stopped. The box moved to a push-and-wait
cadence; the releases page should stay a deliberate shelf, not a log.

## Checklist when a release IS requested

1. `git push` first, CI green.
2. Build both ABIs locally (`bash build.sh gogabox`), verify signature + cert
   SHA-256 continuity (overwrite-install safe).
3. `gh release create <tag>` with the APKs, or re-arm the existing tag
   (delete old assets, upload fresh under the same names).
4. Release notes in the owner's voice: what changed, what to test.
