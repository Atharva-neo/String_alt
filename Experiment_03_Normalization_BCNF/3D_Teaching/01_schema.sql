-- Experiment 3D - Teaching : a relation in 3NF that is NOT in BCNF
-- @DB norm_3d
/* @ER
flowchart LR
    R["Teaching(Student, Subject, Teacher)<br/>keys: {Student,Subject}, {Student,Teacher}<br/>3NF but not BCNF"] -->|"Task 6: decompose on Teacher -> Subject"| D["Teacher_Subject(Teacher, Subject)<br/>Student_Teacher(Student, Teacher)"]
*/
DROP DATABASE IF EXISTS norm_3d;
CREATE DATABASE norm_3d;
USE norm_3d;

CREATE TABLE Teaching (
    Student VARCHAR(30) NOT NULL,
    Subject VARCHAR(30) NOT NULL,
    Teacher VARCHAR(30) NOT NULL,
    PRIMARY KEY (Student, Subject),          -- chosen primary key; {Student, Teacher} is the other candidate key
    UNIQUE KEY uq_student_teacher (Student, Teacher)
) ENGINE=InnoDB;
