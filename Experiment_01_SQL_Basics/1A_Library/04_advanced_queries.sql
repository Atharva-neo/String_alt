-- Experiment 1A - additional examiner-style queries
USE library_1a;

-- ### ADV 1: Books that have never been issued
-- LEFT JOIN keeps every book; rows with no match have NULL on the Issue side.
SELECT b.book_id, b.title FROM Book b LEFT JOIN Issue i ON i.book_id = b.book_id WHERE i.issue_id IS NULL;

-- ### ADV 2: Who currently holds which book (unreturned loans), with days held
-- DATEDIFF(CURRENT_DATE, issue_date) is the number of days since the book left the library.
SELECT m.name, b.title, i.issue_date, DATEDIFF(CURRENT_DATE, i.issue_date) AS days_held
FROM Issue i JOIN Book b ON b.book_id = i.book_id JOIN Member m ON m.member_id = i.member_id
WHERE i.return_date IS NULL;

-- ### ADV 3: Delete a member who still has issue records (RESTRICT behaviour)
-- The default FK action is RESTRICT/NO ACTION, so M01 (with 2 issue rows) cannot be deleted -> error 1451.
DELETE FROM Member WHERE member_id = 'M01';

-- ### ADV 4: Overdue loans (policy: 14 days) for books not returned
SELECT i.issue_id, i.book_id, i.member_id, DATEDIFF(CURRENT_DATE, i.issue_date) - 14 AS days_overdue
FROM Issue i WHERE i.return_date IS NULL AND DATEDIFF(CURRENT_DATE, i.issue_date) > 14;

-- ### ADV 5: Total inventory value per author
SELECT author, SUM(price * copies) AS stock_value FROM Book GROUP BY author ORDER BY stock_value DESC;

-- ### ADV 6: Add ON DELETE CASCADE to the member FK, delete M02 and see its loans disappear
-- Re-creating the FK with CASCADE makes the child rows follow the parent. Done inside a transaction-free demo, so we restore data afterwards.
ALTER TABLE Issue DROP FOREIGN KEY fk_issue_member;
ALTER TABLE Issue ADD CONSTRAINT fk_issue_member FOREIGN KEY (member_id) REFERENCES Member(member_id) ON DELETE CASCADE;
DELETE FROM Member WHERE member_id = 'M02';
SELECT * FROM Issue;
