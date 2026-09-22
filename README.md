# slopcheck

A test bed for the PR wiring of [sloplint2](https://github.com/danielhuadotcom/sloplint2).
The `src/` tree is clean under both configs, so every finding on a PR comes from that PR.

## How CI is split

Both jobs run the full default rule set. The only difference is which files they are handed.

| Job | Paths |
| --- | --- |
| `slop check (diff scope)` | the PR's added/changed `.py` files |
| `slop check (repo scope)` | `.` |

Most rules are per-file and report identically either way. Two are not: SLP020 (clones) and
SLP090 (directory fanout) analyze the set of files they are given. A diff-scoped run hides them —
a function copied from a file the PR never touched has no partner in the set, and a directory is
never over-full when only part of it is passed. Comparing the two jobs on one PR shows exactly
what diff scoping costs.

Scoping to the diff is worth it only when the tree has findings a PR did not introduce; a repo-scoped
job then fails on every PR until the tree is clean. This repo's tree is clean, so repo scope is the
stricter of the two and nothing is narrowed away.

## PRs worth opening

Each one should fail exactly one job.

1. **Per-file rules — both jobs agree.** Add a comment, a docstring, a `# noqa`, a
   `def test_*`, or an import inside a function to any file in `src/`. Expect SLP010, SLP011,
   SLP012, SLP070, SLP181.
2. **Untouched file stays quiet.** Do the above in one file only and confirm
   the other two are not reported.
3. **Clones — the jobs disagree.** Copy `pricing.subtotal` into a new module under a different
   name. The diff-scoped job passes (it never sees the original); the repo-scoped job reports
   SLP020 at both ends.
4. **Fanout — the jobs disagree.** Add enough modules to put one directory over 15. Only the
   repo-scoped job reports SLP090, on the directory's first module.
5. **Findings on lines the PR did not touch.** Add a comment to `report.py`, then in a second PR
   change one unrelated line in the same file. The second PR still reports the comment: the tool
   has no diff-awareness and no baseline.
6. **No Python changed.** Edit this README alone. The diff-scoped job skips its lint step; the
   repo-scoped job still runs.

## Running it locally

    sloplint check src
    sloplint check .
