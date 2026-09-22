# slopcheck

Test bed for the PR wiring of [sloplint2](https://github.com/danielhuadotcom/sloplint2). The slop
check lints the whole tree at the PR's merge commit and at its base, and fails on findings the PR
introduces, so cross-file rules (SLP020 clones, SLP090 fanout) apply while existing findings on the
base do not. Both the slop check and the ruff check post their findings as inline review comments
through `.github/scripts/review.sh`.
