"""3C - FD analysis of the 1NF relation plus a data-level check of the multivalued dependency EmpID ->> Skill."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools"))
from fd_tools import report

ATTRS = "EmpID,EmpName,DeptID,DeptName,ProjectID,ProjectName,Hours,Skill"
FDS = [("EmpID", "EmpName,DeptID"),
       ("DeptID", "DeptName"),
       ("ProjectID", "ProjectName"),
       ("EmpID,ProjectID", "Hours")]

report("3C: EP_1NF (Skills made atomic; Skill is determined by nothing, so it joins the key)", ATTRS, FDS,
       closures_of=["EmpID", "EmpID,ProjectID", "EmpID,ProjectID,Skill"])

# Without the Skill column all dependencies are FDs; this 7-attribute decomposition is lossless by the chase test.
NO_SKILL = "EmpID,EmpName,DeptID,DeptName,ProjectID,ProjectName,Hours"
report("3C: FD part (Skill removed) -> Department | Employee | Project | Works_On", NO_SKILL, FDS, analyse=False,
       decomposition=["DeptID,DeptName", "EmpID,EmpName,DeptID", "ProjectID,ProjectName", "EmpID,ProjectID,Hours"])

# The Skill column is separated by the MVD EmpID ->> Skill (not an FD, so the FD-chase cannot prove it).
# Verify it on the data: projecting onto (EmpID, Skill) and (everything else) and joining back gives exactly the 1NF rows.
rows = [("E1","Ravi","D1","R&D","PR1","Chatbot",20,"Python"), ("E1","Ravi","D1","R&D","PR1","Chatbot",20,"SQL"),
        ("E1","Ravi","D1","R&D","PR2","Vision",15,"Python"), ("E1","Ravi","D1","R&D","PR2","Vision",15,"SQL"),
        ("E2","Sneha","D2","IT","PR1","Chatbot",30,"Java"),
        ("E3","Amol","D1","R&D","PR3","Analytics",25,"SQL"), ("E3","Amol","D1","R&D","PR3","Analytics",25,"Tableau")]
skills = {(r[0], r[7]) for r in rows}
rest = {r[:7] for r in rows}
joined = {r + (s,) for r in rest for (e, s) in skills if r[0] == e}
print("=== 3C: MVD EmpID ->> Skill checked on the data ===")
print("rows in EP_1NF                :", len(rows))
print("rows in Emp_Skill projection  :", len(skills), sorted(skills))
print("rows in 'rest' projection     :", len(rest))
print("natural join reproduces 1NF   :", joined == set(rows), f"({len(joined)} rows)")
