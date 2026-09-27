# PLAYBOOK: wrap a non-Godot game (the Steam model)

The game is a real .exe (Windows) or .so (Android) that must REQUIRE
the running box. The platform does not crack, download or distribute
games — wrap only what you have the right to wrap.

1. **The starter.** A thin launcher that links the C ABI
   (sdk/native/goga_sdk.h — the reference client compiles clean) or
   speaks the wire directly (SDK.md): goga_connect → the game's own
   boot → the game runs → the coins/saves flow through the doors.
2. **The no-box seat.** `goga_connect` fails when the box is closed —
   the starter shows "launch GOGABox first" and exits. That is the
   Steam model working as designed.
3. **The manifest.** `runs: {"pc": {"kind": "native", "bin": ...}}` —
   the validator checks the binary exists; the box launches it as a
   child process (PC) or loads it in-process (Android).
4. **The contract still holds.** index/, data/ minimums (a moddable
   config beats a dead one — expose the game's own config format in
   data/logic/), save/ (point the game's own saves at the package's
   save/ folder — the portable-save law), discover/.
5. **Renderer freedom.** The native kind runs the game's OWN renderer —
   the box's gl_compatibility does not apply. Record it in
   runs.<plat>.renderer.
