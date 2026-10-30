-- Experiment 3C - additional examiner-style queries (run after 03)
USE norm_3c;

-- ### ADV 1: Reconstruct the 1NF table (lossless-join check)
-- Joining Employee-Department-Works_On-Project-Emp_Skill gives 7 rows, identical to EP_1NF.
CREATE VIEW ep_rebuilt AS
SELECT e.EmpID, e.EmpName, d.DeptID, d.DeptName, p.ProjectID, p.ProjectName, w.Hours, s.Skill
FROM Employee e JOIN Department d USING (DeptID) JOIN Works_On w USING (EmpID) JOIN Project p USING (ProjectID) JOIN Emp_Skill s USING (EmpID);
SELECT COUNT(*) AS rebuilt_rows,
       (SELECT COUNT(*) FROM EP_1NF o WHERE NOT EXISTS (SELECT 1 FROM ep_rebuilt r WHERE r.EmpID=o.EmpID AND r.ProjectID=o.ProjectID AND r.Skill=o.Skill AND r.Hours=o.Hours AND r.DeptName=o.DeptName)) AS missing
FROM ep_rebuilt;

-- ### ADV 2: Add a skill for Sneha without touching any project row
-- With Emp_Skill the MVD no longer forces extra project rows.
INSERT INTO Emp_Skill VALUES ('E2', 'SQL');
SELECT * FROM Emp_Skill WHERE EmpID = 'E2';

-- ### ADV 3: In EP_1NF the same change needs one row per project
-- Sneha works on one project only, but Ravi (2 projects) adding a skill 'Docker' would need 2 new rows:
SELECT COUNT(*) AS rows_needed_in_1nf_to_add_one_skill_for_ravi FROM Works_On WHERE EmpID = 'E1';

-- ### ADV 4: Employees without any project
SELECT e.EmpName FROM Employee e LEFT JOIN Works_On w USING (EmpID) WHERE w.ProjectID IS NULL;

-- ### ADV 5: Duplicate skill for the same employee
-- Error 1062: the composite key (EmpID, Skill) prevents it.
INSERT INTO Emp_Skill VALUES ('E1', 'SQL');

-- ### ADV 6: Negative hours
-- Error 3819.
INSERT INTO Works_On VALUES ('E2', 'PR3', -5);
