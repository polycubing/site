---
title: Don't trust us, check us
---

Every claim on this site rests on a certificate in the public record. Here is how to recheck them yourself.

## Tilings, in plain geometry

Clone [the census](https://github.com/polycubing/census) and run its verifier. It reads every record, rebuilds every placement from the shape's cells, and confirms the copies cover their box or their repeating block exactly once. No solver is involved.

```sh
git clone https://github.com/polycubing/census
cd census
script/setup
script/verify
```

A checker written from scratch needs one convention from us: placements name rotations by number, and [the 24 rotations](/rotations/) page spells out what each number does.

It also pins the shape counts of every size to the Online Encyclopedia of Integer Sequences ([A000162](https://oeis.org/A000162) and [A038119](https://oeis.org/A038119)) and checks that every record's stored facts agree with each other.

## Refutations, with an independent checker

A non-tiler's record names a DRAT proof by its SHA-256 digest. The formula and the proof are published, compressed, in a public bucket, and listed with their checksums in [`data/artifacts.json`](https://github.com/polycubing/census/blob/main/data/artifacts.json). To recheck one:

1. Download the formula and the proof from the URLs in the manifest.
2. `xz -d` both, and confirm each file's `sha256` matches the manifest.
3. Run `drat-trim formula.cnf proof.drat` and look for `s VERIFIED`.

drat-trim is Marijn Heule's checker, built from [its source](https://github.com/marijnheule/drat-trim). It knows nothing about polycubes. It only confirms that the proof refutes the formula it was given.

## The formula itself

What drat-trim does not check is that the formula means what we say it means. That reading, "this formula is satisfiable exactly when a corona of this depth exists", is the one thing left to trust, and the code that writes the formula is in the open for anyone to read.
