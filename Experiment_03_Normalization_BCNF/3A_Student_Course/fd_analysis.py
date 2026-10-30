"""3A - attribute closures, candidate keys and normal-form checks computed with tools/fd_tools.py."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools"))
from fd_tools import report, closure, fmt

ATTRS = "RollNo,Name,CourseID,CourseName,Faculty,FacultyPhone,Grade"
FDS = [("RollNo", "Name"),
       ("CourseID", "CourseName,Faculty"),
       ("Faculty", "FacultyPhone"),
       ("RollNo,CourseID", "Grade")]

# Task 4 + 5 + 6 + 7 + 8 on the 1NF relation
report("3A: 1NF relation Student_Course(RollNo, Name, CourseID, CourseName, Faculty, FacultyPhone, Grade)",
       ATTRS, FDS, closures_of=["RollNo", "RollNo,CourseID"])

# Step 2NF
report("3A: after 2NF  (Student | Course_Faculty | Enrolment)", ATTRS, FDS, analyse=False,
       decomposition=["RollNo,Name", "CourseID,CourseName,Faculty,FacultyPhone", "RollNo,CourseID,Grade"])

# Step 3NF / BCNF (final)
report("3A: final 3NF = BCNF  (Student | Faculty | Course | Enrolment)", ATTRS, FDS, analyse=False,
       decomposition=["RollNo,Name", "Faculty,FacultyPhone", "CourseID,CourseName,Faculty", "RollNo,CourseID,Grade"])
