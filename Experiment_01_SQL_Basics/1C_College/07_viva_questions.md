# Viva questions - 1C College

**Q1. Why does Enrolment have a composite primary key?** Because one student can take many courses and a course has many students; the pair (roll_no, course_id) identifies one enrolment and prevents duplicates.

**Q2. Cardinalities?** Department 1:N Student, Department 1:N Course, Student M:N Course (through Enrolment, i.e. Student 1:N Enrolment and Course 1:N Enrolment).

**Q3. Why did deleting C201 fail first?** Enrolment (103, C201) references it; the default FK action RESTRICT raises ERROR 1451.

**Q4. How do you change an FK to ON DELETE CASCADE?** MySQL has no ALTER for it: `DROP FOREIGN KEY fk_enr_course`, then `ADD CONSTRAINT ... ON DELETE CASCADE`.

**Q5. What are the risks of CASCADE?** Silent mass deletion of child rows; use deliberately and only when child rows have no meaning without the parent.

**Q6. UNIQUE column `email` - what does MySQL create?** A unique index with the same name as the column; DROP COLUMN removes it.

**Q7. What happens if `year` is not updated for students in other departments?** WHERE dept_id='D1' restricts the UPDATE; without WHERE every row would be updated.

**Q8. CHECK (cgpa BETWEEN 0 AND 10) vs a data type DECIMAL(3,1)?** Type limits digits (up to 99.9), CHECK limits the business range.

**Q9. Why LEFT JOIN in Task 7?** To keep departments with zero students; COUNT(s.roll_no) counts only non-NULL matches.

**Q10. What does `faculty1` see after REVOKE SELECT?** Nothing on Student; queries return ERROR 1142 (SELECT command denied).

**Q11 (follow-up). RENAME COLUMN vs CHANGE COLUMN?** RENAME COLUMN only renames (8.0+); CHANGE needs the full column definition again.

**Q12 (follow-up). Can a view hide students' cgpa from faculty1?** Yes, grant SELECT on a view that omits cgpa instead of on the base table.
