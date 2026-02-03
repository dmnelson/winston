Winston
===============

http://github.com/dmnelson/winston

CHANGELOG
---------

### 0.1.0
* Added MAC (Maintaining Arc Consistency) solver with GAC for AllDifferent.
* Added min-conflicts solver.
* Added heuristics (MRV/LCV) and forward checking support.
* Added DSL for defining CSPs, named domains, and named constraints.
* Added benchmark suite and solver selection via `CSP#solve`.
* Updated gemspec metadata and Ruby version requirement.

### 0.0.2
* Added NotInList constraint.
* Added Sudoku example spec.
* Added 'allow_nil' option for constraints, so not all variables are necessarily required.
* Changed AllDifferent constraint to be restricted to given variables when not global
