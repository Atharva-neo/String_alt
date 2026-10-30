# Viva questions - 3B Order_Details

**Q1. Primary key of Order_Details?** {OrderID, ProductID}; one order has many products and one product is in many orders.

**Q2. Which FDs are partial, which transitive?** Partial: OrderID -> OrderDate, CustID; ProductID -> ProductName, UnitPrice. Transitive: OrderID -> CustID -> CustName, CustCity. Full: {OrderID, ProductID} -> Qty.

**Q3. Why is the relation in 1NF but not 2NF?** Values are atomic, but non-prime attributes depend on part of the composite key.

**Q4. Why can a table with a single-attribute key never violate 2NF?** A partial dependency needs a proper subset of the key; a single attribute has none.

**Q5. How do you know the 3NF decomposition is lossless?** Each join is on a key of one participant (CustID for Customer, OrderID for Orders, ProductID for Product).

**Q6. Is the decomposition dependency preserving?** Yes, every FD is entirely inside one table.

**Q7. How much work is the city change now?** One row in Customer (3 rows in the old design, Task 12).

**Q8. What happens if the Customer insert is skipped?** `Orders` insert fails with FK error 1452; the schema enforces the insertion order.

**Q9. Is Qty stored in Order_Item or Orders and why?** Order_Item: it depends on the pair (order, product).

**Q10. How can the original wide table still be produced?** A view joining the four tables (ADV 6) - normalise for storage, denormalise for reporting.

**Q11 (follow-up). Would UnitPrice stay in Product in a real shop?** Real systems copy the price into Order_Item to freeze historical prices; that is deliberate, documented redundancy.

**Q12 (follow-up). Does 3NF guarantee no anomalies?** Not always; BCNF removes the remaining anomalies caused by prime attributes (see 3D).
