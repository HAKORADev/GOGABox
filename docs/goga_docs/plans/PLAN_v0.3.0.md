# PLAN v0.3.0 — the verdict round: XO marks + Fruit Slasher's real face

The owner played v0.2.9 and ruled. "Work harder on it so it gets even
better than the real fruit ninja."

## XO

- [x] The marks were "weird" — they are now PRE-RENDERED brush sketches
  (tools/v030_xomarks.py): smooth ribbon strokes at 4x downscaled, width
  tapering to a point, soft wobble, under-shadows, 3 variants per kind
  chosen deterministically per cell+round.

## Fruit Slasher

- [x] The position ask shows ONLY the two phone cards (the hint text died).
- [x] The +N/-N zone reader died: "+1" floats right at the cut, each fall
  floats its own "-2" where it fell, the bomb floats "-1 HEART".
- [x] THE WOOD BOARD: the classic fruit-ninja wood (from the classic art
  set), composed into portrait + landscape plates (mirrored tiling +
  vignette); the rays/bokeh are gone; only 4 tiny slow sparkles remain.
- [x] THE GLITCH LINE found and killed (the v0.2.9 cut-flash drew the
  whole swipe segment) — replaced by the classic flash.png glint along
  real cuts only.
- [x] THE SLICE FIXED FOR REAL: the v0.2.9 halves were 256x too small
  (a unit-square polygon at scale ~0.5 = sub-pixel — that is why the
  owner saw "a radius effect then fade-out"). The fruit is now replaced
  by its TWO REAL ART HALVES (the classic set ships them pre-cut),
  aligned to the cut line, thrown apart with flips.
- [x] REAL ASSETS: the hunt (Kenney JS-gated, OGA pixel art / CC-BY
  samples, GitHub packs reviewed one by one) landed the classic
  fruit-ninja set (apple/banana/basaha/peach/sandia + halves + boom +
  flash + smoke + the wood board). The painted fruits were retired from
  the spawner (they survive only as the vegetables stand-in).
- [x] REAL JUICE: bigger stretched droplets + splatter decals that stick
  to the wood (7-10 merged blobs + a drip) and fade slowly.
- [x] THE BOMB: the classic bomb art + a REAL explosion (flash burst,
  shockwave ring, 10 smoke puffs, 12 sparks, the shake, a red pulse).
- [x] The SFX re-voiced: the wet cuts are squelches now (soft body slide,
  a snap, juice plips — the dry bursts read like cutting bombs).
- [x] tests: slasher_probe re-lawed (the real halves, the +1/-2
  floaters, the explosion FX), all four suites exit 0; Xvfb qa_v030
  eyeballed (the marks, the wood, the slice, the splat, the explosion).
- [x] Version 0.3.0 (base 30390: arm32 30391, arm64 30392).
