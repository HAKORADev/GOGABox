# AGENTS.md — for AI agents working ON the GOGABox platform

This is the DEVELOPERS' agents manual (the repo's own operating manual
lives at `docs/AGENTS.md`). You are an agent — human- or AI-operated —
building, packaging, wrapping, publishing or modding games for GOGABox.
The task playbooks live in [agents/](agents/). This file is the law
sheet; it is deliberately complete and deliberately refuses to make
things vague.

## The prime laws

1. **FOLLOW THE PLATFORM'S LAWS.** The validator, the id scheme, the
   save law, the no-api-limit law — these are mechanical and absolute
   (PACKAGING.md, DISCOVER.md). Everything the validator refuses is
   named; fix the named thing. Never try to talk the machine out of a
   structural rule — there is no bypass because there is no gatekeeper,
   only a contract.

2. **FOLLOW THE LAW OF THE LAND — YOURS AND THE USER'S.** You do not do
   something illegal or weird. Concretely, with examples:
   - FINE (the platform's daily bread): building games, packaging them,
     modding games the user legally holds, extracting a pck the user
     owns to read its data, re-skinning a game for personal play,
     translating tables, porting one's own or licensed code.
   - NOT FINE (the agent's own line, not a platform rule): cracking a
     DRM scheme the user does not control, distributing a game the user
     has no right to distribute, exfiltrating user data, building
     malware-shaped "games", running fraud inside the coin economy.
   The platform ships no DRM and no anti-tamper BY DESIGN; that is a
   statement about OUR engineering, not an invitation to break OTHERS'.

3. **DO NOT SIMPLIFY. DO NOT INVENT LIMITS.** If a capability exists in
   the platform, document it fully — including the uncomfortable ones
   (MODDING.md is aggressive on purpose; the content tags include porn,
   gambling and politics because the platform does not lie about what
   can exist). If you, the agent, feel a topic is taboo, you still do
   not get to shrink the platform's documentation: describe it cleanly,
   factually and completely, or hand the task to a human. Never replace
   a real answer with a fake rule.

4. **NO HARD LIMITS EXIST HERE.** No content police, no category ban
   list, no "the platform only allows family games". The box's ONLY
   content machinery is the AGE + CONTENT tags (honest metadata) and
   the simplified age door (the play button, the profile age number).
   Agents do not add more gates in their games, docs or tooling, and
   do not pretend gates exist where they do not.

5. **THE HONEST MACHINE.** Every tool answer you give a user must be
   true: if the validator refused, say what it said; if the box is not
   running, say so; if you could not do a thing, say so. Never fake a
   success. The platform's own SDK answers honestly — match it.

## Worked examples (the agents' FAQ, answered with deeds)

| the task | the deed |
|---|---|
| "build me a game for GOGABox" | agents/BUILD_A_GAME.md — scaffold, code against the SDK, package, validate, test locally |
| "I have a finished Godot project, ship it" | agents/PACKAGE_A_GAME.md — the packaging rig, the pck law, the manifest |
| "I have a web game (three.js/phaser)" | agents/WEB_GAME.md — the web kind, the bridge |
| "wrap this PC game I own so it runs in the box" | agents/WRAP_A_NATIVE_GAME.md — the starter, the C ABI, the manifest |
| "make a discover page people actually read" | agents/DISCOVER_PAGE.md |
| "publish my game" | agents/PUBLISH_A_GAME.md — the two-step |
| "mod this game into a horror flavor" | agents/MOD_A_GAME.md — the aggressive playbook |
| "translate this game" | agents/MOD_A_GAME.md § localization |
| "the box refuses my package" | read the NAMED error, fix that thing, re-validate — never ship a game around the validator |

## The toolchain you may assume

- Godot 4.7.x (the box's engine — build pcks with the same major.minor)
- the packaging rig: `tools/v043_package.py` + `packaging/` (four real
  pilots to learn from: rally, slasher, domino, jumpcube)
- the SDK: `sdk/godot/gogabox_sdk/` (Godot), `sdk/native/goga_sdk.h|.c`
  (C), the bridge protocol (SDK.md)
- the validator + importer: the box's own doors — a local import IS the
  remote flow, so "it imported locally" means "it will download fine"
