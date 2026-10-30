# Viva questions - 9C Report card

**Q1. How is SGPA calculated?** Sum of (course credits x grade points) divided by total credits; points O=10, A=9, B=8, C=6, F=0.

**Q2. Why is `$unwind` needed after `$lookup`?** `$lookup` returns an array; `$unwind` makes one document per match so fields like `exams.total` can be used.

**Q3. How do you combine attendance of the right course?** `$lookup` all attendance of the student, then `$arrayElemAt` of a `$filter` on `course_id`.

**Q4. What does `$out` do and what is its risk?** Writes the pipeline result to a collection, replacing it; it must be the last stage. Do not point it at a source collection you still need.

**Q5. Why store report cards instead of computing them on demand?** A materialised report makes reads cheap and gives a frozen result per semester; refresh by re-running the pipeline (Task 11 shows the refresh).

**Q6. How do you decide Pass/Fail and Detained?** Pass/Fail: `$min` of marks < 40; Detained: `$min` of attendance % < 75 over the student's courses.

**Q7. Export to CSV - options?** `mongoexport --type=csv --fields=...`, mongosh with `fs`, or a Python script with pymongo/pandas.

**Q8. Why create `{student_id:1, course_id:1}` indexes?** The report probes exams and attendance by student (and course) once per student; without the index each probe is a collection scan.

**Q9. Class topper?** `$sort` by `sgpa` descending, `$limit 1`; ties need `$rank` or `$group`.

**Q10. What happens to the report when a phone number changes?** Nothing until the pipeline runs again, because `report_cards` is a copy.

**Q11 (follow-up). SQL equivalent?** Four-table JOIN with GROUP BY, `SUM(credits * points) / SUM(credits)`, CASE for result/remark, `CREATE TABLE ... AS SELECT`.

**Q12 (follow-up). `$lookup` pipeline form?** `{$lookup: {from, let: {...}, pipeline: [{$match: {$expr: ...}}], as}}` for multi-field joins.
