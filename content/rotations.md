---
title: The 24 rotations
---

Every tiling certificate on this site is a list of placements, and each placement is an offset and a rotation number from 0 to 23. The number indexes the table below, which is every rotation of a cube that keeps it a cube, without reflections, in the order the census code generates them.

Read a row as a recipe for new coordinates. Rotation 13 says new x = y, new y = -z, new z = -x, so the cell (0, 0, 1) lands at (0, -1, 0). After rotating, the copy is slid so its lowest corner sits at the origin, and only then is the offset added. The last column says the same turn as an axis and an angle, right-handed about the axis: one identity, nine turns about a face axis, six half turns about an edge, and eight third turns about a corner.

The census prints this table from its code with `script/rotations`, and [its README](https://github.com/polycubing/census#rotations) carries the same copy.
