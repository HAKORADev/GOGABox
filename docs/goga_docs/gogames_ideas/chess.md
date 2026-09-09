# CHECKMATE (chess) — the owner's GDD, v0.3.8 (from the owner's message)

> The old war. The SOON teaser "CHECKMATE / the old war" graduates.
> Base study: chess.com 4.10.13 (APKPure XAPK, decompiled through
> `tools/study/`) — what the study gave us is the PERSONALITY SHAPE
> (every named play style = an opening book + style knobs + a mistake
> model; the bins were Polyglot opening books, one per personality) and
> the sound ANATOMY (move = a soft woody tock, capture = a deeper knock,
> check = a bright alert). All art and audio in the box are our own.

## 1. THE SHAPE

- **Horizontal only** (landscape). Full legal chess vs the CPU.
- **TAP ANYWHERE TO START.** You take WHITE first; the loser of a round
  takes WHITE next; a draw swaps the colors.
- Scoring (the owner's law): **win +1 / lose −1 (the score never goes
  negative) / draw 0**. Run bonus **/1** (registry coin_div 1).
- Fee 10, price **700**, direct reveal, appear_after 8, needs_games 9.
- Themes (boards) + skins (piece sets) live DIRECTLY in the shop —
  everything past the defaults is BOUGHT.

## 2. THE RULES (the owner trusts the implementation — perft-certified)

Every piece moves by the book, and ALL of it is live:

- castling (every real condition: untouched king/rook, empty lane, no
  castle through, out of, or into check),
- **en passant**, **promotion** (a picker, underpromotion included),
- check (the king glows red), **checkmate**, **stalemate**,
- the **50-move rule**, **threefold repetition**, **insufficient
  material** (bare kings and friends).

THE PROOF: the engine is STATIC (`start_state/legal_moves/make_move/
status/eval/cpu_move`) and the probe pins the canonical perft counts —
**perft(1)=20, perft(2)=400, perft(3)=8902** — the move generator is
mathematically identical to the reference numbers of the game itself.

## 3. THE INPUT

Tap a piece: it rings, its legal targets **dot the board**, capture
squares ring. Tap a target to play — or **drag** the piece. The last move
stays tinted. Everything answers the same frame.

## 4. THE COIN LAW

One GOGACoin after each **3 minutes** of play, on a square YOUR pieces can
legally reach — whoever lands a piece on it takes it; the CPU races you.

## 5. THE CPU — six personalities (the chess.com study, made ours)

SIX hidden profiles rotate invisibly (one name: CPU), each with its OWN
OPENING BOOK and its own honest mistakes — the xo law: "good but has real
programmed failures to give the user a way to win":

| profile | book lines | depth/qcap | miss | noise | aggr/safety |
|---------|-----------|------------|------|-------|-------------|
| STARTER | the classical gates | 2/2 | 10% | 40 | 0.5/1.0 |
| AGGRESSOR | the gambit lunges | 2/3 | 12% | 55 | 0.9/0.5 |
| **JOBAVA** | **the Jobava London** (the owner's named example — d4 Nc3 Bf4 systems) | 2/2 | 11% | 48 | 0.8/0.7 |
| TRICKSTER | the trap lines | 2/2 | 14% | 62 | 0.7/0.6 |
| ROYAL | the classical mainlines | 2/4 | 8% | 30 | 0.4/1.2 |
| FLANKER | the wing attacks | 2/4 | 9% | 34 | 0.3/1.1 |

The engine behind the personality: alpha-beta search at depth 2 + a
quiescence capture sweep (phone-safe budget), PST-guided eval, aggression
and safety weights per profile. **THE 2-ROUND ADAPTIVE MEMORY** (the xo
law): repeat an opening and the burned reply varies; play hyper-aggressive
and the safe moods tighten up. Every game feels different — the owner's
"many profiles chosen randomly so the game feels different everytime".

## 6. THE SHOP (all bought past the defaults)

- **Piece sets (skins)**: CLASSIC (free, cream vs charcoal) · MINIMAL 180
  · BOLD 260 · ROYAL 340.
- **Boards (themes)**: WALNUT (free classic wood) · FOREST 220 · MARBLE
  280 · NEON 320.

## 7. ACHIEVEMENTS (10, tiered)

First Blood / War Chest / Grand Table / The Old War's Master (score 3/10/
25/50 in a run), Mated / The Quiet Executioner (10/50 round wins),
Collector / The Battlefield Sweep (100/500 captures), plus play-count
trophies.

## 8. SFX + VFX (all synthesized, the box law)

c_select (the ring) · c_move (the woody tock) · c_capture (the deeper
knock) · c_castle (the double tock) · c_check (the bright alert) ·
c_mate (the fall) · c_promote (the rise) · c_illegal (the thud) · c_coin
· c_draw · c_win · c_lose. Slides ease, captures poof, checks pulse red,
mate rains the board.

## 9. THE PROBE (tests/chess_probe.gd — ALL PASS)

Perft 20/400/8902 pinned · castling conditions · en passant (the ghost
expiry) · promotion + underpromotion · checkmate detection (the scholar's
mate) · stalemate · the 50-move rule · threefold (the full 10-ply dance)
· bare kings · the books open honestly per profile · the memory law ·
the coin at the 3rd minute + the race · the score floor.
