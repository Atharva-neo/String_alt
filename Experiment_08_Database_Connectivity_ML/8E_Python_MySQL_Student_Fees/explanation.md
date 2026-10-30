# Explanation - 8E_Python_MySQL_Student_Fees

| Task | What happens |
|---|---|
| 1 | `mysql.connector.connect(host,user,password)` from environment variables; `server_info` |
| 2 | `CREATE DATABASE collegeDB`, table with `CHECK (fee_paid <= fee_total)` |
| 3 | parameterised `INSERT ... VALUES (%s, ...)` + `commit()` |
| 4 | `executemany` |
| 5 | `fetchall()` printed as a table |
| 6 | `WHERE fee_paid < fee_total`, pending = total - paid |
| 7 | keyboard/CLI roll + amount, parameterised UPDATE; SQL-injection explanation |
| 8 | DELETE + `cursor.rowcount` |
| 9 | `CREATE PROCEDURE pay_fee`, `callproc`, `stored_results()` |
| 10 | `autocommit=False`; second UPDATE violates the CHECK -> `rollback()`; table unchanged |
| 11 | DataFrame + `groupby('dept')` |
| 12 | `mysql.connector.Error`: errno 1045 (wrong password), 1146 (missing table); `finally` closes |
