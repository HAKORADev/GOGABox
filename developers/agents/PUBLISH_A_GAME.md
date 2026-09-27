# PLAYBOOK: publish (the two-step)

1. **The repo.** Push the packages to a PUBLIC github repo serving
   `GOGAs/discover/index/source.json` + the listed packages (the files
   manifest makes every file raw-fetchable — keep the repo public and
   the files under 100MB each, raw's ceiling).
2. **Test the remote flow before the PR:** open the box, ADD SOURCE >
   github `you/yourrepo` — the feed must list the game, the download
   must install, the game must play. This is the SAME code path the
   community tier will use.
3. **The PR.** One line into HAKORADev/GOGABox's
   `GOGAs/discover/REPOS.txt`: `you/yourrepo`. CI validates (the repo
   exists, the source file parses, the indexes parse, the ids wear the
   scheme). Merge = the community tier.
4. **Updates.** Bump the package's `version`, push, add the new files
   to the manifest. The box's update census (the feed + the schedule)
   picks it up; players see UPDATE buttons. The old version dies in
   place (the update law replaces).
5. **Degrading.** A repo that stops serving the files drops off the
   feed honestly (the notes say so) — nothing breaks on the player's
   box; installed games keep playing from their installed folders.
