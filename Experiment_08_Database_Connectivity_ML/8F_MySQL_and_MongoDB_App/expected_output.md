# Expected output - Experiment_08_Database_Connectivity_ML / 8F_MySQL_and_MongoDB_App

> **MongoDB part produced with the in-memory `mongomock` emulation (USE_MOCK_MONGO=1) - no MongoDB server was available.** MySQL parts, if any, ran against a real MySQL 8.0 server. Re-run without `--mock` on a machine with MongoDB for a real transcript. Date: 2026-10-30. Values such as timings or dates differ between runs.

```text
### Task 1 - Connect to MySQL (mysql-connector-python) and MongoDB (pymongo)
MySQL connected, server 8.0.46
MongoDB connected, databases visible: ok

### Task 2 - Create the three MySQL tables with keys and constraints and insert the data
category : 3 rows
product  : 5 rows
review   : 5 rows

### Task 3 - Read each product with its category name using a JOIN
   {'prod_id': 101, 'name': 'Headphones', 'category': 'Electronics', 'price': Decimal('1500.00'), 'stock': 20}
   {'prod_id': 102, 'name': 'Power Bank', 'category': 'Electronics', 'price': Decimal('1200.00'), 'stock': 35}
   {'prod_id': 103, 'name': 'Notebook', 'category': 'Stationery', 'price': Decimal('60.00'), 'stock': 300}
   {'prod_id': 104, 'name': 'Desk Lamp', 'category': 'Home', 'price': Decimal('900.00'), 'stock': 15}
   {'prod_id': 105, 'name': 'USB Cable', 'category': 'Electronics', 'price': Decimal('250.00'), 'stock': 100}

### Task 4 - Convert every product into the MongoDB document shape (embedded category + reviews)
{'_id': 101, 'name': 'Headphones', 'price': 1500.0, 'stock': 20, 'category': {'id': 1, 'name': 'Electronics'}, 'reviews': [{'user': 'Riya', 'rating': 5, 'comment': 'Great sound'}, {'user': 'Amit', 'rating': 4, 'comment': 'Good value'}]}

### Task 5 - Insert the documents with insert_many
inserted: 5

### Task 6 - Verify that the product count is the same in MySQL and MongoDB
MySQL 5 | MongoDB 5 | equal: True

### Task 7 - Electronics products priced above 1000 in both databases
MySQL (WHERE + JOIN): [101, 102] 
MongoDB (find)       : [101, 102] 
results match: True

### Task 8 - Average rating per product in both (GROUP BY vs $unwind + $group)
MySQL  : {101: 4.5, 102: 3.0, 104: 4.0, 105: 2.0} 
MongoDB: {101: 4.5, 102: 3.0, 104: 4.0, 105: 2.0} 
match: True

### Task 9 - Update the price of product 102 to 1100 in MySQL and sync it to MongoDB (update_one)
MySQL price: 1100.00 | MongoDB price: 1100.0

### Task 10 - Delete product 105 from both databases inside try/except so a failure in either is reported
MySQL delete failed (as expected, reviews reference the product): errno 1451: Cannot delete or update a parent row: a foreign key constraint fails (`catalog_8f`.`review`, CONSTRAINT `fk_rev_prod` FOREIGN KEY (`prod_id`) REFERENCES `product` (`prod_id`))
MySQL: reviews + product 105 deleted
MongoDB: deleted 1 document
counts now - MySQL: 4 MongoDB: 4

### Task 11 - Time the query of Task 7 on both databases with time.perf_counter()
MySQL   : 1.375 ms (median of 200 runs)
MongoDB : 0.194 ms (median of 200 runs)
Note: with 4 rows both are dominated by network/driver overhead; the comparison only becomes meaningful on large data with indexes.

### Task 12 - Node.js script with mysql2 and mongodb that prints the product count of each database
Run:  node node_count.js   (see this folder; output recorded in node_count_output.md)
```
