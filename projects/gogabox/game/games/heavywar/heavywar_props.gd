class_name HWProps
extends RefCounted
## THE PLACE PROPS - extracted verbatim from the original's Anims.xml (the
## owner's as-is law, v040-2): plane 4 = sky, 3 = far background, 2 =
## background, 1 = ground; offset/y are the original 640x480 coords (the
## game scales them by SC = 2.25); mx is the per-frame drift at the
## original's 100fps clock (x100 = px/s at 1x, xSC on our screen); rare
## props appear once every third prop set; nuke marks the wreck-frame props.
## The z law lives in the game: plane 4 -> -35, 3 -> -25, 2 -> -15, 1 -> -5
## (between their own plane strips, the original's stacking).

const PROPS := [
        {"p": "frostkrai", "tex": "res://assets/games/hwsrc/anims/frigistan/Yetti.png", "frames": 6, "speed": 0.1, "plane": 1, "offset": 640.0, "y": 356.0, "mx": 0.0, "type": "looping", "nuke": false, "rare": true},
        {"p": "frostkrai", "tex": "res://assets/games/hwsrc/anims/frigistan/Penguin.png", "frames": 6, "speed": 0.2, "plane": 1, "offset": 640.0, "y": 405.0, "mx": -1.0, "type": "looping", "nuke": false, "rare": true},
        {"p": "frostkrai", "tex": "res://assets/games/hwsrc/anims/frigistan/Igloo.png", "frames": 1, "speed": 0.0, "plane": 2, "offset": 341.0, "y": 348.0, "mx": 0.0, "type": "looping", "nuke": false, "rare": false},
        {"p": "frostkrai", "tex": "res://assets/games/hwsrc/anims/frigistan/eskimo.png", "frames": 9, "speed": 0.02, "plane": 2, "offset": 634.0, "y": 354.0, "mx": 0.0, "type": "looping", "nuke": false, "rare": false},
        {"p": "frostkrai", "tex": "res://assets/games/hwsrc/anims/frigistan/snocommie.png", "frames": 2, "speed": 0.0, "plane": 1, "offset": 700.0, "y": 377.0, "mx": 0.0, "type": "looping", "nuke": true, "rare": true},
        {"p": "gulfgate", "tex": "res://assets/games/hwsrc/anims/blastnya/Scope.png", "frames": 1, "speed": 0.0, "plane": 2, "offset": 640.0, "y": 376.0, "mx": -0.5, "type": "looping", "nuke": false, "rare": false},
        {"p": "gulfgate", "tex": "res://assets/games/hwsrc/anims/blastnya/Nessi.png", "frames": 1, "speed": 0.0, "plane": 3, "offset": 640.0, "y": 328.0, "mx": 0.1, "type": "looping", "nuke": false, "rare": false},
        {"p": "gulfgate", "tex": "res://assets/games/hwsrc/anims/blastnya/MurryandMaud.png", "frames": 2, "speed": 0.0, "plane": 1, "offset": 640.0, "y": 402.0, "mx": 0.0, "type": "looping", "nuke": true, "rare": true},
        {"p": "gulfgate", "tex": "res://assets/games/hwsrc/anims/blastnya/lighthouse.png", "frames": 2, "speed": 0.0, "plane": 2, "offset": 350.0, "y": 170.0, "mx": 0.0, "type": "looping", "nuke": true, "rare": true},
        {"p": "gulfgate", "tex": "res://assets/games/hwsrc/anims/blastnya/radiotowers.png", "frames": 2, "speed": 0.0, "plane": 3, "offset": 170.0, "y": 235.0, "mx": 0.0, "type": "looping", "nuke": true, "rare": false},
        {"p": "gulfgate", "tex": "res://assets/games/hwsrc/anims/blastnya/radiotowers.png", "frames": 2, "speed": 0.0, "plane": 3, "offset": 340.0, "y": 220.0, "mx": 0.0, "type": "looping", "nuke": true, "rare": false},
        {"p": "oilreach", "tex": "res://assets/games/hwsrc/anims/petrovakia/Petro-Rig.png", "frames": 1, "speed": 0.0, "plane": 2, "offset": 524.0, "y": 288.0, "mx": 0.0, "type": "looping", "nuke": false, "rare": false},
        {"p": "oilreach", "tex": "res://assets/games/hwsrc/anims/petrovakia/COW.png", "frames": 5, "speed": 0.08, "plane": 2, "offset": 733.0, "y": 401.0, "mx": 0.0, "type": "pingpong", "nuke": false, "rare": false},
        {"p": "oilreach", "tex": "res://assets/games/hwsrc/anims/petrovakia/COW.png", "frames": 5, "speed": 0.08, "plane": 2, "offset": 103.0, "y": 401.0, "mx": 0.0, "type": "pingpong", "nuke": false, "rare": false},
        {"p": "oilreach", "tex": "res://assets/games/hwsrc/anims/petrovakia/GasPill.png", "frames": 2, "speed": 0.0, "plane": 1, "offset": 640.0, "y": 382.0, "mx": 0.0, "type": "looping", "nuke": true, "rare": false},
        {"p": "oilreach", "tex": "res://assets/games/hwsrc/anims/petrovakia/oilcans.png", "frames": 2, "speed": 0.0, "plane": 1, "offset": 640.0, "y": 385.0, "mx": 0.0, "type": "looping", "nuke": true, "rare": false},
        {"p": "nukeflats", "tex": "res://assets/games/hwsrc/anims/dictastroika/Cooler-crack.png", "frames": 1, "speed": 0.0, "plane": 3, "offset": 385.0, "y": 178.0, "mx": 0.0, "type": "looping", "nuke": false, "rare": false},
        {"p": "nukeflats", "tex": "res://assets/games/hwsrc/anims/dictastroika/WasteSpill.png", "frames": 1, "speed": 0.0, "plane": 3, "offset": 485.0, "y": 313.0, "mx": 0.0, "type": "looping", "nuke": false, "rare": false},
        {"p": "nukeflats", "tex": "res://assets/games/hwsrc/anims/dictastroika/surrender.png", "frames": 1, "speed": 0.0, "plane": 3, "offset": 70.0, "y": 150.0, "mx": 0.0, "type": "looping", "nuke": false, "rare": false},
        {"p": "nukeflats", "tex": "res://assets/games/hwsrc/anims/dictastroika/surrender.png", "frames": 1, "speed": 0.0, "plane": 3, "offset": 370.0, "y": 150.0, "mx": 0.0, "type": "looping", "nuke": false, "rare": false},
        {"p": "nukeflats", "tex": "res://assets/games/hwsrc/anims/dictastroika/Barrelofnuke.png", "frames": 1, "speed": 0.0, "plane": 1, "offset": 640.0, "y": 390.0, "mx": 0.0, "type": "looping", "nuke": false, "rare": false},
        {"p": "nukeflats", "tex": "res://assets/games/hwsrc/anims/dictastroika/Spiltnuke.png", "frames": 1, "speed": 0.0, "plane": 1, "offset": 640.0, "y": 397.0, "mx": 0.0, "type": "looping", "nuke": false, "rare": false},
        {"p": "vinebelt", "tex": "res://assets/games/hwsrc/anims/zamblamia/brontasaur.png", "frames": 2, "speed": 0.0, "plane": 3, "offset": 480.0, "y": 217.0, "mx": -0.2, "type": "looping", "nuke": true, "rare": true},
        {"p": "vinebelt", "tex": "res://assets/games/hwsrc/anims/zamblamia/zambian.png", "frames": 2, "speed": 0.0, "plane": 1, "offset": 640.0, "y": 395.0, "mx": 0.0, "type": "looping", "nuke": true, "rare": true},
        {"p": "vinebelt", "tex": "res://assets/games/hwsrc/anims/zamblamia/pterodactyl.png", "frames": 2, "speed": 0.0, "plane": 1, "offset": 640.0, "y": 70.0, "mx": 0.0, "type": "looping", "nuke": true, "rare": true},
        {"p": "gloomkeep", "tex": "res://assets/games/hwsrc/anims/tankylvania/vania_light.png", "frames": 1, "speed": 0.0, "plane": 2, "offset": 269.0, "y": 292.0, "mx": 0.0, "type": "looping", "nuke": false, "rare": false},
        {"p": "gloomkeep", "tex": "res://assets/games/hwsrc/anims/tankylvania/Hangtree.png", "frames": 1, "speed": 0.0, "plane": 3, "offset": 510.0, "y": 175.0, "mx": 0.0, "type": "looping", "nuke": false, "rare": false},
        {"p": "gloomkeep", "tex": "res://assets/games/hwsrc/anims/tankylvania/vania_ghost.png", "frames": 1, "speed": 0.0, "plane": 1, "offset": 400.0, "y": 240.0, "mx": 0.0, "type": "looping", "nuke": false, "rare": true},
        {"p": "gloomkeep", "tex": "res://assets/games/hwsrc/anims/tankylvania/vania_ghost.png", "frames": 1, "speed": 0.0, "plane": 1, "offset": 750.0, "y": 200.0, "mx": 0.0, "type": "looping", "nuke": false, "rare": true},
        {"p": "gloomkeep", "tex": "res://assets/games/hwsrc/anims/tankylvania/vania_pumpkin1.png", "frames": 2, "speed": 0.0, "plane": 2, "offset": 410.0, "y": 365.0, "mx": 0.0, "type": "looping", "nuke": true, "rare": false},
        {"p": "gloomkeep", "tex": "res://assets/games/hwsrc/anims/tankylvania/vania_pumpkin2.png", "frames": 2, "speed": 0.0, "plane": 2, "offset": 635.0, "y": 365.0, "mx": 0.0, "type": "looping", "nuke": true, "rare": false},
        {"p": "ashfall", "tex": "res://assets/games/hwsrc/anims/vodkavania/Fence.png", "frames": 1, "speed": 0.0, "plane": 2, "offset": 100.0, "y": 360.0, "mx": -0.5, "type": "looping", "nuke": false, "rare": false},
        {"p": "ashfall", "tex": "res://assets/games/hwsrc/anims/vodkavania/Fence.png", "frames": 1, "speed": 0.0, "plane": 2, "offset": 400.0, "y": 360.0, "mx": -0.5, "type": "looping", "nuke": false, "rare": false},
        {"p": "ashfall", "tex": "res://assets/games/hwsrc/anims/vodkavania/silo.png", "frames": 1, "speed": 0.0, "plane": 2, "offset": 50.0, "y": 240.0, "mx": 0.0, "type": "looping", "nuke": false, "rare": false},
        {"p": "ashfall", "tex": "res://assets/games/hwsrc/anims/vodkavania/Brokenwindmill.png", "frames": 1, "speed": 0.0, "plane": 2, "offset": 460.0, "y": 190.0, "mx": 0.0, "type": "looping", "nuke": false, "rare": false},
        {"p": "ashfall", "tex": "res://assets/games/hwsrc/anims/vodkavania/Grainelevator.png", "frames": 1, "speed": 0.0, "plane": 3, "offset": 420.0, "y": 200.0, "mx": 0.0, "type": "looping", "nuke": false, "rare": false},
        {"p": "dunefort", "tex": "res://assets/games/hwsrc/anims/antagonistan/oasis.png", "frames": 2, "speed": 0.0, "plane": 2, "offset": 220.0, "y": 300.0, "mx": 0.0, "type": "looping", "nuke": true, "rare": false},
        {"p": "dunefort", "tex": "res://assets/games/hwsrc/anims/antagonistan/bedouin-tents.png", "frames": 1, "speed": 0.0, "plane": 2, "offset": 715.0, "y": 345.0, "mx": 0.0, "type": "looping", "nuke": false, "rare": false},
        {"p": "dunefort", "tex": "res://assets/games/hwsrc/anims/antagonistan/Pyramid.png", "frames": 1, "speed": 0.0, "plane": 3, "offset": 413.0, "y": 187.0, "mx": 0.0, "type": "looping", "nuke": false, "rare": false},
        {"p": "dunefort", "tex": "res://assets/games/hwsrc/anims/antagonistan/Pyramid.png", "frames": 1, "speed": 0.0, "plane": 3, "offset": 862.0, "y": 184.0, "mx": 0.0, "type": "looping", "nuke": false, "rare": false},
        {"p": "steelcrown", "tex": "res://assets/games/hwsrc/anims/killingrad/Statue2.png", "frames": 2, "speed": 0.0, "plane": 2, "offset": 0.0, "y": 190.0, "mx": -0.3, "type": "looping", "nuke": true, "rare": false},
        {"p": "steelcrown", "tex": "res://assets/games/hwsrc/anims/killingrad/Statue1.png", "frames": 2, "speed": 0.0, "plane": 2, "offset": 400.0, "y": 195.0, "mx": -0.3, "type": "looping", "nuke": true, "rare": false},
        {"p": "steelcrown", "tex": "res://assets/games/hwsrc/anims/killingrad/PeaceBalloon.png", "frames": 1, "speed": 0.0, "plane": 1, "offset": 640.0, "y": 40.0, "mx": 0.5, "type": "looping", "nuke": false, "rare": true},
]
