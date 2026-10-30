-- Experiment 2D - additional examiner-style queries
USE flight_2d;

-- ### ADV 1: Busiest route by number of bookings
SELECT f.source, f.destination, COUNT(*) AS bookings FROM Booking b JOIN Flight f USING (flight_no) GROUP BY f.source, f.destination ORDER BY bookings DESC LIMIT 1;

-- ### ADV 2: Passengers who never booked
SELECT p.pname FROM Passenger p WHERE NOT EXISTS (SELECT 1 FROM Booking b WHERE b.pid = p.pid);

-- ### ADV 3: Passengers who flew on every airline they could (flights from Pune)
-- Division: passengers having a booking on every flight departing from Pune. Only Rajesh booked both AI101 and UK303.
SELECT p.pname FROM Passenger p WHERE NOT EXISTS (
  SELECT 1 FROM Flight f WHERE f.source = 'Pune' AND NOT EXISTS (SELECT 1 FROM Booking b WHERE b.pid = p.pid AND b.flight_no = f.flight_no));

-- ### ADV 4: Fare difference of each booking from the passenger's own average
SELECT p.pname, b.flight_no, b.fare, ROUND(b.fare - AVG(b.fare) OVER (PARTITION BY b.pid), 2) AS diff_from_own_avg FROM Booking b JOIN Passenger p USING (pid);

-- ### ADV 5: Booking for a flight that does not exist
-- Error 1452.
INSERT INTO Booking VALUES (6, 4, 'XX999', '2026-12-01', 5000);

-- ### ADV 6: Booking with zero fare
-- Error 3819 (chk_b_fare).
INSERT INTO Booking VALUES (7, 4, 'AI101', '2026-12-01', 0);
