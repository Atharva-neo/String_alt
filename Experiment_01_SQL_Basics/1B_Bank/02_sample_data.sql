-- Experiment 1B - sample data from the PDF
USE bank_1b;
INSERT INTO Branch VALUES ('BR1','Vishrambag','Sangli'), ('BR2','Rajarampuri','Kolhapur'), ('BR3','Deccan','Pune');
INSERT INTO Customer VALUES
('C1','Rahul More','Sangli','1995-04-12'),
('C2','Pooja Shinde','Pune','1990-09-23'),
('C3','Kiran Desai','Kolhapur','1988-01-30');
INSERT INTO Account (acc_no, cust_id, branch_id, acc_type, balance) VALUES
(5001,'C1','BR1','Savings',25000),
(5002,'C2','BR3','Current',120000),
(5003,'C3','BR2','Savings',8000),
(5004,'C1','BR1','Current',45000);
