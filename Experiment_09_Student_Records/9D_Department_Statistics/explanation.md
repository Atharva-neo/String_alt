# Explanation - 9D Department and semester statistics (collegeDB)

Same collections as 9A (students embed `contact`; attendance and exams reference students and courses).

| Task | Technique | Result (PDF data) |
|---|---|---|
| 1 | `$group` by dept | AIML 3, CSE 1 |
| 2 | `$group` by `{dept, semester}` | AIML/3: 3, CSE/5: 1 |
| 3 | `$group` by `{dept, gender}` | AIML F 2, AIML M 1, CSE M 1 |
| 4 | `$match total<40`, `$group` count, `$match > 1` | none (S104 failed one course only) |
| 5 | `$lookup` exams, keep `$size: 0` | none; a temporary student S900 proves the query |
| 6 | `$group` by `contact.city` | Sangli 2, Kolhapur 1, Miraj 1 |
| 7 | `dob > 2006-01-01` | S102, S101, S104 |
| 8 | `$inc: {semester: 1}` | AIML students move to semester 4 (S103 unchanged) |
| 9 | insert course C4 + 2 attendance documents | enrolments of S101 and S102 |
| 10 | `$lookup` students, `$group` avg by dept | AIML 65.6, CSE 70 |
| 11 | `$unset: {"contact.email": ""}` | email removed from all students |
| 12 | `$out` backup, `drop()`, `getCollectionNames()` | backup copy created then dropped |

Order used: queries -> aggregation -> crud, so Tasks 1-7 and 10 see the original semester numbers; Task 8 changes them afterwards.
