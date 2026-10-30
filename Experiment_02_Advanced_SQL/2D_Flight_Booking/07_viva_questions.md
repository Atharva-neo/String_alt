# Viva questions - 2D Flight Booking

**Q1. How do you find flights with no bookings?** `LEFT JOIN Booking ... WHERE b.booking_id IS NULL` (or NOT EXISTS / NOT IN). 6E404 is the answer.

**Q2. Why must the NULL test be on a Booking column?** A match produces a non-NULL booking id; NULL means no match. Testing a Flight column would never be NULL.

**Q3. How is occupancy computed and why LEFT JOIN?** `COUNT(b.booking_id) / seats * 100`; COUNT of a right-side column gives 0 for unmatched flights, INNER JOIN would drop them.

**Q4. Why did Task 6 return only Arjun?** The correlated subquery averages fares of the same flight. AI101: both 6500, none above; 6E202: average 3300, Arjun's 3400 is above; UK303 has a single fare.

**Q5. How do you find "IndiGo but never Air India" passengers?** EXISTS for IndiGo AND NOT EXISTS for Air India. Rajesh has both, so he is excluded.

**Q6. HAVING vs WHERE in Task 12?** Revenue is SUM(fare), a group value, so HAVING.

**Q7. How does the pune_departures view help security?** It exposes only Pune-bound rows and chosen columns; users get SELECT on the view, not the tables.

**Q8. Is `Booking` in 3NF?** Yes: non-key columns (travel_date, fare) depend on booking_id only; passenger/flight details are in their own tables.

**Q9. COUNT(DISTINCT x) vs COUNT(x)?** DISTINCT counts unique non-NULL values.

**Q10. Why use CONCAT for the route?** To present two columns as one label; Oracle uses `||`.

**Q11 (follow-up). Compute revenue per airline for November only.** Add `WHERE travel_date BETWEEN '2026-11-01' AND '2026-11-30'` before GROUP BY.

**Q12 (follow-up). What is a self-contained alternative to the double NOT EXISTS in ADV 3?** Compare `COUNT(DISTINCT flight_no)` of the passenger's Pune flights with the number of Pune flights.
