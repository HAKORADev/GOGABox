# GOGACOINS.md — the economy doors

GOGACoins are the box's one currency. The wallet is the player's, shared
by every game; your game can pay into it and spend from it through the
`GOGA` autoload. Every door is OPTIONAL — a game that never calls them
just plays for free.

## Reading and writing coins

```gdscript
GOGA.coins_balance()          # -> int, the player's wallet
GOGA.coins_earn(5)            # the player earned 5 coins in your game
GOGA.coins_spend(10)          # -> bool, false when the wallet is dry
```

Coins shown anywhere in your UI must wear the coin icon (the box's
`Arc.coin_button` / the `goga_coins_icon` asset) — a naked number reads
as nothing in particular.

## The in-run economy (the usual road)

Most games don't call GOGA directly during a run. They collect the run's
coins in a local counter and land them at the end:

```gdscript
add_run_coins(coins)          # inside GameBase - counts this run's take
finish_run(score)             # ends the run: banks the coins, records
                              # score/best/plays, opens the game-over sheet
```

The box handles the banking, the stats and the game-over sheet for you.

## Achievements

Declared in `game.json` (`ach`), tracked by the box:

```json
"ach": [
  { "id": "wins_t1", "title": "First Win", "desc": "Win 10 rounds",
    "tier": 1, "rule": { "k": "cnt", "key": "wins", "v": 10 } }
]
```

Your game feeds the counters and the box grants:

```gdscript
bump_counter("wins", 1)       # inside GameBase
Box.grant_achievement("my_game", "wins_t1")
```

## Saves that travel with the folder

The box keeps every game's progress in its own save system, but your
game may keep ITS OWN files inside its folder through the portable save
door — the files live under `GOGAs/games/<your-id>/save/` and move with
the folder when the player copies it:

```gdscript
GOGA.save_json_write("save.json", {"level": 3, "gold": 120})
var s := GOGA.save_json_read("save.json")
```

## Modding, free of charge

`GOGA.data_json("logic/tuning.json")` reads a file from your folder's
`data/` subfolder — if the player (or a modder) edits that file, your
game obeys it; if the file is absent or broken, you fall back to your
packed default. Same idea for art: `GOGA.visual_override("board.png")`
returns a path when the player dropped a replacement into your folder,
or "" when they didn't.
