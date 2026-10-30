# Expected output - Experiment_07_MongoDB / 7B_Ecommerce

> **How this output was produced.** No MongoDB server was available, so the scripts were executed by `tools/mongosh_shim.js`, an in-memory emulation of the mongosh API built on the `mingo` library (query/aggregation/update operators are evaluated by mingo; `explain()` plans are *simulated*). The logic and results are therefore verified, but this is **not** a transcript of a real MongoDB 7 server - re-run with `python tools/run_mongo.py --real <folder>` (or the mongosh commands in README.md) to produce a real transcript. ObjectIds are deterministic placeholders. Run date: 2026-10-30.

## `schema.js`

```text
### Task 1 - Create collections products and orders (validated)
collections: [ 'orders', 'products' ]

### Task 1 - Negative tests
qty 0 -> code 121: Document failed validation
unknown category -> code 121: Document failed validation
```

## `insert_data.js`

```text
### Task 1 - Insert products and orders
products: 4  orders: 3
{ _id: 'P1', name: 'Laptop', category: 'Electronics', price: 55000, stock: 10 }
{ _id: 'P2', name: 'Mouse', category: 'Electronics', price: 500, stock: 100 }
{ _id: 'P3', name: 'Notebook', category: 'Stationery', price: 60, stock: 500 }
{ _id: 'P4', name: 'Desk Lamp', category: 'Home', price: 1200, stock: 25 }
{
  _id: 1001,
  customer: 'Sagar',
  date: ISODate('2026-10-02T00:00:00.000Z'),
  items: [ { prod_id: 'P1', qty: 1 }, { prod_id: 'P2', qty: 2 } ]
}
{
  _id: 1002,
  customer: 'Meera',
  date: ISODate('2026-10-05T00:00:00.000Z'),
  items: [ { prod_id: 'P3', qty: 10 } ]
}
{
  _id: 1003,
  customer: 'Sagar',
  date: ISODate('2026-10-09T00:00:00.000Z'),
  items: [ { prod_id: 'P4', qty: 1 } ]
}
```

## `queries.js`

```text
### Task 2 - Products with price between 400 and 2000 ($gte, $lte)
{ name: 'Mouse', price: 500 }
{ name: 'Desk Lamp', price: 1200 }

### Task 3 - Products in Electronics or Home: $in and the equivalent $or
{ name: 'Laptop', category: 'Electronics' }
{ name: 'Mouse', category: 'Electronics' }
{ name: 'Desk Lamp', category: 'Home' }
-- same result with $or:
{ name: 'Laptop', category: 'Electronics' }
{ name: 'Mouse', category: 'Electronics' }
{ name: 'Desk Lamp', category: 'Home' }

### Task 4 - Product names in descending order of price, top 2 only
{ name: 'Laptop', price: 55000 }
{ name: 'Desk Lamp', price: 1200 }
```

## `aggregation.js`

```text
### Task 5 - Join orders with products: customer, product name, qty and amount
{ customer: 'Sagar', amount: 55000, order: 1001, product: 'Laptop', qty: 1 }
{ customer: 'Sagar', amount: 1000, order: 1001, product: 'Mouse', qty: 2 }
{ customer: 'Meera', amount: 600, order: 1002, product: 'Notebook', qty: 10 }
{ customer: 'Sagar', amount: 1200, order: 1003, product: 'Desk Lamp', qty: 1 }

### Task 6 - Total amount of each order
{ _id: 1001, customer: 'Sagar', total: 56000 }
{ _id: 1002, customer: 'Meera', total: 600 }
{ _id: 1003, customer: 'Sagar', total: 1200 }

### Task 7 - Category-wise revenue
{ _id: 'Electronics', revenue: 56000 }
{ _id: 'Home', revenue: 1200 }
{ _id: 'Stationery', revenue: 600 }

### Task 8 - Customer with the highest total spending
{ _id: 'Sagar', spent: 57200 }

### Task 9 - Products never ordered ($lookup into orders, keep products with an empty match)
with the PDF data: []  (every product was ordered at least once)
after adding a temporary product P5: [{"_id":"P5","name":"USB Cable"}]
temporary product removed again: 4 products
```

## `indexes.js`

```text
### Task 10 - Electronics products priced above 400: before the index
{ stage: 'COLLSCAN', nReturned: 2, totalKeysExamined: 0, totalDocsExamined: 4 }

### Task 10 - Create the compound index and run the query again
created: category_1_price_1
{ stage: 'IXSCAN', nReturned: 2, totalKeysExamined: 2, totalDocsExamined: 2 }
-- COLLSCAN reads every document (4); IXSCAN reads only index entries of category 'Electronics' with price > 400 (2) and fetches just those documents.
{ v: 2, key: { _id: 1 }, name: '_id_' }
{ v: 2, key: { category: 1, price: 1 }, name: 'category_1_price_1' }
```

## `crud.js`

```text
### Task 11 - Reduce stock for each ordered item with updateOne
order 1001: P1 -1  (modifiedCount 1)
order 1001: P2 -2  (modifiedCount 1)
order 1002: P3 -10  (modifiedCount 1)
order 1003: P4 -1  (modifiedCount 1)
{ _id: 'P1', name: 'Laptop', stock: 9 }
{ _id: 'P2', name: 'Mouse', stock: 98 }
{ _id: 'P3', name: 'Notebook', stock: 490 }
{ _id: 'P4', name: 'Desk Lamp', stock: 24 }
-- negative test: the validator keeps stock >= 0
code 121: Document failed validation

### Task 12 - Delete orders older than 2026-10-05 and drop the index
{ acknowledged: true, deletedCount: 1 }
{ _id: 1002, customer: 'Meera', date: ISODate('2026-10-05T00:00:00.000Z') }
{ _id: 1003, customer: 'Sagar', date: ISODate('2026-10-09T00:00:00.000Z') }
indexes now: _id_
```
