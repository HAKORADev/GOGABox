# save/ - the portable save seat

Saves live here, inside the package, never in app-data bloat. Copy the
folder and you copied the player's progress.

- the game reads and writes through the GOGA SDK door
  (GOGA.save_read / save_write / save_json_read / save_json_write),
  paths are relative to this folder
- JSON in, JSON out - human-readable, agent-readable, moddable
- the engine never writes outside this folder; a package that does is
  broken by definition
- delete this file only if you replace it with real save files
