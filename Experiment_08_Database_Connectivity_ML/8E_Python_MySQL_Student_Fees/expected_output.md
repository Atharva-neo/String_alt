# Expected output - Experiment_08_Database_Connectivity_ML / 8E_Python_MySQL_Student_Fees

> Output of a run against the servers configured in the environment. Date: 2026-10-30. Values such as timings or dates differ between runs.

```text
### Task 1 - Connect with host, user, password and print the server version
connected to MySQL server version: 8.0.46

### Task 2 - Create database collegeDB and table student_fee
table student_fee created

### Task 3 - Insert one row with a parameterised query (%s placeholders) and commit
rows inserted: 1

### Task 4 - Insert the remaining rows with executemany
rows inserted: 4

### Task 5 - fetchall() and print as a formatted table
+---------+----------------+------+-----------+----------+
| roll_no | name           | dept | fee_total | fee_paid |
+---------+----------------+------+-----------+----------+
|     101 | Aditya Pawar   | AIML |  85000.00 | 85000.00 |
|     102 | Neha Gaikwad   | AIML |  85000.00 | 40000.00 |
|     103 | Omkar Salunkhe | CSE  |  90000.00 | 90000.00 |
|     104 | Priya Mane     | CSE  |  90000.00 | 30000.00 |
|     105 | Sagar Jadhav   | ENTC |  80000.00 |     0.00 |
+---------+----------------+------+-----------+----------+

### Task 6 - Students with pending fee (fee_paid < fee_total) and the pending amount
+---------+--------------+----------+
| roll_no | name         | pending  |
+---------+--------------+----------+
|     102 | Neha Gaikwad | 45000.00 |
|     104 | Priya Mane   | 60000.00 |
|     105 | Sagar Jadhav | 80000.00 |
+---------+--------------+----------+

### Task 7 - Read a roll number and an amount, update fee_paid with a parameterised query
rows updated: 1
(102, Decimal('85000.00'), Decimal('50000.00'))
Why not string formatting?  sql = f"UPDATE ... WHERE roll_no = {roll}"  lets the user type  102 OR 1=1  (or  1; DROP TABLE student_fee)
and the text becomes part of the SQL statement => SQL injection. With %s placeholders the driver sends the value as DATA, never as SQL.
negative test (paying more than the total) -> errno 3819: Check constraint 'chk_paid_le_total' is violated.

### Task 8 - Delete a student by roll number and print cursor.rowcount
cursor.rowcount = 1

### Task 9 - Create stored procedure pay_fee(IN r INT, IN amt DECIMAL) and call it with callproc
+---------+------------+-----------+----------+----------+
| roll_no | name       | fee_total | fee_paid | pending  |
+---------+------------+-----------+----------+----------+
|     104 | Priya Mane |  90000.00 | 35000.00 | 55000.00 |
+---------+------------+-----------+----------+----------+

### Task 10 - Two updates as one transaction (autocommit off); the second fails -> rollback()
error in the second update: errno 3819: Check constraint 'chk_paid_le_total' is violated.
rollback() done
table unchanged: True

### Task 11 - Load the table into a pandas DataFrame: department-wise total pending fee
dept
AIML    35000.0
CSE     55000.0

### Task 12 - Handle mysql.connector.Error: wrong password and missing table; close in finally
wrong password: errno 1045, sqlstate 28000: Access denied for user 'root'@'localhost' (using password: YES)
missing table: errno 1146, sqlstate 42S02: Table 'collegedb.no_such_table' doesn't exist
cursor and connection closed
```

**stderr / exit code 0:**

```text
D:\Dooms_day\DBMS_LAB_EXTERNAL\Experiment_08_Database_Connectivity_ML\8E_Python_MySQL_Student_Fees\main.py:114: DeprecationWarning: Call to deprecated function stored_results. Reason: The property counterpart 'stored_results' will be added in a future release, and this method will be removed.
  for rs in cur.stored_results():
```
