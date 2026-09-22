# slopcheck

Test bed for the PR wiring of [sloplint2](https://github.com/danielhuadotcom/sloplint2). Both CI
jobs run the full default rule set and differ only in scope — one gets the PR's changed Python
files, the other the whole repo — so the cross-file rules (SLP020 clones, SLP090 fanout) can only
fire in the second.
