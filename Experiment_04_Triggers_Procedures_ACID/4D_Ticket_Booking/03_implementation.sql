-- Experiment 4D - Ticket booking : 12 tasks.  Task 11 (kill the session) is performed by run_demo.py with real connections.
/* @CONCEPTS
* Three triggers keep `available` consistent: BEFORE INSERT (guard), AFTER INSERT (reserve), AFTER UPDATE (restore on cancellation).
* Procedure `book_ticket` wraps the booking in a transaction with an exit handler: success = COMMIT, any error = ROLLBACK + error to the caller.
* **SAVEPOINT** inside a transaction lets one booking be undone without losing the previous one.
* **Atomicity** = all or nothing (rollback, killed session); **Consistency** = `available + booked seats = capacity` always; **Isolation** = other sessions do not see uncommitted bookings; **Durability** = committed bookings survive (see 4A durability demo).
*/

-- ### TASK 1: Create Show_Seats and Booking and insert the data
SELECT * FROM Show_Seats;
SELECT COUNT(*) AS bookings FROM Booking;

-- ### TASK 2: AFTER INSERT trigger on Booking that reduces available by seats
DELIMITER $$
CREATE TRIGGER trg_booking_reserve AFTER INSERT ON Booking FOR EACH ROW
BEGIN
    UPDATE Show_Seats SET available = available - NEW.seats WHERE show_id = NEW.show_id;
END$$
DELIMITER ;
SELECT trigger_name, action_timing, event_manipulation FROM information_schema.triggers WHERE trigger_schema = 'ticket_4d';

-- ### TASK 3: AFTER UPDATE trigger that restores seats when status changes to 'Cancelled'
-- The condition OLD.status <> 'Cancelled' prevents restoring the same seats twice.
DELIMITER $$
CREATE TRIGGER trg_booking_cancel AFTER UPDATE ON Booking FOR EACH ROW
BEGIN
    IF NEW.status = 'Cancelled' AND OLD.status <> 'Cancelled' THEN
        UPDATE Show_Seats SET available = available + OLD.seats WHERE show_id = OLD.show_id;
    END IF;
END$$
DELIMITER ;
SELECT trigger_name, action_timing, event_manipulation FROM information_schema.triggers WHERE trigger_schema = 'ticket_4d' ORDER BY trigger_name;

-- ### TASK 4: BEFORE INSERT trigger that blocks booking when seats > available
-- The guard reads the current availability; if the request is bigger it SIGNALs and the INSERT never happens.
DELIMITER $$
CREATE TRIGGER trg_booking_guard BEFORE INSERT ON Booking FOR EACH ROW
BEGIN
    DECLARE v_avail INT;
    SELECT available INTO v_avail FROM Show_Seats WHERE show_id = NEW.show_id;
    IF v_avail IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Show not found';
    END IF;
    IF NEW.seats > v_avail THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not enough seats available';
    END IF;
END$$
DELIMITER ;
SELECT trigger_name, action_timing, event_manipulation FROM information_schema.triggers WHERE trigger_schema = 'ticket_4d' ORDER BY trigger_name;

-- ### TASK 5: Book 2 seats for show 1, then try 2 more - error
-- Show 1 has 3 seats. After the first booking 1 seat is left, so a request for 2 is rejected by trg_booking_guard.
INSERT INTO Booking (show_id, customer, seats) VALUES (1, 'Aarav', 2);
SELECT * FROM Show_Seats WHERE show_id = 1;
INSERT INTO Booking (show_id, customer, seats) VALUES (1, 'Bhumi', 2);
SELECT booking_id, customer, seats, status FROM Booking;
SELECT * FROM Show_Seats WHERE show_id = 1;

-- ### TASK 6: Cancel the first booking and show seats restored
-- Changing status to 'Cancelled' fires trg_booking_cancel: available 1 -> 3.
UPDATE Booking SET status = 'Cancelled' WHERE booking_id = 1;
SELECT booking_id, customer, seats, status FROM Booking;
SELECT * FROM Show_Seats WHERE show_id = 1;

-- ### TASK 7: Procedure book_ticket(show, cust, n) as a transaction
-- START TRANSACTION, INSERT (the triggers reserve the seats), COMMIT. Any error (guard trigger, unknown show, CHECK) triggers the handler: ROLLBACK + RESIGNAL.
DELIMITER $$
CREATE PROCEDURE book_ticket(IN p_show INT, IN p_cust VARCHAR(30), IN p_n INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    INSERT INTO Booking (show_id, customer, seats) VALUES (p_show, p_cust, p_n);
    COMMIT;
END$$
DELIMITER ;
CALL book_ticket(2, 'Meera', 4);
SELECT * FROM Show_Seats;
CALL book_ticket(1, 'Zoya', 9);
SELECT booking_id, show_id, customer, seats, status FROM Booking;

-- ### TASK 8: Function revenue(show_id) at 200 per seat
-- Only 'Booked' rows count, cancelled bookings earn nothing. Show 2: 4 seats x 200 = 800; show 1: 0 (its only booking was cancelled).
DELIMITER $$
CREATE FUNCTION revenue(p_show INT) RETURNS DECIMAL(10,2) READS SQL DATA
BEGIN
    DECLARE v_seats INT;
    SELECT COALESCE(SUM(seats), 0) INTO v_seats FROM Booking WHERE show_id = p_show AND status = 'Booked';
    RETURN v_seats * 200;
END$$
DELIMITER ;
SELECT show_id, movie, revenue(show_id) AS revenue FROM Show_Seats;

-- ### TASK 9: Procedure show_report() printing seats booked and available per show using a cursor
DELIMITER $$
CREATE PROCEDURE show_report()
BEGIN
    DECLARE v_show INT;
    DECLARE v_movie VARCHAR(30);
    DECLARE v_avail INT;
    DECLARE v_booked INT;
    DECLARE done INT DEFAULT 0;
    DECLARE cur CURSOR FOR SELECT show_id, movie, available FROM Show_Seats ORDER BY show_id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    OPEN cur;
    rep: LOOP
        FETCH cur INTO v_show, v_movie, v_avail;
        IF done = 1 THEN
            LEAVE rep;
        END IF;
        SELECT COALESCE(SUM(seats), 0) INTO v_booked FROM Booking WHERE show_id = v_show AND status = 'Booked';
        SELECT CONCAT('Show ', v_show, ' (', v_movie, '): booked ', v_booked, ', available ', v_avail) AS report;
    END LOOP;
    CLOSE cur;
END$$
DELIMITER ;
CALL show_report();

-- ### TASK 10: Two bookings in one transaction with a SAVEPOINT between; roll back the second
-- Both inserts reduce seats of show 2 (46 -> 44 -> 41); ROLLBACK TO SAVEPOINT undoes only the second one (and its seat reduction made by the trigger).
START TRANSACTION;
INSERT INTO Booking (show_id, customer, seats) VALUES (2, 'Rohan', 2);
SAVEPOINT after_first;
INSERT INTO Booking (show_id, customer, seats) VALUES (2, 'Rohan', 3);
SELECT customer, seats FROM Booking WHERE customer = 'Rohan';
SELECT available FROM Show_Seats WHERE show_id = 2;
ROLLBACK TO SAVEPOINT after_first;
COMMIT;
SELECT customer, seats FROM Booking WHERE customer = 'Rohan';
SELECT available FROM Show_Seats WHERE show_id = 2;

-- ### TASK 11: Transaction with two bookings, kill the session before COMMIT, reconnect - nothing saved (atomicity)
-- A killed/disconnected session is rolled back by the server. This needs two connections, so it is done by run_demo.py (see the multi-session section below).
SELECT 'see run_demo.py: Task 11' AS note;

-- ### TASK 12: How each ACID property was demonstrated (evidence queries)
-- A: Task 5 failed booking left no row, Task 10 savepoint rollback, Task 11 killed session.  C: CHECK(available>=0) + guard trigger => the invariant below holds.
-- I: Task 11 second connection saw nothing of the uncommitted bookings (and 4A Task 10).  D: committed rows survive a restart (4A DURABILITY.md).
-- Invariant check: available + booked seats must equal the original capacity (3 and 50) for every show.
SELECT s.show_id, s.movie, s.available, COALESCE(SUM(CASE WHEN b.status = 'Booked' THEN b.seats END), 0) AS booked,
       s.available + COALESCE(SUM(CASE WHEN b.status = 'Booked' THEN b.seats END), 0) AS capacity_check
FROM Show_Seats s LEFT JOIN Booking b ON b.show_id = s.show_id GROUP BY s.show_id, s.movie, s.available;
SELECT 'Atomicity' AS property, 'Tasks 5, 10, 11 - failed / rolled back bookings leave no trace' AS demonstrated_by UNION ALL
SELECT 'Consistency', 'CHECK + guard trigger; available + booked = capacity (query above)' UNION ALL
SELECT 'Isolation', 'Task 11: other connection sees no uncommitted rows; 4A Task 10 lock wait' UNION ALL
SELECT 'Durability', 'Committed bookings persist after restart (4A DURABILITY.md)';
