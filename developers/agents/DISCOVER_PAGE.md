# PLAYBOOK: the discover page people read

The page material lives in the package's discover/ folder:

- `page.json`: {"title", "desc", "media": [{"kind": "thumb",
  "file": "media/thumb.png"}], "entry": {"fee", "price"}}
- `media/thumb.png` — the index points at it; the feed + the page + the
  loader all wear it.

The laws:
- THE THUMBNAIL IS THE SHELF: 3:2, real art (the box's thumbs are
  composed from the games' own sprites — see docs/THUMBNAILS.md for the
  house craft), no text walls, no placeholder gradients.
- THE DESC IS THE PITCH: the index's "desc" is one honest paragraph —
  what the game IS, what the coins DO, what the LAN seat offers. No
  keyword stuffing (the search normalizes case, not taste).
- THE MEDIA IS THE GAME: real screenshots (the media array), the real
  palette. The GIF loop law the box uses (the focused face loops
  forever, the unfocused face wears the first frame) applies to page
  media the same way.
- THE TAGS ARE HONEST: age + content tags describe what ships. The box
  does not police them; the players' trust and the tier system do.
