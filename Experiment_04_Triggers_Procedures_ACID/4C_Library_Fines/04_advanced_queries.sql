-- Experiment 4C - additional examiner-style queries (run after 03)
USE library_4c;

-- ### ADV 1: Early return gives no fine
START TRANSACTION;
CALL issue_book('B2', 'Zoya');
UPDATE Issue SET return_date = CURRENT_DATE WHERE member = 'Zoya';
SELECT member, due_date, return_date, fine FROM Issue WHERE member = 'Zoya';
ROLLBACK;

-- ### ADV 2: A return date is filled only once - second update does not re-charge the fine
-- The trigger condition OLD.return_date IS NULL protects against double counting; B1.available is also not incremented twice.
START TRANSACTION;
SELECT available FROM Book WHERE book_id = 'B1';
UPDATE Issue SET return_date = '2026-10-25' WHERE issue_id = 1;
SELECT fine FROM Issue WHERE issue_id = 1;
SELECT available FROM Book WHERE book_id = 'B1';
ROLLBACK;

-- ### ADV 3: Members and the number of unreturned books they hold
SELECT member, COUNT(*) AS holding FROM Issue WHERE return_date IS NULL GROUP BY member;

-- ### ADV 4: Return an Issue record for a book to make it available again, then issue B3 successfully
START TRANSACTION;
UPDATE Book SET available = 1 WHERE book_id = 'B3';
CALL issue_book('B3', 'Sneha');
SELECT * FROM Book WHERE book_id = 'B3';
ROLLBACK;

-- ### ADV 5: CHECK stops available from going negative even if the procedure is bypassed
-- Error 3819.
UPDATE Book SET available = available - 1 WHERE book_id = 'B3';

-- ### ADV 6: Fine report per member
SELECT member, SUM(fine) AS total_fine FROM Issue GROUP BY member ORDER BY total_fine DESC;
