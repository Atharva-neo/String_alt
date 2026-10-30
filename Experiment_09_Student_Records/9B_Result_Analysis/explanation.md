# Explanation - 9B Result analysis (collegeDB)

Collections and the embedding/referencing decision are the same as in 9A (`exams` references `students` and `courses` by id; one document per student-course pair; `contact` embedded in students).

| Task | Technique | Result (PDF data) |
|---|---|---|
| 1 | `find().sort({total:-1})` | 92, 80, 76, 70, 45, 35 |
| 2 | `{total: {$lt: 40}}` | S104 / C1 (35) |
| 3 | `$group` with `$avg/$max/$min` | C1 avg 69 (92/35), C2 avg 60.5 (76/45), C3 70 |
| 4 | `$sum` of `$cond` / appeared x 100 | C1 66.67 %, C2 100 %, C3 100 % |
| 5 | `$sort` desc, `$group` + `$first`, `$lookup` names | C1 Neha (92), C2 Neha (76), C3 Omkar (70) |
| 6 | update with an aggregation pipeline and `$switch` | S101: A, C; S102: O, A; S103: B; S104: F |
| 7 | `$group` by `{course, grade}` | one student per grade/course combination |
| 8 | `$setWindowFields` average per course, `$expr` compare | S101 and S102 in C1 (avg 69), S102 in C2 (avg 60.5) |
| 9 | `$group` by course + `$lookup` courses | Dr. Patil 69, Dr. Kale 60.5, Dr. Joshi 70 |
| 10 | pipeline update: ESE + 6, `total = ise + ese`, regrade | S104 C1: 35 (F) -> 41 (C) |
| 11 | `{ise:{$gte:30}, ese:{$lt:30}}` | empty (no such student) |
| 12 | `deleteMany({total: 0})` | none in the PDF data; a temporary absentee record shows 1 deletion |

**Pass mark:** total >= 40. **Grades:** O >= 90, A >= 75, B >= 60, C >= 40, F < 40. A pipeline update is used instead of a client-side loop because the new value depends on other fields of the same document and the whole change is one atomic operation per document.
