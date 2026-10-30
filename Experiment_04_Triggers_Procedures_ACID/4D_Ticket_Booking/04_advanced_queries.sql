-- Experiment 4D - additional examiner-style queries (run after 03)
USE ticket_4d;

-- ### ADV 1: Cancel an already cancelled booking - seats are NOT restored twice
START TRANSACTION;
SELECT available FROM Show_Seats WHERE show_id = 1;
UPDATE Booking SET status = 'Cancelled' WHERE booking_id = 1;
SELECT available FROM Show_Seats WHERE show_id = 1;
ROLLBACK;

-- ### ADV 2: Book exactly the remaining seats, then one more
START TRANSACTION;
CALL book_ticket(1, 'Last', 3);
SELECT available FROM Show_Seats WHERE show_id = 1;
ROLLBACK;

-- ### ADV 3: Zero or negative seats
-- Error 3819 (chk_booking_seats) - the CHECK fires after the BEFORE trigger.
INSERT INTO Booking (show_id, customer, seats) VALUES (2, 'Bad', 0);

-- ### ADV 4: Invalid status value
-- Error 3819 (chk_booking_status).
UPDATE Booking SET status = 'Pending' WHERE booking_id = 1;

-- ### ADV 5: Revenue of all shows combined
SELECT SUM(revenue(show_id)) AS total_revenue FROM Show_Seats;

-- ### ADV 6: Booking for an unknown show
-- The FK / guard trigger refuses it (error 1644 'Show not found' from the guard).
INSERT INTO Booking (show_id, customer, seats) VALUES (9, 'Ghost', 1);
