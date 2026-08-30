# v0.0.9 PLAN - owner feedback round (2026-08-30)

Owner test-feedback on v0.0.8. Every line below is a commitment for this build.
Checklist mirrors the owner's message 1:1 - nothing may ship half-done.

## 1. SFX identity (dead menu / unlock / achievement)
- [x] Dead menu keeps its melody (`lose`) - it was always meant for the death screen.
- [x] NEW `unlock` SFX: short bright 2-note chime (~0.4s) - plays when a game is bought.
- [x] NEW `achievement` SFX: longer, slower fanfare (~2.2s) - plays on the achievement popup.
- [x] Achiever popup now uses `achievement` only (was star+win = same-as-unlock mush).
- Generator: /scripts/v009_sfx.py (offline, committed wavs under assets/audio/jingles + sfx).

## 2. Top-of-feed carousel (the "big L" redesign)
Owner intent: ONE horizontal strip the finger can scroll left/right, and the
left/right arrows switch WHICH LIST the strip shows (not page single cards).
- [x] Carousel lists: TODAY'S PICKS -> LAST PLAYED -> LEAST PLAYED -> NOT PLAYED YET.
- [x] Cards swipeable left/right by touch (BoxScroll horizontal, tappables kept).
- [x] Arrows = list switchers; dots under the title = which list is active.
- [x] The three v0.0.8 stat strips below are REMOVED (they duplicated the lists
      and caused "last played twice" class bugs forever).
- [x] TODAY'S PICKS draws from OWNED games only (mystery boxes in picks were silly).

## 3. Mystery pre-play "?"
- [x] Back to the v0.0.6 look: the yellow box-font "?" (Arc.ACCENT amber), now
      rendered as art with a LONGER tail stroke (mystery_q.png redrawn).
- Black box tile art (mystery.png) stays untouched - owner rule from v0.0.8.

## 4. Settings gear
- [x] 6 teeth kept, spread wider apart ("go to the sides a little"): top group
      at -90+/-55, bottom group at +90+/-55.

## 5. Rewarded "closed early" rework
- [x] Button text "RETRY IN 10s" with live countdown; grayed AND disabled
      (unclickable) while counting.
- [x] At 0: "RETRY NOW", repainted green, clickable; tap asks a fresh ad.
- [x] Fix "watched a 2nd full ad, got nothing + late closed-early toast":
      - ads.gd stamps show-start at native.show() as a fallback (missed
        ad_shown can no longer zero the watch time);
      - the 8s watchdog no longer fires while a rewarded LOAD is still in
        flight (that hard-resolve was eating the pending callback);
      - every rewarded outcome logs its numbers for logcat diagnosis.

## 6. Score bonus ratio (modular)
- [x] Arc.bonus_ratio_text(score, div) - one helper, reused everywhere.
- [x] Every game HUD shows a small live line: "score bonus S/D = B" (from the
      registry coin_div; snake = /2).
- [x] Dead menu (game-over sheet) shows the v0.0.4-style persistent line above
      the DOUBLE button: "pickups = N - score bonus = S/D = B".

## 7. Feed badges (owner: "you messed the design here too")
- [x] UNLOCKED! (green) ONLY on LOCKED (buyable) tiles, always top-right.
- [x] NEW! (orange) when a teaser first APPEARS (mystery/locked/gated/soon).
- [x] Static SOON ribbon moves top-LEFT (badge owns the top-right corner).
- [x] Roadmap no longer stamps "unlocked" on GATED/SOON transitions; heal
      derives MYSTERY->new, LOCKED->unlocked, GATED/SOON->new.

## 8. Allow reminders (STILL dead taps - fix accurately)
Root-cause hunt: manifest+class+meta-data verified present in the v0.0.8 APK;
UnityAds bridge proves snake_case->camel dispatch works. Remaining dead-end
candidates: OEM suppressing BOTH the dialog and our settings intent, or the
one-shot dialog flag spent with the settings intent silently failing.
- [x] Java: settings intent failure now FALLS BACK to the app-details page
      (no more silent catch).
- [x] GDScript: 2.5s watchdog after request - still not granted -> open the
      notification settings from GDScript too (independent second ladder).
- [x] Every tap gives TOAST feedback (asking system / opening settings /
      already allowed / service missing) - a tap can never look dead again.

## 9. NOT PLAYED YET list
- [x] Owned-but-never-played games ONLY. "Soon" teasers never appear here.

## 10. Search menu
- [x] Hint removed/reworded: filters work on owned + revealed games; mystery
      black boxes always stay visible (genre filters must not leak their content).
- [x] New STATES single-select: ALL / FAVORITES / MYSTERY; none selected = all.
- [x] Picking a state changes the grid headline: "ALL GAMES" -> "FAVORITES" /
      "MYSTERY", and the grid shows only that feed.
- [x] Sheet content scrolls up-down (BoxScroll); each filter group is a
      titled section inside it, so future groups just lengthen the scroll.
- [x] APPLY FILTERS is grayed + disabled while nothing is set, colored the
      moment any filter/state is chosen.

## 11. Favorites
- [x] Box: favorites list persisted (Box.is_favorite / toggle_favorite).
- [x] Pre-play menu: heart button, turns red when favorited, adds/removes the
      game from the FAVORITES feed (via search STATES).

## 12. Resolution / scaling
- Facts: the box renders 720x1280 LOGICAL units with stretch=canvas_items +
  aspect=expand; text/vectors draw at the device's real resolution. What read
  as "small internal resolution" was 1x raster art upscaled on a 1080-wide
  screen (+ the battery chip layout bug below).
- [x] Battery chip in the box menu top bar now measures its real width (it was
      a 0-width Button wrapping an overflowing panel - that is the thing that
      sat on top of the GOGACoin chip and the search icon since v0.0.6).
- [x] Core UI art re-rendered at 2x pixel density (same on-screen size, crisp
      on 1080p+): coin, gear, help, lock, trophy, mystery, mystery_q, heart,
      logo, bg_main, splash, thumbs.
- [x] docs/RESOLUTION_RULE.md updated with the decision: logical layout stays
      720-based; sharpness comes from hi-res art, not from rewriting every
      coordinate to a 1080 base (regression risk >> gain).

## 13. Toasts above everything
- [x] Arc.toast_overlay now hosts the label on a CanvasLayer(layer=100) - the
      toast renders above sheets/popups ("filters applied", "ad closed early"
      were hiding behind panels) while staying bottom-anchored.

## 14. "?" menu descriptions
- [x] The ? (help) list rows show the pre-play description (the game's tag
      line) instead of the long guide desc - the guide keeps "THE GAME" text.

## 15. Repo housekeeping
- [x] projects/candyrush + projects/jellyjump deleted; entries removed from
      config/projects.json (gogabox stays the only project - owner will
      explain the plan for this later).
- [x] This file (docs/PLAN_v0.0.9.md) tracks the round; update statuses here.

## 16. Ship
- [x] config/projects.json -> 0.0.9, version_code_base 30180 (arm64 30182,
      arm32 30181).
- [x] flow_test.gd: picks owned-only, favorites roundtrip, bonus ratio text,
      badge rules, carousel lists.
- [x] All tests green headless -> build both APKs -> push -> CI green ->
      artifacts verified -> backups in the sandbox download/ folder.
