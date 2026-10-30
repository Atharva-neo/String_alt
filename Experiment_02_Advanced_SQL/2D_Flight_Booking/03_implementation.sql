-- Experiment 2D - Flight booking : 12 tasks
/* @CONCEPTS
* LEFT JOIN ... `WHERE right.key IS NULL` is the classic anti-join (rows with no match).
* Occupancy = bookings / seats x 100 (one booking = one seat in this data set).
* Correlated subquery with AVG on the same flight finds fares above the flight's own average.
* Passengers who did X **but never** Y: `EXISTS (X)` combined with `NOT EXISTS (Y)`.
*/

-- ### TASK 1: Passenger name, flight number, airline and travel date
SELECT p.pname, f.flight_no, f.airline, b.travel_date FROM Booking b JOIN Passenger p USING (pid) JOIN Flight f USING (flight_no) ORDER BY b.booking_id;

-- ### TASK 2: Passengers who booked more than 2 flights
-- Only Rajesh has 3 bookings.
SELECT p.pname, COUNT(*) AS bookings FROM Passenger p JOIN Booking b USING (pid) GROUP BY p.pid, p.pname HAVING COUNT(*) > 2;

-- ### TASK 3: Flights with no bookings (LEFT JOIN ... IS NULL)
-- 6E404 (Mumbai -> Delhi) has no matching Booking row.
SELECT f.flight_no, f.airline, f.source, f.destination FROM Flight f LEFT JOIN Booking b USING (flight_no) WHERE b.booking_id IS NULL;

-- ### TASK 4: Airline-wise number of bookings and total revenue
-- Air India 2 / 13000, IndiGo 2 / 6600, Vistara 1 / 4800.
SELECT f.airline, COUNT(*) AS bookings, SUM(b.fare) AS revenue FROM Booking b JOIN Flight f USING (flight_no) GROUP BY f.airline ORDER BY revenue DESC;

-- ### TASK 5: Occupancy percentage of each flight (bookings / seats x 100)
-- LEFT JOIN keeps 6E404 with 0%. Values are small because only five bookings exist in the sample.
SELECT f.flight_no, COUNT(b.booking_id) AS bookings, f.seats, ROUND(COUNT(b.booking_id) / f.seats * 100, 2) AS occupancy_pct
FROM Flight f LEFT JOIN Booking b USING (flight_no) GROUP BY f.flight_no, f.seats ORDER BY occupancy_pct DESC;

-- ### TASK 6: Passengers who paid a fare above the average fare of their flight
-- Correlated subquery: the average is taken over the bookings of the SAME flight. AI101 fares are 6500 and 6500 (average 6500), so the strict > returns no row for it;
-- UK303 has a single fare; 6E202 has 3200 (Rajesh) and 3400 (Arjun), average 3300, so only Arjun's 3400 is above it.
SELECT p.pname, b.flight_no, b.fare FROM Booking b JOIN Passenger p USING (pid)
WHERE b.fare > (SELECT AVG(x.fare) FROM Booking x WHERE x.flight_no = b.flight_no);

-- ### TASK 7: Flight with the highest revenue
-- AI101 earns 6500 + 6500 = 13000.
SELECT f.flight_no, f.airline, SUM(b.fare) AS revenue FROM Flight f JOIN Booking b USING (flight_no) GROUP BY f.flight_no, f.airline ORDER BY revenue DESC LIMIT 1;

-- ### TASK 8: Passengers who travelled with IndiGo but never with Air India
-- Rajesh flew IndiGo and Air India, so he is excluded; Arjun flew only IndiGo.
SELECT p.pname FROM Passenger p
WHERE EXISTS (SELECT 1 FROM Booking b JOIN Flight f USING (flight_no) WHERE b.pid = p.pid AND f.airline = 'IndiGo')
AND NOT EXISTS (SELECT 1 FROM Booking b JOIN Flight f USING (flight_no) WHERE b.pid = p.pid AND f.airline = 'Air India');

-- ### TASK 9: Route-wise (source -> destination) average fare
SELECT CONCAT(f.source, ' -> ', f.destination) AS route, ROUND(AVG(b.fare),2) AS avg_fare FROM Booking b JOIN Flight f USING (flight_no) GROUP BY f.source, f.destination;

-- ### TASK 10: Passengers aged below 30 and their bookings
-- LEFT JOIN so that Mitali (22, no booking) still appears with NULL booking columns.
SELECT p.pname, p.age, b.booking_id, b.flight_no, b.fare FROM Passenger p LEFT JOIN Booking b USING (pid) WHERE p.age < 30;

-- ### TASK 11: View pune_departures; list passengers flying from Pune
-- Flights leaving Pune: AI101 and UK303; Rajesh (both) and Sonal (AI101).
CREATE VIEW pune_departures AS SELECT b.booking_id, p.pname, f.flight_no, f.destination, b.travel_date
FROM Booking b JOIN Passenger p USING (pid) JOIN Flight f USING (flight_no) WHERE f.source = 'Pune';
SELECT * FROM pune_departures;
SELECT DISTINCT pname FROM pune_departures;

-- ### TASK 12: Airlines whose total revenue is greater than 5,000
-- GROUP BY airline HAVING SUM(fare) > 5000: Air India 13000 and IndiGo 6600; Vistara (4800) is excluded.
SELECT f.airline, SUM(b.fare) AS revenue FROM Booking b JOIN Flight f USING (flight_no) GROUP BY f.airline HAVING SUM(b.fare) > 5000;
