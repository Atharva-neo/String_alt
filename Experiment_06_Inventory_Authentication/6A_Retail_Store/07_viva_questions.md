# Viva questions - 6A Retail store roles

**Q1. How is stock kept correct automatically?** AFTER INSERT trigger on Purchase adds, BEFORE INSERT trigger on Sale blocks overselling, AFTER INSERT trigger on Sale subtracts.

**Q2. Why is the over-sale check a BEFORE trigger?** It must reject the row before it exists; the CHECK (qty_in_stock >= 0) would also catch it, but later and with a less helpful error.

**Q3. Why did the sale of 10 monitors fail?** Stock was 8; trigger raised 'Insufficient stock for this sale' (error 1644) and no row/stock change happened.

**Q4. What is the reorder alert query?** `qty_in_stock <= reorder_level` joined to Supplier for name and phone.

**Q5. What is a role and why use it?** A named privilege set. Privileges are managed once per role (admin, store_manager, clerk) and given to many users; revoking from the role affects all of them.

**Q6. Why must you `SET DEFAULT ROLE`?** In MySQL a granted role is not active at login unless it is a default role (or the user runs `SET ROLE`). Without it the user would have no privileges.

**Q7. What does `UPDATE (price)` mean?** A column-level privilege: the user may change only `price`. Updating `qty_in_stock` fails with ERROR 1143.

**Q8. How can a clerk insert a sale and still change stock without UPDATE on Product?** Triggers execute with the definer's privileges, not the caller's.

**Q9. What error shows when clerk1 runs UPDATE Product?** ERROR 1142 (42000): UPDATE command denied to user 'clerk1'@'localhost' for table 'product'.

**Q10. After `REVOKE INSERT ON Sale FROM clerk` what can clerk1 still do?** SELECT on Product; INSERT on Sale now fails with 1142.

**Q11 (follow-up). `GRANT ALL` vs `GRANT ALL ... WITH GRANT OPTION`?** The option lets the grantee pass the privileges on; not given to `admin` here.

**Q12 (follow-up). Why is Stock a view and not a table?** The quantity already lives in Product; a second copy would have to be kept in sync (redundancy / update anomaly). A view gives the Stock interface without duplication.
