# Local Fields and Complete Discrete Valuation Rings

This repository contains the source code for the article "A Formalization of Complete Discrete Valuation Rings and Local Fields", [submitted to CPP 2024](https://popl24.sigplan.org/home/CPP-2024). 
The code runs over Lean 3.51.1 and mathlib's version [32a7e53528](https://github.com/leanprover-community/mathlib/tree/32a7e535287f9c73f2e4d2aef306a39190f0b504) (Aug. 5, 2023).

Local fields, and fields complete with respect to a discrete valuation, are essential objects in commutative algebra, with applications to number theory and algebraic geometry. We formalize in Lean the basic theory of discretely valued fields. In particular, we prove that the unit ball with respect to a discrete valuation on a field is a discrete valuation ring and, conversely, that the adic valuation on the field of fractions of a discrete valuation ring is discrete. We define finite extensions of valuations and of discrete valuation rings, and prove some global-to-local results. 

Building on this general theory, we formalize the abstract definition and some fundamental properties of local fields. As an application, we show that finite extensions of the field $\mathbb{Q}_p$ of $p$-adic numbers and of the field $\mathbb{F}_p((X))$ of Laurent series over $\mathbb{F}_p$ are local fields. 

## File Authorship
Every file in this repository is new, original work of the anonymous paper authors, with the exception of the files in the [from_mathlib](https://github.com/LCFT-Lean/local_fields/tree/master/src/from_mathlib) folder, which are due to María Inés de Frutos-Fernández, Yaël Dillies and Filippo A. E. Nuccio as indicated in each file header and are used in this project after securing permission from them.


## Installation instructions
The formalization has been developed over Lean 3 and its mathematical library mathlib. For detailed instructions to install Lean, mathlib, and supporting tools, visit the [Lean Community website](https://leanprover-community.github.io/lean3/get_started.html#regular-install).

After installation, run the commands `leanproject get LCFT-Lean/local_fields` to obtain a copy of the project's source files and dependencies and `leanproject get-mathlib-cache` to download a compiled mathlib. To open the project in VS Code, either run `path/to/local_fields` on the command line, or use the "Open Folder" menu option to open the project's root directory. To compile the project locally, use the command `lean --make src`.
