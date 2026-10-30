# Viva questions - 8E_Python_MySQL_Student_Fees

**Q1. Why `%s` placeholders and not f-strings?** The driver sends parameters separately from the SQL text, so input can never change the statement (prevents SQL injection). `%s` is a placeholder for every type, not a Python format.

**Q2. Show an injection example.** Roll `102 OR 1=1` in an f-string UPDATE would update every student; with `%s` the whole text is one (invalid) integer value.

**Q3. `commit()` and `rollback()`?** Connector default is autocommit OFF: changes are visible only to this connection until `commit()`.

**Q4. `execute` vs `executemany`?** One statement vs the same statement for many parameter tuples (batched).

**Q5. What does `callproc` return?** Result sets are read with `cursor.stored_results()`; OUT parameters come back in the returned tuple.

**Q6. Which errors did Task 12 handle?** 1045 Access denied (wrong password) and 1146 Table doesn't exist; `mysql.connector.Error` has `errno`, `sqlstate`, `msg`.

**Q7. Why close in `finally`?** So connections are released even when an exception occurs.
