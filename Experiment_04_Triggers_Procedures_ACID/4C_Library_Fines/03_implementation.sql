-- Experiment 4C - Library fines : 12 tasks
/* @CONCEPTS
* A **BEFORE UPDATE** trigger may modify `NEW` (here: compute the fine) - that is its main advantage over an AFTER trigger.
* Fine rule: 5 x number of days between due_date and return_date when the book comes back late (never negative).
* **SAVEPOINT**: a named point inside a transaction; `ROLLBACK TO SAVEPOINT x` undoes only the work after x, the transaction stays open and `COMMIT` keeps the rest.
* **Row-count rule** as a trigger: BEFORE INSERT counts the member's unreturned books and SIGNALs when the limit (3) is reached.
* `SHOW TRIGGERS`, `SHOW PROCEDURE STATUS`, `DROP PROCEDURE` are the metadata commands for stored code.
*/

-- ### TASK 1: Create Book and Issue and insert the data
SELECT * FROM Book;
SELECT * FROM Issue;

-- ### TASK 2: BEFORE UPDATE trigger on Issue: fine = 5 x days late when return_date is filled
-- Fires only when return_date goes from NULL to a date. GREATEST(..., 0) avoids negative fines for early returns.
DELIMITER $$
CREATE TRIGGER trg_issue_fine BEFORE UPDATE ON Issue FOR EACH ROW
BEGIN
    IF OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
        SET NEW.fine = 5 * GREATEST(DATEDIFF(NEW.return_date, NEW.due_date), 0);
    END IF;
END$$
DELIMITER ;
SHOW TRIGGERS LIKE 'Issue';

-- ### TASK 3: AFTER UPDATE trigger that increments available when a book is returned
DELIMITER $$
CREATE TRIGGER trg_issue_return AFTER UPDATE ON Issue FOR EACH ROW
BEGIN
    IF OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
        UPDATE Book SET available = available + 1 WHERE book_id = NEW.book_id;
    END IF;
END$$
DELIMITER ;
SELECT trigger_name, action_timing, event_manipulation FROM information_schema.triggers WHERE trigger_schema = 'library_4c';

-- ### TASK 4: Procedure issue_book(IN b, IN m): check availability, insert with due_date = issue_date + 14 days, decrement available; error if 0
-- FOR UPDATE locks the book row so two members cannot take the last copy at the same time.
DELIMITER $$
CREATE PROCEDURE issue_book(IN b VARCHAR(5), IN m VARCHAR(30))
BEGIN
    DECLARE v_avail INT;
    SELECT available INTO v_avail FROM Book WHERE book_id = b FOR UPDATE;
    IF v_avail IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Book not found';
    END IF;
    IF v_avail <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Book not available';
    END IF;
    INSERT INTO Issue (book_id, member, issue_date, due_date)
    VALUES (b, m, CURRENT_DATE, DATE_ADD(CURRENT_DATE, INTERVAL 14 DAY));
    UPDATE Book SET available = available - 1 WHERE book_id = b;
END$$
DELIMITER ;
SHOW PROCEDURE STATUS WHERE Db = 'library_4c';

-- ### TASK 5: Return book 1 on 2026-10-20 and show the fine
-- Due 2026-10-15, returned 2026-10-20 = 5 days late => fine 25. The AFTER trigger raises B1.available from 2 to 3.
UPDATE Issue SET return_date = '2026-10-20' WHERE issue_id = 1;
SELECT issue_id, book_id, member, due_date, return_date, fine FROM Issue WHERE issue_id = 1;
SELECT * FROM Book;

-- ### TASK 6: Call issue_book('B3','Sneha') and show the error
-- B3 has 0 copies available, so the procedure signals 'Book not available' and inserts nothing.
CALL issue_book('B3', 'Sneha');
SELECT COUNT(*) AS issues_for_sneha FROM Issue WHERE member = 'Sneha';

-- ### TASK 7: Function total_fine(member) returning the fine paid by a member
DELIMITER $$
CREATE FUNCTION total_fine(p_member VARCHAR(30)) RETURNS INT READS SQL DATA
BEGIN
    DECLARE v_total INT;
    SELECT COALESCE(SUM(fine), 0) INTO v_total FROM Issue WHERE member = p_member;
    RETURN v_total;
END$$
DELIMITER ;
SELECT total_fine('Riya') AS riya, total_fine('Amit') AS amit;

-- ### TASK 8: Procedure overdue_list() with a cursor: books not returned past the due date
-- Loops over unreturned issues whose due_date is before today and prints one line per book. (Output depends on today's date.)
DELIMITER $$
CREATE PROCEDURE overdue_list()
BEGIN
    DECLARE v_book VARCHAR(5);
    DECLARE v_member VARCHAR(30);
    DECLARE v_due DATE;
    DECLARE done INT DEFAULT 0;
    DECLARE cur CURSOR FOR SELECT book_id, member, due_date FROM Issue WHERE return_date IS NULL AND due_date < CURRENT_DATE ORDER BY due_date;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_book, v_member, v_due;
        IF done = 1 THEN
            LEAVE read_loop;
        END IF;
        SELECT CONCAT('Book ', v_book, ' held by ', v_member, ' is overdue by ', DATEDIFF(CURRENT_DATE, v_due), ' days (due ', v_due, ')') AS overdue;
    END LOOP;
    CLOSE cur;
END$$
DELIMITER ;
CALL overdue_list();

-- ### TASK 9: Transaction: issue B1 and B2 to Sneha, SAVEPOINT after B1, ROLLBACK TO the savepoint, COMMIT
-- Only the B1 issue survives: B1.available goes 3 -> 2, B2.available stays 1 because its issue and decrement were rolled back.
START TRANSACTION;
CALL issue_book('B1', 'Sneha');
SAVEPOINT after_b1;
CALL issue_book('B2', 'Sneha');
SELECT book_id, member FROM Issue WHERE member = 'Sneha';
ROLLBACK TO SAVEPOINT after_b1;
COMMIT;
SELECT issue_id, book_id, member FROM Issue WHERE member = 'Sneha';
SELECT * FROM Book;

-- ### TASK 10: Trigger that blocks issuing more than 3 books to one member
-- BEFORE INSERT counts the member's unreturned books; with 3 already out the 4th INSERT is rejected before it is written.
-- Sneha already holds B1 (Task 9); two more are issued, the next one is blocked. Run in a transaction that is rolled back.
DELIMITER $$
CREATE TRIGGER trg_issue_limit BEFORE INSERT ON Issue FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM Issue WHERE member = NEW.member AND return_date IS NULL) >= 3 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Limit reached: a member can hold at most 3 books';
    END IF;
END$$
DELIMITER ;
START TRANSACTION;
CALL issue_book('B1', 'Sneha');
CALL issue_book('B2', 'Sneha');
CALL issue_book('B1', 'Sneha');
SELECT member, COUNT(*) AS unreturned FROM Issue WHERE member = 'Sneha' AND return_date IS NULL GROUP BY member;
ROLLBACK;

-- ### TASK 11: Show all triggers with SHOW TRIGGERS
SHOW TRIGGERS\G

-- ### TASK 12: Drop procedure overdue_list and verify
-- After DROP PROCEDURE the routine disappears from the catalogue and calling it fails with error 1305.
DROP PROCEDURE overdue_list;
SHOW PROCEDURE STATUS WHERE Db = 'library_4c' AND Name = 'overdue_list';
SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'library_4c' ORDER BY routine_name;
CALL overdue_list();
