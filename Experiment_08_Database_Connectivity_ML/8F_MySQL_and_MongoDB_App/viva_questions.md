# Viva questions - 8F_MySQL_and_MongoDB_App

**Q1. Why embed reviews and category in the Mongo document?** They are read with the product and the category name rarely changes; one read replaces a join. Trade-off: renaming a category means updating many documents.

**Q2. How do you keep the two databases consistent?** Single writer + sync step (Task 9), or change data capture / outbox pattern; there is no distributed transaction between MySQL and MongoDB here.

**Q3. What failure mode does the try/except in Task 10 cover?** MySQL succeeds and Mongo fails (or the opposite) leaves the stores out of sync; the code reports each failure separately so it can be repaired.

**Q4. Why did the first MySQL delete fail?** Foreign key `review.prod_id` references the product (RESTRICT); delete children first or use ON DELETE CASCADE.

**Q5. Which database is faster in Task 11?** Not meaningful at 4 rows; depends on indexes, data size, caching and driver overhead.

**Q6. Why does the Node script use `execute()`?** mysql2 prepared statements send parameters separately (injection safe).

**Q7. SQL vs MongoDB average rating?** `GROUP BY prod_id` vs `$unwind` reviews then `$group` with `$avg`.
