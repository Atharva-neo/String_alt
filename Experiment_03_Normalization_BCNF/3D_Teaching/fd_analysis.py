"""3D - keys, prime attributes, 3NF vs BCNF, lossless join and the lost dependency."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools"))
from fd_tools import report

ATTRS = "Student,Subject,Teacher"
FDS = [("Student,Subject", "Teacher"), ("Teacher", "Subject")]

report("3D: Teaching(Student, Subject, Teacher)", ATTRS, FDS,
       closures_of=["Teacher", "Student,Subject", "Student,Teacher", "Student"])
report("3D: BCNF decomposition  Teacher_Subject(Teacher, Subject) | Student_Teacher(Student, Teacher)", ATTRS, FDS, analyse=False,
       decomposition=["Teacher,Subject", "Student,Teacher"])
