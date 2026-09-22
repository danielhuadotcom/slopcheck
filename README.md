# slopcheck

A test bed for the PR wiring of [sloplint2](https://github.com/danielhuadotcom/sloplint2).
The `src/` tree is clean under both configs, so every finding on a PR comes from that PR.

## How CI is split

| Job | Paths | Config | Rules |
| --- | --- | --- | --- |
| `slop check (changed files)` | the PR's added/changed `.py` files | `sloplint.changed.toml` | everything except SLP020, SLP090 |
| `slop check (whole tree)` | `.` | `sloplint.tree.toml` | only SLP020, SLP090 |

SLP020 (clones) and SLP090 (directory fanout) analyze the set of files they are given. A
changed-files run hides them: a function copied from a file the PR never touched has no partner
in the set, and a directory is never over-full when only part of it is passed. They run over the
whole tree instead, which also means they report findings the PR did not introduce.

Everything else is per-file and reports the same way whichever set it gets.

## PRs worth opening

Each one should fail exactly one job.

1. **Changed-files job, per-file rules.** Add a comment, a docstring, a `# noqa`, a
   `def test_*`, or an import inside a function to any file in `src/`. Expect SLP010, SLP011,
   SLP012, SLP070, SLP181.
2. **Changed-files job, untouched file stays quiet.** Do the above in one file only and confirm
   the other two are not reported.
3. **Whole-tree job, clones.** Copy `pricing.subtotal` into a new module under a different name.
   The changed-files job passes (it never sees the original); the tree job reports SLP020 at both
   ends.
4. **Whole-tree job, fanout.** Add enough modules to put one directory over 15. Only the tree job
   reports SLP090, on the directory's first module.
5. **Findings on lines the PR did not touch.** Add a comment to `report.py`, then in a second PR
   change one unrelated line in the same file. The second PR still reports the comment: the tool
   has no diff-awareness and no baseline.
6. **No Python changed.** Edit this README alone. The changed-files job skips its lint step;
   the tree job still runs.

## Running it locally

    sloplint check --config sloplint.changed.toml src
    sloplint check --config sloplint.tree.toml .
