# Awake

- `./build.sh` builds a dev copy (`local.awake.dev`) that runs beside the installed Awake without sharing its settings or login item. `--installable` and `--self-updating` build the real `local.awake`.
- `scripts/measure.sh <dmg>` runs the README's size, memory and CPU method. README numbers quote the published release; the Release workflow opens the PR that updates the sizes.
- Merge with `gh pr merge <n> --squash --admin`: the Protect main ruleset requires a code-owner review, and the owner can't approve their own PR.
- `codesign --verify --strict` rejects the app inside a release DMG (dmgbuild leaves a FinderInfo xattr; `xattr -cr` a copy first). Plain `--verify` still catches tampering.
- This Mac has no Rosetta, so the x86_64 slice can't be launched here.
