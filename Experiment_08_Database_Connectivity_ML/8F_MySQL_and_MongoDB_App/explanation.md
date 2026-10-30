# Explanation - 8F_MySQL_and_MongoDB_App

| Task | What happens |
|---|---|
| 1 | connect to both and print a success message each |
| 2 | 3 tables (category, product, review) with PK/FK/CHECK and the data of the PDF |
| 3 | JOIN product-category |
| 4 | relational -> document: category embedded as `{id,name}`, reviews as an array |
| 5 | `insert_many` |
| 6 | counts compared |
| 7 | SQL `WHERE`+`JOIN` vs `find({'category.name':..., price:{$gt:1000}})` - same ids |
| 8 | `GROUP BY` vs `$unwind`+`$group`+`$avg` - same averages |
| 9 | update price in MySQL, sync to Mongo with `update_one` |
| 10 | delete product 105: first attempt fails on the review FK (reported), then reviews + product in one transaction; Mongo `delete_one` |
| 11 | `time.perf_counter()` median of 200 runs |
| 12 | Node script printing both counts |
