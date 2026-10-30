# Viva questions - 3C Employee_Project

**Q1. Which attribute violates 1NF and how did you fix it?** `Skills` holds a list; one row per skill (or better, a separate Emp_Skill table).

**Q2. What is the candidate key of the 1NF relation and why does it contain Skill?** {EmpID, ProjectID, Skill}; Skill is not determined by any other attribute set, so every key must include it.

**Q3. Define a multivalued dependency.** X ->> Y: for a given X the set of Y values is independent of the other attributes. EmpID ->> Skill: an employee's skills do not depend on the project.

**Q4. Why is the MVD a problem even in BCNF tables?** BCNF considers only FDs. The EP_1NF relation can be in BCNF w.r.t. FDs yet repeat each skill for each project.

**Q5. What is 4NF?** BCNF plus: for every non-trivial MVD X ->> Y, X is a superkey. Achieved by Emp_Skill + Works_On.

**Q6. Partial vs transitive dependencies here?** Partial: EmpID -> EmpName/DeptID, ProjectID -> ProjectName. Transitive: EmpID -> DeptID -> DeptName.

**Q7. How do you list employees who know both Python and SQL?** Filter skills IN ('Python','SQL'), group by employee, `HAVING COUNT(DISTINCT Skill) = 2`.

**Q8. Which department has the most hours?** R&D (60 = Ravi 35 + Amol 25).

**Q9. Why use a composite PK in Emp_Skill?** An employee may have many skills, and the same skill must not be stored twice for one employee.

**Q10. Can lossless join be proved with FDs alone here?** For the FD part yes (chase); for the Skill split you need the MVD (data check in fd_analysis.py).

**Q11 (follow-up). Why GROUP_CONCAT?** To show one row per project with all employee names; Oracle uses LISTAGG.

**Q12 (follow-up). Is Hours dependent on Skill?** No, Hours depends on (EmpID, ProjectID) only.
