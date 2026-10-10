# Pocket Sweets: initial rules

The first playable level is a 7×7 board with five types. Cells are indexed in
row-major order from zero. Collect 12 each of the first three types within 17 moves (or unlimited
moves in Relaxed mode). Only an orthogonally adjacent swap creating a horizontal or vertical run
of at least three counts as a move. Initial boards have no matches and at least
one legal swap.

All runs clear simultaneously; intersections count once. Each cleared sweet
counts once toward its type's collection goal. Pieces fall vertically, preserving
order. Refill visits empty cells in row-major order using the seeded PRNG.
Cascades repeat without costing moves. Completion is evaluated after resolution.
Level 1 uses ordinary pieces; later levels enable the specials described below.

A dead board is replaced with a fresh playable board for free (collection totals
and move count remain). Generation tries at most 100 boards, then uses a known
playable pattern. Resolution also caps at 100 cascades and replaces the board if
needed; replacement pieces do not count as collected. This bounds work even with
an unfortunate random stream. The UI calls this recovery a reshuffle.

Hints return the first legal swap in row-major search order, not an optimal move.
Undo restores the entire turn including IDs and PRNG state. Restart restores the
seeded opening. Invalid swaps do not change state. UI resolution blocks new swaps;
reduced motion presents the final state immediately. No full-solution guarantee
is claimed. Generation and turn resolution run through top-level isolate helpers.

## Specials and campaign

The campaign has 135 fixed configurations in `packages/match_three/lib/levels.dart`.
Level 1 retains its original seed and targets. Levels 1–15 use normal matches;
levels 16–30 introduce stripes; levels 31 onward also allow rainbow sweets.
New candy varieties arrive every 15 levels from level 46 through level 121. Every
fifth level is a gentler collection goal. These are authored targets, not a claim
of measured difficulty; device playtesting is still required.

Maximal runs of four create a striped sweet oriented along the run (horizontal
clears its row; vertical clears its column). Runs of five or more create a
rainbow when enabled, otherwise a stripe. Connected intersecting runs create one
special: the longest run wins, with row-major start breaking ties. T/L shapes
without a four-piece run create no special; bombs remain deferred.

Placement prefers the swap destination, then its source, then the middle of the
chosen run, then its first eligible ordinary piece. Cascade creation uses the
same rule without swap preferences. Existing specials are never overwritten.
The created piece retains its ID and survives this entire clearing wave, even
if another special's blast crosses it. It earns collection credit only when it
is actually cleared in a later wave.

A stripe activates when included in a match or hit by another special. A rainbow
can be swapped with any neighbor: both swapped pieces clear and the rainbow
clears the neighbor's type. A rainbow hit by another clear instead clears its own
base type. Two swapped rainbows each clear the other's base type; there is no
extra combination bonus. Stripes swapped together need a normal match. A special
hit by a special triggers its ordinary effect, once per wave. No paid activation,
extra move cost, or special-combination mechanic is introduced.

Clearing expansion finishes before collection totals change; each physical piece
counts once. Undo restores special states and random state together. Dead-board
replacement remains a free fresh board, so it may replace unspent specials.

## Move limits

The current campaign has 135 levels. Each has an explicit allowance in
`packages/match_three/lib/move_limits.dart`. Valid swaps cost one move;
invalid swaps, cascades, and automatic reshuffles cost none. The entire last
turn resolves before deciding the outcome: completing the goals wins even with
zero moves remaining. Otherwise further swaps are blocked. Undo restores the
spent move and the full prior state; retry restores the same seeded opening.

The game menu offers Relaxed mode, which restarts the current level without a
limit and carries through Next level. Mode selection lasts for that play session.
Both modes use the existing completion/progress records. Exhaustion never saves
a completion and offers undo, free retry, a Relaxed restart, or return to levels.

To regenerate provisional allowances, run `dart run tool/calibrate_moves.dart`
from `packages/match_three`. It runs 30 deterministic, varied choice sequences
per level: visible goal-prioritizing choices, a preference for larger matches in
half the trials, and 10%, 25%, or 40% random legal choices. It never examines future
refills. Use the 80th-percentile completion count, or the 90th percentile for
the first five levels, three levels around each new mechanic, and every fifth
level; then add 10% breathing room (at least two moves). The checked-in JSON
report records the completion distribution and success count for each allowance.

These are bot-based starting values, not human difficulty measurements or
optimal solutions. The simple bot does not fully value variety blasts, setup
moves, or special combinations. Limits range from 12 to 160; later collection
goals are substantially larger and should be human-playtested for pacing.
Hints still identify a legal move rather than an optimal one. Human first-attempt
success and perceived fairness should guide subsequent per-level adjustments.
