-- 4D Ticket booking - Task 11: script for session S3 (open a separate terminal: mysql -u root -p ticket_4d)
-- Execute the steps in the order of the step numbers; steps of the other session are listed as comments.

-- step 1: run in S2
-- step 2: run in S1
-- step 3: run in S1
-- step 4: run in S1
-- step 5: run in S1
-- step 6: run in S1
-- step 7: run in S2
-- step 8: run in S2
-- step 9
SELECT COUNT(*) AS bookings FROM Booking;
-- step 10
SELECT show_id, available FROM Show_Seats WHERE show_id = 2;
