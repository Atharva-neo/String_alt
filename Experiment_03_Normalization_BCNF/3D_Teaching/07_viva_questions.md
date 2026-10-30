# Viva questions - 3D Teaching

**Q1. Candidate keys of Teaching?** {Student, Subject} and {Student, Teacher}.

**Q2. Why is it in 3NF?** Every attribute is prime, so no non-prime attribute can be partially or transitively dependent; for Teacher -> Subject the dependent attribute Subject is prime, which 3NF allows.

**Q3. Why is it not in BCNF?** Teacher -> Subject with Teacher not a superkey.

**Q4. State the 3NF and BCNF conditions precisely.** For every non-trivial X -> A: BCNF needs X to be a superkey; 3NF needs X superkey **or** A prime.

**Q5. How did you decompose?** R1(Teacher, Subject), R2(Student, Teacher).

**Q6. Is it lossless?** Yes: R1 ∩ R2 = {Teacher} is a key of R1.

**Q7. Which FD is lost?** {Student, Subject} -> Teacher; nothing prevents a student from having two teachers for the same subject (ADV 1).

**Q8. How would you enforce the lost FD anyway?** With a trigger / assertion-like procedure checking the join, or by keeping the original relation (3NF) when preservation matters more than redundancy.

**Q9. Show the update anomaly.** If Kale moves to DAA and only Asha's row is changed, Kale teaches two subjects, contradicting Teacher -> Subject (Task 5).

**Q10. Why can Prof. Rao now be stored?** Teacher_Subject has no dependency on students (insert anomaly removed, ADV 4).

**Q11 (follow-up). Is every 2-attribute relation in BCNF?** Yes.

**Q12 (follow-up). BCNF or 3NF in practice?** Prefer BCNF; accept 3NF when BCNF would lose an FD that must be enforced declaratively.
