# TOP-UP SYSTEM — GOGACoins into game currencies (owner spec, v040-7 round)

> The owner's own spec, verbatim-shaped into laws. DOCUMENT ONLY — nothing
> here is built yet ("i will not do it now ofc"). When the owner
> green-lights it, it becomes a `plans/PLAN_vX.Y.Z.md` task list and this
> file is the contract. Sits next to `LAN_MULTIPLAYER.md` — both are
> box-level economy systems that games opt into.

## THE IDEA (the owner's words)

"this thing will exist for players to play other games to collect
gogacoins so they could transfer gogacoins into other games as coins
which i feel is good idea". GOGABox is one economy wearing many games:
games with their own in-game currencies (Heavy War's scrap, Rock
Breaker's rockCoins, the shelf's future wallets) can be FED from the
GOGACoins a player earns anywhere else in the box. Play wide, spend
deep.

## THE OWNER'S LAWS (binding, from the v040-7 message)

- **THE WALLET TAP LAW**: "tapping gogacoins in the GOGABox main menu
  will open a menu". The main menu's GOGACoin wallet (the top-bar coin
  chip) becomes tappable and opens the top-up menu. The wallet stops
  being a passive label.
- **THE BALANCE LAW**: the opened menu shows "balance = nn" beside the
  gogacoin icon — the player's current total GOGACoins, drawn with the
  box's own coin icon.
- **THE TOP-UP BUTTON LAW**: "under it will show button called top-up".
  One button, one action, under the balance.
- **THE GAME PICKER LAW**: "when tapped will show menu of games that
  contain game-currencies and then a game can be tapped". The picker
  lists ONLY games that carry an in-game currency (the registry declares
  them). A game with no currency is not in the list. Tap a game to enter
  its top-up screen.
- **THE TWO WALLETS LAW**: "then it will show current game coins then
  showing the gogacoins" — the game's top-up screen shows BOTH wallets:
  the tapped game's currency balance first, then the GOGACoins balance.
  The player always sees both sides of the exchange.
- **THE RATE LAW**: "the widget will show that each gogacoin is worth
  nn/0.nnn of a one in-game currency". Every game carries its own
  exchange rate — one GOGACoin is worth N of that game's currency, where
  N may be a whole number (nn) or a fraction with three decimals
  (0.nnn). The rate is declared per game in the registry and printed
  plain in the widget.
- **THE AMOUNT LAW**: "player will write number in the widget where it
  has to be always maximized to the current total GOGACoins and next to
  the number it will show = nn_of_game_currencies". The amount field:
  the player types how many GOGACoins to convert, and the field never
  accepts more than the current total (hard cap at the wallet, always).
  Beside the typed number, live: "= nn" — what the amount becomes in the
  game's currency at the game's rate.
- **THE CONFIRM LAW**: "there will be a button to tap under it called
  top-up then it will show confirmation to the process". The top-up
  button opens a confirmation step before anything moves — no accidental
  conversions.
- **THE SETTLE LAW**: "when done, it will consume gogacoins and increase
  that game coins to the amount bought". Exactly two writes: GOGACoins
  down by the amount, the game's currency up by the converted amount.
  No fees, no rounding games beyond the rate's own three decimals (the
  conversion floors at whole game-currency units).

## THE FLOW (end to end)

1. Main menu → tap the GOGACoin wallet chip.
2. The top-up menu opens: balance = nn (gogacoin icon) · TOP-UP button.
3. TOP-UP → the game picker: every currency-carrying game, one row each.
4. Tap a game → its top-up screen: the game's coins on top, the
   GOGACoins under, then the amount widget with the rate line
   ("each GOGACoin = nn/0.nnn <game currency>").
5. Type the amount (capped at the GOGACoins total) — the "= nn of game
   currencies" preview updates as you type.
6. TOP-UP → confirmation → done: GOGACoins consumed, game coins grown.

## THE DECLARATION (what a game adds to join)

The registry entry grows two fields (names final at build time):

- `currency`: the game's currency id + display name + icon (the widget
  draws the game's own coin, not the GOGACoin).
- `topup_rate`: the exchange rate — GOGACoins → one unit of the game's
  currency (nn or 0.nnn).

The first carriers when this ships: Heavy War (scrap) and Rock Breaker
(rockCoins) — the shelf's wallets, declared. Any future game with an
in-game currency joins by declaring the pair.

## THE OPEN TECH NOTES (for the plan that builds this)

- The game wallets already live in the box save (the per-game shop
  shelves and counters); a top-up writes the same store the game reads —
  no new persistence, one new helper on the Box API.
- The picker reads the registry (currency declared = in the list); no
  per-game code anywhere.
- The amount field: numeric keyboard, clamp-at-input to the wallet total,
  the "= nn" preview computed on every change with the same floor the
  settle uses.
- The confirmation sheet is the box's standard sheet (title, the two
  wallets, the amount and the result line, confirm/cancel).
- The main menu's wallet chip grows a tap-through (it currently only
  displays) — the menu's top bar law stays: the chip keeps its place and
  size.
