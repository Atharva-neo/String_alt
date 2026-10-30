# Viva questions - 2B Sales

**Q1. How is the amount computed?** `qty * price` after joining Orders to Product; amount is derived, so it is not stored (avoids redundancy).

**Q2. Why LEFT JOIN in Task 2?** To list City Bazaar with total 0; INNER JOIN would drop customers with no orders.

**Q3. NOT EXISTS vs NOT IN?** Both express "not present". NOT IN returns no rows if the subquery yields any NULL (ADV 4); NOT EXISTS is NULL-safe and usually preferred.

**Q4. Why HAVING in the month-wise query?** The condition is on SUM(...) (a group value); WHERE cannot use aggregates.

**Q5. How do you get the top 3?** ORDER BY total DESC LIMIT 3. Ties at the boundary are cut arbitrarily; RANK() <= 3 includes ties.

**Q6. Explain the "every product" query (Task 9).** Division: customer c qualifies if there is no product that Ganesh ordered that c has not ordered (NOT EXISTS inside NOT EXISTS).

**Q7. Why is the Task 9 result only Ganesh himself?** No other customer ordered all of P1, P2, P3; when Ganesh is excluded the result is empty.

**Q8. Can you update a view that joins three tables?** Join views are updatable only for columns of a single base table; aggregating views are not updatable.

**Q9. What is the average order amount and how was it used?** 152700/6 = 25450; used in a scalar subquery in WHERE.

**Q10. Difference between COUNT(*) and COUNT(col)?** COUNT(*) counts rows, COUNT(col) skips NULLs.

**Q11 (follow-up). Month grouping without DATE_FORMAT?** `GROUP BY YEAR(order_date), MONTH(order_date)`; Oracle: `TO_CHAR(order_date,'YYYY-MM')`.

**Q12 (follow-up). How to show sales of the last 30 days?** `WHERE order_date >= CURRENT_DATE - INTERVAL 30 DAY`.
