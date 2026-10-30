-- Experiment 5C - examiner follow-ups (not executed by tools/run_sql.py)

-- ### ADV 1: Where do I see the latest deadlock without SHOW ENGINE INNODB STATUS?
-- Enable logging of every deadlock to the error log:  SET GLOBAL innodb_print_all_deadlocks = ON;

-- ### ADV 2: Turn deadlock detection off (and rely on timeouts)
-- SET GLOBAL innodb_deadlock_detect = OFF;  -- then a deadlock only ends with ERROR 1205 after innodb_lock_wait_timeout; used on extremely hot rows

-- ### ADV 3: Which statements block whom right now?
-- SELECT * FROM sys.innodb_lock_waits\G
-- SELECT * FROM performance_schema.data_lock_waits;

-- ### ADV 4: Deadlock caused by a gap lock (not only by row locks)
-- S1> START TRANSACTION; SELECT * FROM Account WHERE acc_no BETWEEN 5 AND 9 FOR UPDATE;   -- locks the gap (no rows)
-- S2> START TRANSACTION; SELECT * FROM Account WHERE acc_no BETWEEN 5 AND 9 FOR UPDATE;   -- also gets the gap lock (gap locks do not conflict with each other)
-- S1> INSERT INTO Account VALUES (7, 1);   -- waits for S2's gap lock          S2> INSERT INTO Account VALUES (8, 1);   -- waits for S1's gap lock => deadlock
