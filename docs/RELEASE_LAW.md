# THE RELEASE LAW

**Owner law, set 2026-09-04 (v0.3.3 round):** GitHub Releases are NOT automatic
anymore and NOT per-build by default.

## THE TWO-PLATFORM LAW (the ANDROID-ONLY law is REPEALED)

**Owner law, set 2026-09-19 (the open-source round):** GOGABox builds for
ANDROID and WINDOWS again — the old "no way to make money from windows
builds" reason is gone (the box is MIT + 0 ads now, money was never the
point). ONE build action (`build.yml`) ships both: the APKs (arm32 + arm64)
and THE one Windows exe — `GOGABox.exe`, x86_32, official templates (SSE2
baseline: it runs on pre-2014 CPUs with no SSE4.2), single file with the
embedded pck, verified by THE REAL-EXE LAW in CI. No 64-bit exe, no
template forging.

The PC-side laws ride along: THE VERTICAL SLICE LAW (portrait games render
a KEEP-aspect slice with the box brown sides), per-game keyboard/mouse
controls (`controls_pc` in the registry + the guide's HOW TO PLAY - PC),
THE PLATFORM LAW (os tags + the PHONE/PC filter chips), and notifications
stay a desktop no-op. The full original windows round is recorded in
`docs/goga_docs/plans/PLAN_v034p3_AND_WINDOWS.md`; the 2026-09-06 rollback
that buried it is recorded in
`docs/goga_docs/plans/PLAN_v034p4_ANDROID_ONLY.md` (history, kept).

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


## THE LAN NOTE (v042)

The v042 build carries the Android INTERNET permission — LAN peer-to-peer
sockets need it even on a local wifi. The box still ships NO servers, NO
telemetry and NO online services: the permission exists for the LAN
sessions and the room-code joins only (see AGENTS.md §4 + law 57). The
store-disclosure line: "GOGABox plays multiplayer on your local network;
it never talks to a server."
