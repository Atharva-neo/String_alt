-- Experiment 1B - additional examiner-style queries
USE bank_1b;

-- ### ADV 1: Customers with their total balance and number of accounts, richest first
SELECT c.name, COUNT(a.acc_no) AS accounts, SUM(a.balance) AS total FROM Customer c JOIN Account a USING (cust_id) GROUP BY c.cust_id, c.name ORDER BY total DESC;

-- ### ADV 2: Branch with the highest total balance
-- ORDER BY ... LIMIT 1 on the grouped result.
SELECT b.branch_name, SUM(a.balance) AS total FROM Bank_Branch b JOIN Account a USING (branch_id) GROUP BY b.branch_id, b.branch_name ORDER BY total DESC LIMIT 1;

-- ### ADV 3: Customers older than 35 as of today with their accounts
SELECT c.name, TIMESTAMPDIFF(YEAR, c.dob, CURRENT_DATE) AS age, a.acc_no FROM Customer c JOIN Account a USING (cust_id) WHERE TIMESTAMPDIFF(YEAR, c.dob, CURRENT_DATE) > 35;

-- ### ADV 4: Delete the customer who still has accounts (RESTRICT)
-- Error 1451 because Account rows reference C1.
DELETE FROM Customer WHERE cust_id = 'C1';

-- ### ADV 5: Violate NOT NULL: insert a customer with no name
-- Error 1048 (Column 'name' cannot be null).
INSERT INTO Customer (cust_id, name) VALUES ('C9', NULL);

-- ### ADV 6: Duplicate primary key
-- Error 1062 because account 5001 already exists.
INSERT INTO Account (acc_no, cust_id, branch_id, balance) VALUES (5001, 'C2', 'BR1', 5000);
