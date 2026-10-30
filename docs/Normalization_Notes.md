# Normalization notes (Experiment 3)

## Definitions
* **FD** X -> Y: equal X values force equal Y values. **Closure** X+ = all attributes derivable from X using the FDs. **Superkey**: X+ = all attributes. **Candidate key**: minimal superkey. **Prime attribute**: member of some candidate key.
* **1NF** atomic values, no repeating groups, a key. **2NF** 1NF + no partial dependency (non-prime attribute depending on part of a candidate key). **3NF** 2NF + for every non-trivial X -> A: X is a superkey **or** A is prime. **BCNF** for every non-trivial X -> A: X is a superkey. **4NF** BCNF + every non-trivial MVD X ->> Y has X as a superkey.

## Procedure (used in every `00_derivation.md`)
1. List the FDs. 2. Compute closures and the candidate keys (`tools/fd_tools.py`). 3. Mark partial / transitive dependencies. 4. Show the anomalies (insert, update, delete). 5. Decompose: remove partial FDs (2NF), then transitive FDs (3NF), then any FD whose determinant is not a key (BCNF). 6. Check **lossless join** and **dependency preservation**. 7. Create the tables with PK/FK, insert, rebuild the original relation with a JOIN.

## Tests
* **Lossless (binary split R1, R2)**: (R1 ∩ R2) -> R1 or (R1 ∩ R2) -> R2 holds. General case: tableau/chase (`lossless_join()`).
* **Dependency preserving**: every FD of F follows from the union of the FDs projected on the parts (`dependency_preserved()`).
* **FD check on data**: `SELECT X FROM t GROUP BY X HAVING COUNT(DISTINCT Y) > 1` returns nothing if X -> Y holds.
* 3NF synthesis is always lossless **and** dependency preserving; BCNF decomposition is always lossless but can lose an FD (3D: {Student, Subject} -> Teacher).

## Worked results of this repository
| Variation | Candidate key(s) | Result |
|---|---|---|
| 3A | {RollNo, CourseID} | 4 tables Student, Faculty, Course, Enrolment = BCNF, lossless, FD preserving |
| 3B | {OrderID, ProductID} | Customer, Orders, Product, Order_Item = BCNF |
| 3C | {EmpID, ProjectID, Skill} (1NF) | Department, Employee, Project, Works_On, Emp_Skill (MVD EmpID ->> Skill removed = 4NF) |
| 3D | {Student, Subject}, {Student, Teacher} | 3NF not BCNF; Teacher_Subject + Student_Teacher lossless, loses {Student, Subject} -> Teacher |

Anomalies: **insert** (cannot store a fact without an unrelated one), **update** (one fact stored in many rows -> inconsistency), **delete** (deleting one fact removes another).
