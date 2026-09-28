# PUBLISHING.md — the two-step publish (no tokens, ever)

The flow the owner designed on purpose ("make repo, pull request with
your link in the specific file in the specific folder, wait, done —
that's way more cleaner"):

## Step 1 — make your repo

A github repo (public) that serves the source file:

```
GOGAs/discover/index/source.json
```

and the game packages it lists (each with the full manifest +
the `files` manifest — see PACKAGING.md and DISCOVER.md). Test it
locally first: a folder with `gogabox.repo.json` (`{"repo": "user/repo"}`)
+ the same shape is the virtual-repo simulation — the box runs the FULL
flow with zero network, and the local flow IS the contract.

## Step 2 — one pull request

Edit `GOGAs/discover/REPOS.txt` in HAKORADev/GOGABox and add ONE line:

```
# GOGABox community register - one repo per line
yourname/yourgame
```

v043 pass 3: the register has a CATALOG VIEW —
`GOGAs/discover/index/community.json` (per-source metadata: branch,
note). A publishing PR touches BOTH files; the CI fails when they drift
apart (they are one register in two shapes). The packager's catalog
writer keeps them synced mechanically:

```bash
python3 tools/v043_package.py --catalog   # regenerate from the tree
```

The CI (`goga-registry.yml`) validates the PR: the repo exists, the
source file is there, it parses, the listed game indexes parse, the ids
wear the scheme, the tiers are legal. The review is the machine's; a
human rubber-stamps the run log.

## What a merge gives you

Your repo joins the **community** tier: verified by CI, listed in the
official register, served in the discover feed under COMMUNITY. Nothing
else changes — your repo stays yours, your releases stay yours, we host
nothing. The box fetches YOUR raw URLs directly; between you and the
player there is only github.

Not in the register? You are **hobbyist** by default — add your repo as
a custom source in the box and share it any way you like. The tier is a
trust display, not a permission: hobbyist games play exactly the same.

## The rules of the register

- one repo per line, `user/repo` form, `#` comments
- removal PRs work the same way (the repo's owner can also ask)
- a repo that starts failing CI validation gets flagged in the PR that
  touches it — the register is machine-checked on every change
- the OFFICIAL tier is never granted by the register (it is hardcoded
  engine-side: the owner's repos, today HAKORADev/GOGABox)
