# Expected output - Experiment_02_Advanced_SQL / 2D_Flight_Booking

> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order (`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), on **MySQL 8.0.46** on **2026-10-30** via `tools/run_sql.py`. Nothing here is hand-typed.  
> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  
> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.


## Core tasks (from the PDF)

### Task 1 - Passenger name, flight number, airline and travel date

```sql
SELECT p.pname, f.flight_no, f.airline, b.travel_date FROM Booking b JOIN Passenger p USING (pid) JOIN Flight f USING (flight_no) ORDER BY b.booking_id;
```

**Output**

```text
SELECT p.pname, f.flight_no, f.airline, b.travel_date FROM Booking b JOIN Passenger p USING (pid) JOIN Flight f USING (flight_no) ORDER BY b.booking_id

+--------+-----------+-----------+-------------+
| pname  | flight_no | airline   | travel_date |
+--------+-----------+-----------+-------------+
| Rajesh | AI101     | Air India | 2026-11-01  |
| Rajesh | 6E202     | IndiGo    | 2026-11-05  |
| Rajesh | UK303     | Vistara   | 2026-11-10  |
| Sonal  | AI101     | Air India | 2026-11-01  |
| Arjun  | 6E202     | IndiGo    | 2026-11-05  |
+--------+-----------+-----------+-------------+
5 rows in set
```

### Task 2 - Passengers who booked more than 2 flights

```sql
SELECT p.pname, COUNT(*) AS bookings FROM Passenger p JOIN Booking b USING (pid) GROUP BY p.pid, p.pname HAVING COUNT(*) > 2;
```

**Output**

```text
SELECT p.pname, COUNT(*) AS bookings FROM Passenger p JOIN Booking b USING (pid) GROUP BY p.pid, p.pname HAVING COUNT(*) > 2

+--------+----------+
| pname  | bookings |
+--------+----------+
| Rajesh |        3 |
+--------+----------+
1 row in set
```

**Why this output is correct:** Only Rajesh has 3 bookings.

### Task 3 - Flights with no bookings (LEFT JOIN ... IS NULL)

```sql
SELECT f.flight_no, f.airline, f.source, f.destination FROM Flight f LEFT JOIN Booking b USING (flight_no) WHERE b.booking_id IS NULL;
```

**Output**

```text
SELECT f.flight_no, f.airline, f.source, f.destination FROM Flight f LEFT JOIN Booking b USING (flight_no) WHERE b.booking_id IS NULL

+-----------+---------+--------+-------------+
| flight_no | airline | source | destination |
+-----------+---------+--------+-------------+
| 6E404     | IndiGo  | Mumbai | Delhi       |
+-----------+---------+--------+-------------+
1 row in set
```

**Why this output is correct:** 6E404 (Mumbai -> Delhi) has no matching Booking row.

### Task 4 - Airline-wise number of bookings and total revenue

```sql
SELECT f.airline, COUNT(*) AS bookings, SUM(b.fare) AS revenue FROM Booking b JOIN Flight f USING (flight_no) GROUP BY f.airline ORDER BY revenue DESC;
```

**Output**

```text
SELECT f.airline, COUNT(*) AS bookings, SUM(b.fare) AS revenue FROM Booking b JOIN Flight f USING (flight_no) GROUP BY f.airline ORDER BY revenue DESC

+-----------+----------+---------+
| airline   | bookings | revenue |
+-----------+----------+---------+
| Air India |        2 |   13000 |
| IndiGo    |        2 |    6600 |
| Vistara   |        1 |    4800 |
+-----------+----------+---------+
3 rows in set
```

**Why this output is correct:** Air India 2 / 13000, IndiGo 2 / 6600, Vistara 1 / 4800.

### Task 5 - Occupancy percentage of each flight (bookings / seats x 100)

```sql
SELECT f.flight_no, COUNT(b.booking_id) AS bookings, f.seats, ROUND(COUNT(b.booking_id) / f.seats * 100, 2) AS occupancy_pct
FROM Flight f LEFT JOIN Booking b USING (flight_no) GROUP BY f.flight_no, f.seats ORDER BY occupancy_pct DESC;
```

**Output**

```text
SELECT f.flight_no, COUNT(b.booking_id) AS bookings, f.seats, ROUND(COUNT(b.booking_id) / f.seats * 100, 2) AS occupancy_pct
FROM Flight f LEFT JOIN Booking b USING (flight_no) GROUP BY f.flight_no, f.seats ORDER BY occupancy_pct DESC

+-----------+----------+-------+---------------+
| flight_no | bookings | seats | occupancy_pct |
+-----------+----------+-------+---------------+
| 6E202     |        2 |   150 |          1.33 |
| AI101     |        2 |   180 |          1.11 |
| UK303     |        1 |   160 |          0.63 |
| 6E404     |        0 |   180 |          0.00 |
+-----------+----------+-------+---------------+
4 rows in set
```

**Why this output is correct:** LEFT JOIN keeps 6E404 with 0%. Values are small because only five bookings exist in the sample.

### Task 6 - Passengers who paid a fare above the average fare of their flight

```sql
SELECT p.pname, b.flight_no, b.fare FROM Booking b JOIN Passenger p USING (pid)
WHERE b.fare > (SELECT AVG(x.fare) FROM Booking x WHERE x.flight_no = b.flight_no);
```

**Output**

```text
SELECT p.pname, b.flight_no, b.fare FROM Booking b JOIN Passenger p USING (pid)
WHERE b.fare > (SELECT AVG(x.fare) FROM Booking x WHERE x.flight_no = b.flight_no)

+-------+-----------+------+
| pname | flight_no | fare |
+-------+-----------+------+
| Arjun | 6E202     | 3400 |
+-------+-----------+------+
1 row in set
```

**Why this output is correct:** Correlated subquery: the average is taken over the bookings of the SAME flight. AI101 fares are 6500 and 6500 (average 6500), so the strict > returns no row for it; UK303 has a single fare; 6E202 has 3200 (Rajesh) and 3400 (Arjun), average 3300, so only Arjun's 3400 is above it.

### Task 7 - Flight with the highest revenue

```sql
SELECT f.flight_no, f.airline, SUM(b.fare) AS revenue FROM Flight f JOIN Booking b USING (flight_no) GROUP BY f.flight_no, f.airline ORDER BY revenue DESC LIMIT 1;
```

**Output**

```text
SELECT f.flight_no, f.airline, SUM(b.fare) AS revenue FROM Flight f JOIN Booking b USING (flight_no) GROUP BY f.flight_no, f.airline ORDER BY revenue DESC LIMIT 1

+-----------+-----------+---------+
| flight_no | airline   | revenue |
+-----------+-----------+---------+
| AI101     | Air India |   13000 |
+-----------+-----------+---------+
1 row in set
```

**Why this output is correct:** AI101 earns 6500 + 6500 = 13000.

### Task 8 - Passengers who travelled with IndiGo but never with Air India

```sql
SELECT p.pname FROM Passenger p
WHERE EXISTS (SELECT 1 FROM Booking b JOIN Flight f USING (flight_no) WHERE b.pid = p.pid AND f.airline = 'IndiGo')
AND NOT EXISTS (SELECT 1 FROM Booking b JOIN Flight f USING (flight_no) WHERE b.pid = p.pid AND f.airline = 'Air India');
```

**Output**

```text
SELECT p.pname FROM Passenger p
WHERE EXISTS (SELECT 1 FROM Booking b JOIN Flight f USING (flight_no) WHERE b.pid = p.pid AND f.airline = 'IndiGo')
AND NOT EXISTS (SELECT 1 FROM Booking b JOIN Flight f USING (flight_no) WHERE b.pid = p.pid AND f.airline = 'Air India')

+-------+
| pname |
+-------+
| Arjun |
+-------+
1 row in set
```

**Why this output is correct:** Rajesh flew IndiGo and Air India, so he is excluded; Arjun flew only IndiGo.

### Task 9 - Route-wise (source -> destination) average fare

```sql
SELECT CONCAT(f.source, ' -> ', f.destination) AS route, ROUND(AVG(b.fare),2) AS avg_fare FROM Booking b JOIN Flight f USING (flight_no) GROUP BY f.source, f.destination;
```

**Output**

```text
SELECT CONCAT(f.source, ' -> ', f.destination) AS route, ROUND(AVG(b.fare),2) AS avg_fare FROM Booking b JOIN Flight f USING (flight_no) GROUP BY f.source, f.destination

+-------------------+----------+
| route             | avg_fare |
+-------------------+----------+
| Pune -> Delhi     |  6500.00 |
| Mumbai -> Goa     |  3300.00 |
| Pune -> Bengaluru |  4800.00 |
+-------------------+----------+
3 rows in set
```

### Task 10 - Passengers aged below 30 and their bookings

```sql
SELECT p.pname, p.age, b.booking_id, b.flight_no, b.fare FROM Passenger p LEFT JOIN Booking b USING (pid) WHERE p.age < 30;
```

**Output**

```text
SELECT p.pname, p.age, b.booking_id, b.flight_no, b.fare FROM Passenger p LEFT JOIN Booking b USING (pid) WHERE p.age < 30

+--------+-----+------------+-----------+------+
| pname  | age | booking_id | flight_no | fare |
+--------+-----+------------+-----------+------+
| Sonal  |  29 |          4 | AI101     | 6500 |
| Mitali |  22 |       NULL | NULL      | NULL |
+--------+-----+------------+-----------+------+
2 rows in set
```

**Why this output is correct:** LEFT JOIN so that Mitali (22, no booking) still appears with NULL booking columns.

### Task 11 - View pune_departures; list passengers flying from Pune

```sql
CREATE VIEW pune_departures AS SELECT b.booking_id, p.pname, f.flight_no, f.destination, b.travel_date
FROM Booking b JOIN Passenger p USING (pid) JOIN Flight f USING (flight_no) WHERE f.source = 'Pune';
SELECT * FROM pune_departures;
SELECT DISTINCT pname FROM pune_departures;
```

**Output**

```text
CREATE VIEW pune_departures AS SELECT b.booking_id, p.pname, f.flight_no, f.destination, b.travel_date
FROM Booking b JOIN Passenger p USING (pid) JOIN Flight f USING (flight_no) WHERE f.source = 'Pune'

Query OK, 0 rows affected

SELECT * FROM pune_departures

+------------+--------+-----------+-------------+-------------+
| booking_id | pname  | flight_no | destination | travel_date |
+------------+--------+-----------+-------------+-------------+
|          1 | Rajesh | AI101     | Delhi       | 2026-11-01  |
|          3 | Rajesh | UK303     | Bengaluru   | 2026-11-10  |
|          4 | Sonal  | AI101     | Delhi       | 2026-11-01  |
+------------+--------+-----------+-------------+-------------+
3 rows in set

SELECT DISTINCT pname FROM pune_departures

+--------+
| pname  |
+--------+
| Rajesh |
| Sonal  |
+--------+
2 rows in set
```

**Why this output is correct:** Flights leaving Pune: AI101 and UK303; Rajesh (both) and Sonal (AI101).

### Task 12 - Airlines whose total revenue is greater than 5,000

```sql
SELECT f.airline, SUM(b.fare) AS revenue FROM Booking b JOIN Flight f USING (flight_no) GROUP BY f.airline HAVING SUM(b.fare) > 5000;
```

**Output**

```text
SELECT f.airline, SUM(b.fare) AS revenue FROM Booking b JOIN Flight f USING (flight_no) GROUP BY f.airline HAVING SUM(b.fare) > 5000

+-----------+---------+
| airline   | revenue |
+-----------+---------+
| Air India |   13000 |
| IndiGo    |    6600 |
+-----------+---------+
2 rows in set
```

**Why this output is correct:** GROUP BY airline HAVING SUM(fare) > 5000: Air India 13000 and IndiGo 6600; Vistara (4800) is excluded.


## Advanced / examiner-style queries

### Adv 1 - Busiest route by number of bookings

```sql
SELECT f.source, f.destination, COUNT(*) AS bookings FROM Booking b JOIN Flight f USING (flight_no) GROUP BY f.source, f.destination ORDER BY bookings DESC LIMIT 1;
```

**Output**

```text
SELECT f.source, f.destination, COUNT(*) AS bookings FROM Booking b JOIN Flight f USING (flight_no) GROUP BY f.source, f.destination ORDER BY bookings DESC LIMIT 1

+--------+-------------+----------+
| source | destination | bookings |
+--------+-------------+----------+
| Mumbai | Goa         |        2 |
+--------+-------------+----------+
1 row in set
```

### Adv 2 - Passengers who never booked

```sql
SELECT p.pname FROM Passenger p WHERE NOT EXISTS (SELECT 1 FROM Booking b WHERE b.pid = p.pid);
```

**Output**

```text
SELECT p.pname FROM Passenger p WHERE NOT EXISTS (SELECT 1 FROM Booking b WHERE b.pid = p.pid)

+--------+
| pname  |
+--------+
| Mitali |
+--------+
1 row in set
```

### Adv 3 - Passengers who flew on every airline they could (flights from Pune)

```sql
SELECT p.pname FROM Passenger p WHERE NOT EXISTS (
  SELECT 1 FROM Flight f WHERE f.source = 'Pune' AND NOT EXISTS (SELECT 1 FROM Booking b WHERE b.pid = p.pid AND b.flight_no = f.flight_no));
```

**Output**

```text
SELECT p.pname FROM Passenger p WHERE NOT EXISTS (
  SELECT 1 FROM Flight f WHERE f.source = 'Pune' AND NOT EXISTS (SELECT 1 FROM Booking b WHERE b.pid = p.pid AND b.flight_no = f.flight_no))

+--------+
| pname  |
+--------+
| Rajesh |
+--------+
1 row in set
```

**Why this output is correct:** Division: passengers having a booking on every flight departing from Pune. Only Rajesh booked both AI101 and UK303.

### Adv 4 - Fare difference of each booking from the passenger's own average

```sql
SELECT p.pname, b.flight_no, b.fare, ROUND(b.fare - AVG(b.fare) OVER (PARTITION BY b.pid), 2) AS diff_from_own_avg FROM Booking b JOIN Passenger p USING (pid);
```

**Output**

```text
SELECT p.pname, b.flight_no, b.fare, ROUND(b.fare - AVG(b.fare) OVER (PARTITION BY b.pid), 2) AS diff_from_own_avg FROM Booking b JOIN Passenger p USING (pid)

+--------+-----------+------+-------------------+
| pname  | flight_no | fare | diff_from_own_avg |
+--------+-----------+------+-------------------+
| Rajesh | AI101     | 6500 |           1666.67 |
| Rajesh | 6E202     | 3200 |          -1633.33 |
| Rajesh | UK303     | 4800 |            -33.33 |
| Sonal  | AI101     | 6500 |              0.00 |
| Arjun  | 6E202     | 3400 |              0.00 |
+--------+-----------+------+-------------------+
5 rows in set
```

### Adv 5 - Booking for a flight that does not exist

```sql
INSERT INTO Booking VALUES (6, 4, 'XX999', '2026-12-01', 5000);
```

**Output**

```text
INSERT INTO Booking VALUES (6, 4, 'XX999', '2026-12-01', 5000)

ERROR 1452 (23000) at line 1: Cannot add or update a child row: a foreign key constraint fails (`flight_2d`.`booking`, CONSTRAINT `fk_b_flight` FOREIGN KEY (`flight_no`) REFERENCES `flight` (`flight_no`))
```

**Why this output is correct:** Error 1452.

### Adv 6 - Booking with zero fare

```sql
INSERT INTO Booking VALUES (7, 4, 'AI101', '2026-12-01', 0);
```

**Output**

```text
INSERT INTO Booking VALUES (7, 4, 'AI101', '2026-12-01', 0)

ERROR 3819 (HY000) at line 1: Check constraint 'chk_b_fare' is violated.
```

**Why this output is correct:** Error 3819 (chk_b_fare).
