# Viva questions - 1D Online Shop

**Q1. Why is `Order_Item` required?** One order has many products and one product is in many orders (M:N). Order_Item resolves it and stores `qty`, an attribute of the relationship.

**Q2. Why composite PK (order_id, prod_id)?** It identifies an order line and forbids the same product twice in the same order.

**Q3. Which constraint rejects qty = 0?** `chk_item_qty CHECK (qty > 0)`, error 3819.

**Q4. How did you reduce stock by the ordered quantity in one statement?** UPDATE ... JOIN (SELECT prod_id, SUM(qty) ... GROUP BY prod_id) ... SET stock = stock - ordered. Without the subquery a product ordered twice would only be reduced once.

**Q5. Why did deleting a customer need CASCADE on two FKs?** Customer -> Orders -> Order_Item; deleting the customer cascades to Orders, whose deletion must again cascade to Order_Item, otherwise the second FK blocks it.

**Q6. What data was removed by the cascade?** Sagar (cust 1), orders 1001 and 1003, and three Order_Item rows (P1, P2, P4). Stock changes made in Task 6 are *not* reverted.

**Q7. What is a role?** A named set of privileges. Grant privileges to the role once, grant the role to many users; revoke from the role to change them all.

**Q8. Why SET DEFAULT ROLE?** A granted role is not active automatically in MySQL; without a default role (or `SET ROLE`) the user would log in with no role privileges.

**Q9. Why DEFAULT 0 plus CHECK on discount?** DEFAULT supplies a value for old and new rows, CHECK restricts it to 0..50.

**Q10. Which statement shows constraint definitions?** `SHOW CREATE TABLE`, or query `information_schema.check_constraints` / `table_constraints`.

**Q11 (follow-up). Can stock be driven negative by an UPDATE?** No; CHECK also applies to UPDATE (ADV 5).

**Q12 (follow-up). Why does a hard-coded price in Order_Item sometimes exist in real shops?** To freeze the sale price; here price comes from Product so history changes when price changes (design trade-off).
