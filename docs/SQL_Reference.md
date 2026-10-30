# SQL quick reference (MySQL 8 - Oracle differences marked)

## DDL / DML / DCL
| Task | MySQL 8 | Oracle |
|---|---|---|
| create table | `CREATE TABLE t (id INT PRIMARY KEY, n VARCHAR(30) NOT NULL UNIQUE, p DECIMAL(8,2) CHECK (p > 0), d DATE DEFAULT (CURRENT_DATE))` | `... d DATE DEFAULT SYSDATE`, `NUMBER(8,2)`, `VARCHAR2` |
| add / change column | `ALTER TABLE t ADD COLUMN c INT; ... MODIFY COLUMN n VARCHAR(100); ... RENAME COLUMN a TO b; ... DROP COLUMN c` | `ADD (c INT)`, `MODIFY (n VARCHAR2(100))` |
| rename table | `RENAME TABLE a TO b` | `RENAME a TO b` |
| remove | `DELETE FROM t WHERE ..` (rollback-able) / `TRUNCATE TABLE t` (DDL, resets AUTO_INCREMENT) / `DROP TABLE t` | same |
| FK with cascade | `FOREIGN KEY (c) REFERENCES p(id) ON DELETE CASCADE` ; change = `DROP FOREIGN KEY name` + `ADD CONSTRAINT` | `ALTER TABLE ... DROP CONSTRAINT` |
| privileges | `CREATE USER 'u'@'localhost' IDENTIFIED BY '..'; GRANT SELECT, UPDATE (col) ON db.t TO u; REVOKE ..; SHOW GRANTS FOR u; DROP USER u` | `CREATE USER u IDENTIFIED BY ..; GRANT .. TO u` |
| roles | `CREATE ROLE r; GRANT priv TO r; GRANT r TO u; SET DEFAULT ROLE r TO u` | roles are active by default |

## Queries
* Joins: `INNER JOIN`, `LEFT/RIGHT JOIN`, self join (alias twice), no FULL OUTER JOIN -> `LEFT UNION RIGHT`.
* Subqueries: `IN`, `EXISTS`, `> ANY` (> min), `> ALL` (> max), correlated (refers to outer row), `NOT IN` + NULL trap -> use `NOT EXISTS`.
* Aggregates: `COUNT(*)` vs `COUNT(col)`, `GROUP BY`, `HAVING` (filters groups), `WHERE` (filters rows).
* Window functions (8.0): `RANK()`, `DENSE_RANK()`, `ROW_NUMBER()`, `SUM() OVER (PARTITION BY .. ORDER BY ..)`.
* Nth highest: `DENSE_RANK() = n`, or `LIMIT 1 OFFSET n-1` on `DISTINCT` values.
* Dates: `CURRENT_DATE`, `DATEDIFF(a,b)`, `DATE_ADD(d, INTERVAL 14 DAY)`, `DATE_FORMAT(d,'%Y-%m')` (Oracle `SYSDATE`, `TO_CHAR`).
* Views: `CREATE VIEW v AS ..` ; updatable = single table, no aggregates/DISTINCT/GROUP BY; `WITH CHECK OPTION` blocks rows that would leave the view.

## Programming
```sql
DELIMITER $$
CREATE TRIGGER t BEFORE UPDATE ON acc FOR EACH ROW
BEGIN IF NEW.bal < 1000 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'too low'; END IF; END$$
CREATE PROCEDURE p(IN a INT, OUT b INT) BEGIN SELECT COUNT(*) INTO b FROM t WHERE x = a; END$$
CREATE FUNCTION f(a INT) RETURNS INT READS SQL DATA BEGIN RETURN a * 2; END$$
DELIMITER ;
```
Cursor: `DECLARE c CURSOR FOR SELECT ..; DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1; OPEN c; loop: LOOP FETCH c INTO v; IF done THEN LEAVE loop; END IF; ..; END LOOP; CLOSE c;`
Handlers: `DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;` Oracle: `RAISE_APPLICATION_ERROR(-20001,'msg')`, `EXCEPTION WHEN OTHERS THEN`.
Transactions: `START TRANSACTION; .. SAVEPOINT s; .. ROLLBACK TO SAVEPOINT s; COMMIT;` (DDL commits implicitly).

## Frequent error numbers
1062 duplicate key | 1451 parent row referenced | 1452 child row without parent | 3819 CHECK violated | 1048 NOT NULL | 1142/1143 privilege denied (table/column) | 1370 EXECUTE denied | 1644 user SIGNAL | 1213 deadlock | 1205 lock wait timeout | 1288 view not updatable | 1369 CHECK OPTION failed.
