GOGAs - the GOGABox games home
==============================

Where this folder lives:
- Windows: next to GOGABox.exe (the box's zip already ships it there -
  unzip anywhere and both arrive together).
- Android: at Downloads/GOGAs (extract the GOGAs zip into the Downloads
  folder; the box asks for the all-files permission the first time it
  needs it).

What is inside:
- games/<id>/   one folder per game. The folder name is the game's id.
- box.json      the box's own settings file - open it in any text editor.

A game folder carries:
- game.json     the game's name and details (the box reads this)
- game.pck      the game itself - the one file the box launches
- thumb.png     the tile picture shown in the feed
- anything else the game's own business (its saves, its data) - GOGABox
  never touches or checks the rest of the folder.

Adding a game: drop its folder into games/ and start GOGABox. Removing
a game: delete its folder. Sharing a game: share the folder.

box.json - the settings:
------------------------
  {
    "hide_mature": true,
    "dev_cheats": false,
    "starter_game": ""
  }

- hide_mature   "true" (the default) keeps the box family-friendly: games
                rated +12 and up stay out of the feed, and the age-rating
                and content tags stay hidden with them. Set it to "false"
                for the uncensored view - everything shows, nothing is
                filtered. Restart the box (or just go back to it) after
                editing.
- dev_cheats    "false" (the default). The hidden dev-cheats menu stays
                locked for everyone. Set "true" only if you are the
                developer/owner: the five-tap-on-the-logo menu comes back.
- starter_game  optional. The one game a fresh box starts owning. Empty =
                the box picks the alphabetically-first game folder itself.

A missing box.json, or a broken one, just means the defaults - the box
always starts, whatever the file says.
