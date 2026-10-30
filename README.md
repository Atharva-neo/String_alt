# DBMS Lab External - complete practical preparation kit

Source: *DBMS Lab External - Experiment List* (10 experiments, 52 pages). Every experiment, variation and numbered task of that PDF has its own folder with code, **real captured output where a real server was available**, explanation, ER/structure diagrams and viva questions.

> **Read this first - what is verified and what is not.** See `MASTER_INDEX.md` for the status of every task.
> * Experiments **1-6** (MySQL) were executed on a real **MySQL 8.0.46** server; `05_expected_output.md` files are captured outputs, not typed text.
> * Experiments **7, 9, 10-database** (mongosh scripts) were executed with `tools/mongosh_shim.js`, an **in-memory emulation** of mongosh (built on `mingo`). The logic and results are checked, but it is **not MongoDB**; `explain()` plans are simulated.
> * Experiments **8A-8C, 8F (Mongo part)** ran with `mongomock` (in-memory), **8E** and the MySQL parts of **8F** on real MySQL; **8D** against an in-memory fake of the driver.
> * **Not executed anywhere:** MongoDB change streams, the live dashboard refresh on a real replica set, all Neo4j Cypher. They are implemented and documented; run the commands in `Experiment_10_Hospital_Management/README.md` to verify them.

## Structure

```
DBMS_LAB_EXTERNAL/
├── README.md  MASTER_INDEX.md  requirements.txt  package.json  .env.example
├── tools/            run_sql.py (executes a SQL variation and writes 05/06/README), sessions.py (multi-session demos),
│                     fd_tools.py (closures, keys, BCNF/3NF, lossless join), run_mongo.py, run_py.py, mongosh_shim.js, fake_mongodb.js ...
├── Experiment_01_SQL_Basics/                 1A_Library 1B_Bank 1C_College 1D_Online_Shop
├── Experiment_02_Advanced_SQL/               2A_Employee_Department 2B_Sales 2C_University_Results 2D_Flight_Booking
├── Experiment_03_Normalization_BCNF/         3A_Student_Course 3B_Order_Details 3C_Employee_Project 3D_Teaching
├── Experiment_04_Triggers_Procedures_ACID/   4A_Bank_Transfer 4B_Payroll 4C_Library_Fines 4D_Ticket_Booking
├── Experiment_05_Concurrency_Recovery/       5A_Lost_Update 5B_Isolation_Levels 5C_Deadlocks 5D_Log_Based_Recovery
├── Experiment_06_Inventory_Authentication/   6A_Retail_Store 6B_Medical_Store 6C_Multi_Warehouse 6D_Login_Module
├── Experiment_07_MongoDB/                    7A_Blog 7B_Ecommerce 7C_Movie_Catalogue 7D_Employee_Directory
├── Experiment_08_Database_Connectivity_ML/   8A_Titanic 8B_House_Price 8C_Review_Sentiment 8D_Node_REST_API 8E_Python_MySQL_Student_Fees 8F_MySQL_and_MongoDB_App
├── Experiment_09_Student_Records/            9A_Attendance_Report 9B_Result_Analysis 9C_Report_Card 9D_Department_Statistics
├── Experiment_10_Hospital_Management/        database backend realtime dashboard neo4j
└── docs/             SQL_Reference MongoDB_Reference Python_Reference Normalization_Notes ACID_Notes Concurrency_Notes Viva_Questions
```

The PDF defines **A-D for experiments 1-7 and 9, A-F for experiment 8** (so Experiment 8 has six folders, 7B-7D are E-commerce / Movie catalogue / Employee directory, 9A-9D are attendance / results / report card / department statistics). Folder names follow the PDF titles.

SQL variation folders: `01_schema.sql` `02_sample_data.sql` `03_implementation.sql` (all 12 tasks) `04_advanced_queries.sql` `05_expected_output.md` `06_explanation.md` (ER diagram, concepts) `07_viva_questions.md` `README.md`; Experiment 3 adds `00_derivation.md` + `fd_analysis.py`; Experiments 4/5 add `run_demo.py`, `session1.sql`, `session2.sql`.
MongoDB folders: `schema.js insert_data.js queries.js crud.js aggregation.js indexes.js run_order.txt expected_output.md explanation.md viva_questions.md README.md`.
Python/Node folders: `main.py` (or `app.js`/`server.js`), `requirements.txt`, `expected_output.md`, `explanation.md`, `viva_questions.md`, `README.md`.

## Installation

| Tool | Version | Notes |
|---|---|---|
| MySQL | 8.0.16+ (CHECK enforced; roles; `RENAME COLUMN`) | Windows installer or `apt install mysql-server`; make sure you can run `mysql -u root -p`. Oracle differences are marked in comments. |
| MongoDB | 7.0 + `mongosh` | Community Server; for Experiment 10 a **single-node replica set**: `mongod --replSet rs0 --dbpath <dir>` then `mongosh --eval "rs.initiate()"`. Compass optional. |
| Python | 3.10+ | `python -m venv .venv`, activate, `pip install -r requirements.txt` |
| Node.js | 18+ | `npm install` in the repository root (express, mongodb, mysql2, dotenv; `mingo` for the test shim) |
| Neo4j | 5.x | `docker run -p 7474:7474 -p 7687:7687 -e NEO4J_AUTH=neo4j/<password> neo4j:5` or Neo4j Desktop (Browser at http://localhost:7474) |

Copy `.env.example`, set the variables (the code never contains passwords).

## How to run

**SQL experiments 1-6** (one variation):
```bash
cd Experiment_01_SQL_Basics/1A_Library
mysql -u root -p < 01_schema.sql
mysql -u root -p library_1a < 02_sample_data.sql
mysql -u root -p library_1a < 03_implementation.sql      # then 04_advanced_queries.sql
```
or let the helper do it and rebuild the output files (needs `MYSQL_*` variables): `python tools/run_sql.py Experiment_01_SQL_Basics/1A_Library` (`--all` for everything).
Order inside a variation matters (later scripts use the state left by earlier ones). Lines starting `-- |` are statements to type in a second terminal as another MySQL user; `-- S1>`/`-- S2>` lines (experiments 4-5) are the two-terminal scripts - `python run_demo.py` replays them with real connections.
Experiment 3: `python fd_analysis.py` prints closures, candidate keys, normal-form checks and the lossless-join test. Experiment 5D: `python main.py`.

**MongoDB experiments 7, 9, 10-database:** `cd Experiment_07_MongoDB/7A_Blog` then run the files of `run_order.txt` with `mongosh --quiet --file <file>`; or `python tools/run_mongo.py --real Experiment_07_MongoDB/7A_Blog`. Without a server: `python tools/run_mongo.py Experiment_07_MongoDB/7A_Blog` (shim).

**Experiment 8:** `cd Experiment_08_.../8A_Titanic && python main.py` (MongoDB), `8E` needs MySQL, `8D`: `node server.js` + `node test_api.js`. **Experiment 10:** see its README (generator, watcher, dashboard, Neo4j).

**Suggested order for revision:** 1 -> 2 -> 3 -> 4 -> 5 -> 6 (SQL), 7 -> 9 (MongoDB), 8, 10.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `ERROR 1819` / `Access denied` | wrong `MYSQL_PWD`/user; for the demos the user needs CREATE/DROP DATABASE and CREATE USER rights (root) |
| `ERROR 3819 Check constraint ... violated` is printed | that is a deliberate negative test (marked in the task comment) |
| Check constraints silently ignored | MySQL < 8.0.16 - upgrade |
| `ERROR 1418 ... DETERMINISTIC, NO SQL, or READS SQL DATA` | the function lacks a characteristic or set `SET GLOBAL log_bin_trust_function_creators=1` (our functions declare `READS SQL DATA`) |
| Procedure with `DELIMITER` fails in a GUI | run the script with the `mysql` CLI (DELIMITER is a client command) or set the delimiter field in Workbench |
| `ERROR 1205 Lock wait timeout` in the two-session demos | expected in 5A Task 10; otherwise a previous demo session is still open - close it |
| `The MySQL server is running with the --skip-grant-tables` / role errors | roles need MySQL 8; `SET DEFAULT ROLE` must be run for each user |
| `mongosh` not found / connection refused | start `mongod`; check `MONGODB_URI` |
| `Document failed validation` | a deliberate negative test, or a document that violates `schema.js` |
| `The $changeStream stage is only supported on replica sets` | start `mongod --replSet rs0` and run `rs.initiate()` |
| Streamlit `width="stretch"` error | upgrade Streamlit (`pip install -U streamlit`, needs >= 1.50) |
| PowerShell: `&&` not recognised | use `;` (Windows PowerShell 5) |
| `ModuleNotFoundError: mysql` | `pip install mysql-connector-python` (not `mysql`) |
| Dates differ from `05_expected_output.md` | tasks using `CURRENT_DATE`/`NOW()` (1A, 6B) depend on the run date |

## Documents

`docs/` contains compact reference sheets (SQL, MongoDB, Python/pandas/scikit-learn), normalization, ACID, concurrency notes and a pooled viva question bank. `MASTER_INDEX.md` is the checklist with the verification status of every task.
