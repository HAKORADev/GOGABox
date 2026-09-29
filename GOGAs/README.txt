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

A game folder carries:
- game.json     the game's name and details (the box reads this)
- game.pck      the game itself - the one file the box launches
- thumb.png     the tile picture shown in the feed
- anything else the game's own business (its saves, its data) - GOGABox
  never touches or checks the rest of the folder.

Adding a game: drop its folder into games/ and start GOGABox. Removing
a game: delete its folder. Sharing a game: share the folder.
