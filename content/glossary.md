---
title: Glossary
---

Words the census uses everywhere, in the order you are likely to meet them.

## Polycube {#polycube}

A solid made of unit cubes glued face to face, like a Tetris piece in three dimensions. A polycube with n cells is an n-cube: 1 is the monocube, 4 are tetracubes, 9 are nonacubes. Two polycubes are the same shape if one can be rotated onto the other. A shape and its mirror image count as two shapes unless they happen to be the same.

## Tiling {#tiling}

Filling all of space with copies of one shape, no gaps and no overlaps. Copies may be rotated. A shape that admits one is a tiler. The census allows the 24 rotations of the cube and reports separately whether reflections were needed.

## Periodic tiling {#periodic}

A tiling that repeats on a lattice, like three-dimensional wallpaper. A certificate for a periodic tiling is a lattice and a list of placements inside one repeating block. The census finds these by solving on a torus: space wrapped around so that a block's edges meet.

## Box tiling {#box}

A tiling of a rectangular box. Boxes stack, so a box tiling is a tiling of space, and the smallest box a shape fills is its box order. The box stage runs first because its certificates are the easiest to read.

## Corona {#corona}

One complete layer of copies wrapped around a shape so that every cell touching the shape, at a face, an edge, or a corner, is covered. A second corona wraps the first. The census uses 26-neighbour adjacency for "touching", which is the convention from the two-dimensional literature.

## Heesch number {#heesch-number}

How many complete coronas can be wrapped around a shape before it is impossible to add another. A tiler has infinitely many. A shape with Heesch number 1 can be wrapped once and provably never twice. The census's non-tilers all have Heesch number 1 so far. Shapes known to wrap twice but not yet shown to stop are listed as Heesch number 2 or more.

## Verdicts {#verdicts}

**Tiler**: a certificate exists, a box or a periodic block, rechecked by plain geometry. **Non-tiler**: a corona depth was proven impossible by a SAT solver, and the proof was checked by an independent program. **Open**: the shape survived every test within its stated budgets. Open is not a shrug: the record says exactly how far each search went.

## Stages {#stages}

The order the census tries things: box tiling, then periodic tiling, then coronas. Each record lists which stages it went through and how each ended: `certified` (a tiling found), `exhausted` (searched to the limit, nothing), `witnessed` (a corona of that depth exists), `refuted` (none of that depth exists), or `attempted` (tried, not settled).

## Symmetry order {#symmetry-order}

How many of the 24 rotations of the cube leave the shape looking the same. A straight bar has 8. A shape with no symmetry has 1. The more symmetric a shape, the fewer distinct ways it can be placed.

## Chiral {#chiral}

A shape is chiral if no rotation turns it into its mirror image, like a left and a right screw. Chiral shapes come in pairs, and each page links to its twin. A shape tiles space if and only if its mirror image does, so the census solves one and reflects the certificate for the other.

## Certificate {#certificate}

Data that lets anyone recheck a claim without trusting us. A tiling certificate is a placement list, checked by counting. A refutation certificate is a proof in DRAT format, checked by drat-trim. The [verify](/verify/) page walks through both.

## SAT solver {#sat}

A program that decides whether a large true-or-false formula can be satisfied. The census writes "copies of this shape fill this region" as such a formula and hands it to a solver. A satisfying assignment is a tiling. A proof of unsatisfiability is a refutation.
