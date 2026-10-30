-- 4D Ticket booking - Task 11: script for session S1 (open a separate terminal: mysql -u root -p ticket_4d)
-- Execute the steps in the order of the step numbers; steps of the other session are listed as comments.

-- step 1: run in S2
-- step 2
START TRANSACTION;
-- step 3
INSERT INTO Booking (show_id, customer, seats) VALUES (2, 'Neel', 3);
-- step 4
INSERT INTO Booking (show_id, customer, seats) VALUES (2, 'Neel', 2);
-- step 5
SELECT customer, seats FROM Booking;
-- step 6
SELECT show_id, available FROM Show_Seats WHERE show_id = 2;
-- step 7: run in S2
-- step 8: run in S2
-- step 9: run in S3
-- step 10: run in S3
