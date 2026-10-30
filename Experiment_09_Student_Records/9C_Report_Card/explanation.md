# Explanation - 9C Report card (collegeDB)

Collections and the embed/reference decision are as in 9A. The report card is a **derived** document built by one aggregation and stored in `report_cards` (a materialised report: fast to read, refreshed by re-running the pipeline).

## The pipeline (`aggregation.js`)

```mermaid
flowchart LR
    S[students] --> L1["$lookup exams"] --> U1["$unwind"] --> L2["$lookup courses"] --> U2["$unwind"] --> L3["$lookup attendance"] --> F["$filter: same course"] --> C["$set: grade, attendance %, grade points"] --> G["$group by student: courses[], sum(credits x points)"] --> R["$set: sgpa, result, remark"] --> O["$out report_cards"]
```

| Task | Result (PDF data) |
|---|---|
| 1 | exams grouped per student with course ids and marks |
| 2-3 | one row per (student, course) with course name, marks, attendance %, grade |
| 4 | SGPA = sum(credits x points) / sum(credits): S101 (4x9 + 4x6)/8 = **7.5**, S102 (4x10 + 4x9)/8 = **9.5**, S103 3x8/3 = **8.0**, S104 4x0/4 = **0** |
| 5 | class topper: **Neha Gaikwad, 9.5** |
| 6 | full report card of S102 (courses array, sgpa, Pass, Eligible) |
| 7 | Fail if any course total < 40: only S104 fails |
| 8 | Detained if any attendance < 75 %: S101 (DAA 71.05) and S104 (DBMS 62.5) |
| 9 | `$out: "report_cards"` writes 4 documents (replaces the collection atomically) |
| 10 | CSV written from mongosh with Node's `fs` (or `mongoexport --type=csv --fields=...`) |
| 11 | phone updated in `students`, the next `$out` run shows the new phone |
| 12 | indexes `{student_id:1, course_id:1}` on exams and attendance: `explain()` COLLSCAN -> IXSCAN on the lookup access path |

Why `$lookup` into attendance by `student_id` and then `$filter` by course: it works on every MongoDB 7 shell and keeps the stage simple; the alternative is `$lookup` with `let` + `pipeline` + `$expr` matching both ids.
