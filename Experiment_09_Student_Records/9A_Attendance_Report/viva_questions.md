# Viva questions - 9A Attendance report

**Q1. Why separate collections for attendance and exams instead of embedding in students?** Students and courses are many-to-many; the relationship has its own data (counts, marks). Embedding would create unbounded, growing arrays and make course-wise reports scan every student.

**Q2. What is embedded and why?** `contact` (phone, email, city): 1:1 data read with the student.

**Q3. How is attendance % computed?** `attended / total * 100`, rounded with `$round`.

**Q4. What is a defaulter here?** Attendance below 75 %.

**Q5. Why `$lookup` twice in Task 6?** Once to fetch the student name (`students._id = student_id`), once for the course name.

**Q6. `$inc` with two fields?** Increments `total` and `attended` in one atomic update of the document.

**Q7. What does `$jsonSchema` validation do?** The server rejects inserts/updates that break the rules (required fields, semester 1-8); error 121 DocumentValidationFailure.

**Q8. Why a unique compound index on (student_id, course_id)?** Speeds the lookup and guarantees one attendance document per pair.

**Q9. How do you delete attendance of students who left?** `deleteMany({student_id: 'S103'})`; in practice deactivate or archive instead of deleting.

**Q10. `$group` with `$addToSet` and `$size`?** Collect distinct student ids per department and count them (Task 9).

**Q11 (follow-up). SQL equivalent of Task 6?** `SELECT ... FROM attendance a JOIN students s ... JOIN courses c ... WHERE attended*100.0/total < 75`.

**Q12 (follow-up). Why store `total` and `attended` instead of one row per lecture?** Compact; a per-lecture log would allow detailed history but needs far more documents.
