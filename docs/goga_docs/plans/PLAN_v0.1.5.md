# PLAN v0.1.5 — THE POLISH & SHARED-SYSTEM PATCH

Owner directive (2026-08-31): "ok there is now just two simple things that
needs patching" - (1) the weird background dots, (2) the hardcoded toast
text size. Plus the standing architecture rule: the v0.1.4 brainstorms must
be an EXPANDING shared GOGABox system, never a replacement of old paths.
The owner will NOT test this one directly; v0.1.6 gets tested on top of it.

## 1. THE DOTS - found, then removed at BOTH sources

Owner: "the box background has weird dots, 3 dots per line somehow, i
thought this is in the background image itself, and now i am sure they are,
somehow try to use code to see these dots and modify the values of the
image to remove them while preserve the colors behind it, it's an alpha
color, so i guess you can do it via code."

WHAT THE CODE-PROBE FOUND (`scripts/v015_bg_probe2.py` outside the repo):

- The LIVE background is `bg_stripe.gdshader` (code-drawn since v0.1.2) and
  it re-creates a STAGGERED dot grid (216x330 design px, r 7-10, mixed at
  0.9) - that is what the owner sees on device. The dots were inherited
  from the original png's accents when v0.1.2 "detected the colors".
- `bg_main.png` itself is RGB with FLAT alpha (no alpha channel at all -
  the "alpha color" hunch was close but the dots are baked OPAQUE pixels):
  a perfect 5x6 grid, centers x = 72 + 144k, y = 90 + 220k (144x220 px at
  720-wide), solid r ~5.6 px + soft fringe, exactly 30 dots.

THE FIX, BOTH SOURCES:

- Shader: the dot-grid block and the `dot_col` uniform are DELETED - the
  field is pure stripes + vertical shade + sheen. "Preserve the colors
  behind it" is structural: the dots simply stop being painted over the
  stripe field. menu.gd drops `BG_DOT` and its wiring.
- PNG: `scripts/v015_bg_inpaint.py` masks the 30 discs (r 9) and rebuilds
  the colors BEHIND them by diffusion (normalized-convolution inpainting -
  the surrounding stripe gradient flows into each hole). Verified by
  `scripts/v015_bg_verify.py` against the git original: outside the discs
  BIT-IDENTICAL, all 30 dot blobs eliminated (30 -> 0 by re-detection),
  mean change inside a disc ~5 levels. The asset stays honest for any
  future color re-derivation.

## 2. THE TOAST - dynamic text size (ui_kit.gd)

Owner: "the word 'the box bank is dry - it charges while gogab...' in-app
pop-up is using hardcoded text size, make it dynamic based on chars and the
universal resolution so it detects where the letters will land and use
smaller text size."

- `Arc.toast()` now MEASURES the real line every time it fires:
  `fit_size(msg, base, viewport_width - 48, font, floor 14)` - the font
  steps down until the rendered width lands inside the safe 24 px side
  margins, single line. Short toasts keep the base size; long ones shrink
  themselves at ANY resolution (the viewport rect under the stretch system
  IS the universal design-px ruler).
- The measuring loop is promoted to the shared `Arc.fit_size()` (fit_label's
  private loop, now THE one measurer) - `fit_label` delegates to it, so
  every dynamic-text spot in the box uses the same rule (the owner's
  shared-system principle applied to UI code too).
- The known offender ("the box bank is dry - it charges while GOGABox is
  closed", 58 chars) now lands ~26 px at 1080 design width instead of
  clipping at the screen edge.

## 3. THE SHARED-SYSTEM AUDIT - "expand, don't replace"

Owner: "make sure that my brainstorms when you implemented them, you have
not removed old code, i mean, when i said some games and some games, i
meant expand the code so later we make the new games with different ways to
get owned and not to replace something existing, just make sure the code
arch makes this a GOGABox shared system so we can later use it easily
without coding everything everytime."

AUDIT RESULT (v0.1.4 was already additive - verified line by line):

- store.gd: the v0.1.4 sections (GOGACharges, daily limits, partial pay)
  are NEW blocks; wallet / batteries / box bank / skins / achievements /
  favorites / badges / interstitials all untouched. `unlock_game(id, price)`
  - the original coin-buy path - still exists and still works.
- roadmap.gd: the state machine kept HIDDEN/MYSTERY/GATED/SOON/LOCKED/OWNED
  and ADDED CHARGING as a new state; reveal kinds chain/orders/inbox/real
  all kept, `direct` added, orders gained the `spend_charges` type.
- registry.gd: every brainstorm is per-game METADATA (reveal.*, charge_unlock,
  hours, daily_rounds/daily_minutes) - adding a game with a different
  combination of unlock ways = data, no new code.

THE ONE HARDening PASS (game-specific leftovers -> registry policy):

- Found: the v0.1.4 snake partial-pay rule was hardcoded as
  `id == "snake"` / `Box.snake_entry_cost` in SIX shared-layer sites
  (game_host.launch, roadmap.can_play_now, menu x3, host_node retry x2).
- Fix: snake's registry entry now wears the declarative
  `"entry": {"partial_pay": true}` key; the box reads
  `Box.pays_partial_fee(id)` + `Box.entry_cost(id, fee)`. ANY future game
  can adopt the same thin-wallet rule by wearing the key - no code changes.
- NOTHING REMOVED: `Box.snake_entry_cost(fee)` still exists and returns the
  exact same numbers (it delegates to the generic `entry_cost`), so old
  callers and old tests keep working. registry.gd's header now documents
  the FULL unlock vocabulary in one place (price/reveal/needs_games/
  charge_unlock/entry.partial_pay/hours/daily caps/charges).

## 4. VERIFICATION

- `tools/test.sh gogabox`: ALL 24 SUITES PASS (the snake partial-pay suite
  extended with the shared-policy checks: registry-driven yes/no, full-fee
  vs thin-wallet `entry_cost`, alias consistency).
- `geometry_probe` (headless, per its run line): probe PASS, exit 0 -
  aspect matrix, end-to-end design application, rotation ping-pong, FIT.
- Both fixes are visual-only on device: dots gone from the living bg, long
  toasts self-shrink. No save-format changes (no migration needed).

## 5. SHIP

- version_name 0.1.4 -> 0.1.5, version_code_base 30230 -> 30240
  (arm32 30241, arm64 30242), same signing chain as v0.0.7..v0.1.4
  (overwrite-install safe).
- Build both ABIs, verify APKs, push; CI builds the release candidates.
- Owner test path: v0.1.6 will be tested on top of this - check the dots
  are gone and fire the dry-bank toast (GIVE CHARGES on an empty bank) to
  see the toast fit itself.
