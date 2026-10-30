# MASTER INDEX - checklist of every experiment, variation and task

Legend (the status is NOT "a file exists"; it says how the task was actually checked):

| Mark | Meaning |
|---|---|
| `[x]` | implemented **and executed against the real server/tool** it targets (MySQL 8.0.46, Python 3.14); output captured |
| `[e]` | implemented and executed only on an **emulator** (mongosh shim on `mingo`, `mongomock`, fake Node driver) - logic verified, real server **not** tested |
| `[~]` | implemented but **not executed** (needs a server that was not available: MongoDB replica set / Neo4j) |
| `[ ]` | not started (none) |

Environment used for verification: Windows 11, MySQL 8.0.46 (scratch instance), Python 3.14, Node 24. No MongoDB or Neo4j server was available.
Each variation below covers its tasks **1-12** (Neo4j: 1-10) as listed in the PDF unless a note says otherwise.


## Experiment 1 - SQL commands, ER modelling, integrity constraints (MySQL)

- [x] **1A Library** - tasks 1-12 - negatives: FK 1452, CHECK 3819, UNIQUE 1062, DCL denial 1142
- [x] **1B Bank** - tasks 1-12 - column privilege UPDATE(balance) denial 1143
- [x] **1C College** - tasks 1-12 - FK error then ON DELETE CASCADE
- [x] **1D Online Shop** - tasks 1-12 - two-level cascade, role sales_staff

## Experiment 2 - Advanced SQL

- [x] **2A Employee-Department** - tasks 1-12 - joins, correlated subquery, ALL, 2nd highest salary (nested MAX and DENSE_RANK), views
- [x] **2B Sales** - tasks 1-12 - relational division, month-wise HAVING, views
- [x] **2C University results** - tasks 1-12 - ALL/ANY, RANK, updatable join view + CHECK OPTION
- [x] **2D Flight booking** - tasks 1-12 - anti-join, occupancy %, view

## Experiment 3 - Normalization up to BCNF

- [x] **3A Student_Course** - tasks 1-12 - 1NF->BCNF derivation, closures, lossless join (SQL + chase); `00_derivation.md`, `fd_analysis.py`
- [x] **3B Order_Details** - tasks 1-12 - FD classification, anomalies, lossless + dependency preserving; `00_derivation.md`, `fd_analysis.py`
- [x] **3C Employee_Project** - tasks 1-12 - MVD / 4NF idea, checked on data; `00_derivation.md`, `fd_analysis.py`
- [x] **3D Teaching** - tasks 1-12 - 3NF but not BCNF; lost FD demonstrated; `00_derivation.md`, `fd_analysis.py`

## Experiment 4 - Triggers, procedures, transactions, ACID

- [x] **4A Bank transfer** - tasks 1-12 - task 10 (isolation) by `run_demo.py`; task 11 (durability) by a real forced server kill + restart, see `DURABILITY.md`
- [x] **4B Payroll** - tasks 1-12 - cursor, handlers, OUT parameters, function
- [x] **4C Library fines** - tasks 1-12 - SAVEPOINT, 3-book limit trigger
- [x] **4D Ticket booking** - tasks 1-12 - task 11 (killed session) by `run_demo.py` with `KILL`

## Experiment 5 - Concurrency control and recovery

- [x] **5A Lost update** - tasks 1-12 - two real sessions (S1/S2); `LOCK TABLES`, lock-wait timeout, precedence graph
- [x] **5B Isolation levels** - tasks 1-12 - anomaly x isolation matrix MEASURED with real sessions
- [x] **5C Deadlocks** - tasks 1-12 - real 1213 deadlocks (2 and 3 sessions), InnoDB status, retry procedure
- [x] **5D Log-based recovery** - tasks 1-12 - Python program; task 12 against real MySQL

## Experiment 6 - Inventory management, authentication, privileges

- [x] **6A Retail store roles** - tasks 1-12 - stock triggers, roles admin/store_manager/clerk
- [x] **6B Medical store** - tasks 1-12 - batches/expiry, column grants
- [x] **6C Multi-warehouse** - tasks 1-12 - transfer procedure, EXECUTE grants
- [x] **6D Login module** - tasks 1-12 - SHA-256, lock after 3 failures, least privilege

## Experiment 7 - MongoDB database operations

- [e] **7A Blog** - tasks 1-12 - $elemMatch, $push/$pull/$addToSet, $unwind/$group, indexes; run on `tools/mongosh_shim.js` (in-memory), explain() simulated
- [e] **7B E-commerce** - tasks 1-12 - $lookup joins, ESR compound index; run on `tools/mongosh_shim.js` (in-memory), explain() simulated
- [e] **7C Movie catalogue** - tasks 1-12 - $text index, $size, pipeline update; run on `tools/mongosh_shim.js` (in-memory), explain() simulated
- [e] **7D Employee directory** - tasks 1-12 - $all/$not/$nin, $rename, dot notation; run on `tools/mongosh_shim.js` (in-memory), explain() simulated

## Experiment 8 - Database connectivity (Python / Node.js), AI/ML datasets

- [e] **8A Titanic** - tasks 1-12 - PyMongo on mongomock; pandas + scikit-learn real
- [e] **8B House price** - tasks 1-12 - PyMongo on mongomock ($mul emulated); R2 real
- [e] **8C Review sentiment** - tasks 1-12 - PyMongo on mongomock ($text replaced by regex fallback); TF-IDF + Naive Bayes real
- [e] **8D Node.js REST API** - tasks 1-12 - all routes tested through `test_api.js` against an in-memory fake driver; `server.js` + curl on real MongoDB not run
- [x] **8E Python-MySQL student fees** - tasks 1-12 - real MySQL, includes injection explanation, procedure, transaction, error handling
- [e] **8F MySQL + MongoDB application** - tasks 1-12 - MySQL real, MongoDB mongomock; task 12 Node script: MySQL count real, MongoDB part failed for lack of a server (see `node_count_output.md`)

## Experiment 9 - Student records database with reports

- [e] **9A Attendance report** - tasks 1-12 - attendance %, defaulters via $lookup, unique compound index; run on the mongosh shim
- [e] **9B Result analysis** - tasks 1-12 - pass %, topper, $switch grades, $setWindowFields; run on the mongosh shim
- [e] **9C Report card** - tasks 1-12 - 4-collection join, SGPA, $out, CSV export; run on the mongosh shim
- [e] **9D Department and semester statistics** - tasks 1-12 - group by dept/semester/gender/city, $unset, $out backup; run on the mongosh shim

## Experiment 10 - Hospital management with real-time graphs

- [e] **10 database (tasks 1-10)** - tasks 1-10 - schema/validation, CRUD, history aggregation, unpaid bills, indexes - mongosh shim
- [e] **10 task 11 generator** - tasks 11 - `realtime/generator.py` insert logic exercised on mongomock
- [~] **10 task 11 change stream (`watcher.py`)** - tasks 11 - needs a replica set - not run (script refuses cleanly without one)
- [e] **10 task 12 dashboard (4 graphs)** - tasks 12 - renders and changes after an insert in a headless Streamlit test (polling mode)
- [~] **10 task 12 live refresh driven by change stream** - tasks 12 - implemented in `dashboard/live.py`; not run
- [~] **10 Neo4j graph tasks 1-10** - tasks 1-10 - Cypher not executed; expected answers cross-checked by `neo4j/verify_expected.py` (plain Python, executed)

## Other deliverables

- [x] `README.md` (installation, execution order, troubleshooting) - [x] `requirements.txt`, `package.json`, `.env.example`
- [x] `docs/` - SQL, MongoDB, Python references; normalization, ACID, concurrency notes; pooled viva questions
- [x] ER / structure diagrams (Mermaid) in every `06_explanation.md`, `explanation.md`; dependency diagrams in `00_derivation.md`
- [x] Negative tests with the real error text: duplicate PK, invalid FK, CHECK, insufficient stock, unauthorised update, invalid login, invalid MongoDB document

## Known deviations / assumptions (all stated in the files too)

1. PDF 4B Task 9: the tax slab assumes the stored salary is **monthly** (annual = 12 x salary).
2. PDF 5D: `<T2, start>` is placed immediately before `<checkpoint {T2}>` so that T2 is "active at the checkpoint".
3. PDF 6: `Stock` is a **view** over `Product` (the PDF's Product table already holds `qty_in_stock`).
4. PDF 6D asks for plain `SHA2(password,256)`; the files explain why salted slow hashes are used in production.
5. 7A/8A/8B/8C: extra generated documents (clearly labelled) were added where the PDF asks for 4-5 or "20+" documents but lists fewer.
6. Mongo experiments 7 and 9 run their aggregations before the destructive updates in a few places (order stated in each `explanation.md`) so the numbers equal those of the PDF data.
7. 10 Task 9: the PDF sample has no bill for A1003, so the script creates one before cancelling it.
