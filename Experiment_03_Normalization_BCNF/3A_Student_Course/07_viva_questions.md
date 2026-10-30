# Viva questions - 3A Student_Course

**Q1. Why is the table not in 1NF?** Cells contain lists (`C1, C2`, `A, B`). 1NF requires atomic values and no repeating groups.

**Q2. What is the candidate key and how did you prove it?** {RollNo, CourseID}: its closure is all attributes and neither RollNo+ nor CourseID+ is.

**Q3. Define a partial dependency with an example.** A non-prime attribute depending on a proper subset of a candidate key: RollNo -> Name (RollNo is part of {RollNo, CourseID}).

**Q4. Define a transitive dependency with an example.** CourseID -> Faculty and Faculty -> FacultyPhone, so CourseID -> FacultyPhone through a non-key attribute.

**Q5. Is 3NF always BCNF?** No. 3NF allows X -> A where A is prime; BCNF requires every determinant to be a superkey. Here the final schema is both (see 3D for a case that is 3NF but not BCNF).

**Q6. How do you check a lossless join?** Common attribute set of a binary decomposition must be a key of at least one part (R1 ∩ R2 -> R1 or R2); verified with the chase in `fd_analysis.py` and with anti-joins in SQL.

**Q7. What is dependency preservation?** The union of FDs of the decomposed tables implies all original FDs, so constraints can be checked without joins.

**Q8. Show an update anomaly.** Changing one of Dr. Kale's phone numbers in the 1NF table leaves two different numbers; in the normalised design one UPDATE on Faculty suffices (ADV 2).

**Q9. Why insert Faculty before Course?** The FK Course.Faculty -> Faculty needs the parent row first.

**Q10. How do you test an FD in SQL?** `GROUP BY X HAVING COUNT(DISTINCT Y) > 1` must return nothing.

**Q11 (follow-up). Why is Grade not in Student or Course?** It depends on both RollNo and CourseID (full dependency), so it belongs to Enrolment.

**Q12 (follow-up). Would you denormalise this schema?** Only for read-heavy reporting; the 4-way join (Task 11) can be wrapped in a view.
