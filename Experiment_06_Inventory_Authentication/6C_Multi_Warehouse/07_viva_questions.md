# Viva questions - 6C Multi-warehouse

**Q1. Why a composite PK on Wh_Stock?** A product can be in many warehouses and a warehouse holds many products; (wh_id, prod_id) identifies one stock row.

**Q2. Why must a transfer be one transaction?** Decrease at the source and increase at the destination must both happen or neither; otherwise stock is lost or created. Rollback on shortage restores the source.

**Q3. How does the procedure handle a destination that never stocked the product?** `INSERT ... ON DUPLICATE KEY UPDATE qty = qty + p_qty` inserts a new row or adds to the existing one.

**Q4. Why `SELECT ... FOR UPDATE` on the source row?** Prevents two concurrent transfers from both seeing enough stock and driving it below zero.

**Q5. What happened to the monitor transfer and what is left behind?** ERROR 'Shortage...'; the handler rolled back: no stock change, no voucher, no log.

**Q6. How is every transfer logged?** AFTER INSERT trigger on the voucher table `Stock_Transfer` copies it to `Transfer_Log` with `USER()` (the connecting account; inside a trigger `CURRENT_USER()` would return the definer) and the time.

**Q7. How does reorder_list handle products with no warehouse stock?** LEFT JOIN + `COALESCE(SUM(qty),0)`; total 0 <= reorder level so they appear (P4, P5).

**Q8. Why can purchase_officer query the view but not Product?** Views are SQL SECURITY DEFINER by default; the check uses the definer's rights on base tables, so the officer only needs SELECT on the view.

**Q9. What does `GRANT EXECUTE ON PROCEDURE` allow?** Calling the routine; the routine runs with its definer's rights, so wh_manager needs no INSERT right on Stock_Transfer/Transfer_Log.

**Q10. What error after REVOKE EXECUTE?** ERROR 1370 (42000): execute command denied.

**Q11 (follow-up). Definer vs invoker rights?** `SQL SECURITY DEFINER` (default) vs `INVOKER`: with INVOKER the caller's privileges are checked inside the routine.

**Q12 (follow-up). Where would deadlocks come from in this design?** Two opposite transfers (W1->W2 and W2->W1) locking rows in opposite order; lock the two rows in a fixed order (e.g. by wh_id) or retry on 1213.
