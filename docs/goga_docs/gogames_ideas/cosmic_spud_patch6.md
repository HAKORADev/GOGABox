# COSMIC SPUD — PATCH 6 (v0.3.5-5, the allies round)

> "selecting the engineer and tap drop-in makes the app crash before wave
> starts and likely because a bug in the allies system because this is the
> only character that has an ally soooo...check that" + "make sure that
> existing allies are differ, like some with the character, some go fight
> around, some have auras? some have cool weapons".

## THE ALLY TRUTH (the crash)
`_t()` — the game's texture loader — never registered the ALLY art keys.
The engineer's drop-in deploy asked for `_t("orbiter")` and the missing
dictionary key killed the script before `_begin_wave(1)` ever ran. Every
ally texture registers now (the art lives beside the enemy sheets it was
recomposed from). The probe boots the engineer end to end: the drone
deploys, the wave begins, nothing crashes.

## THE TARGET NULL LAW (the second crash family)
`_nearest_enemy` returns null when every enemy is beyond the ally's
range — and all four ally branches assigned it straight into typed
`Dictionary` vars. Any live ally on an empty-far board spat script errors
every fire tick. The callers take Variants now.

## THE ALLY VARIETY LAW
- **THE GUARD** — a PROTECTIVE AURA: inside its 130px ring the damage the
  potato takes shrinks (12% at lv1, +4% per level). The BEST ring counts
  once — guards never stack (allies do not die, upgrades exist, and the
  owner warned against "too cool from the start"). The ring breathes so
  the shield reads.
- **THE MEDIC** — the heal pulses a soft green ring every 2s so the care
  is visible.
- **THE SCOUT** — keeps the mark (+15% taken in 300px) and plinks a weak
  pea-dart (3 + 1.5/lv every 1.8s): the spotter fights around now.
- **THE DRONE / TURRET / BOMBER** — keep their jobs (orbit-shoot,
  plant-sweep, kamikaze), each wearing its own tint so the crew reads as
  individuals at a glance.
- Level 1 numbers stay humble everywhere; the levels and the lab do the
  scaling.
