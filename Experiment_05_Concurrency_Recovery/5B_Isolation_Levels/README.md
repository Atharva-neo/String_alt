# Experiment_05_Concurrency_Recovery / 5B_Isolation_Levels

Database name: `seats_5b` (created by `01_schema.sql`; safe to re-run, it drops and recreates it).

## Run order

```bash
mysql -u root -p < 01_schema.sql
mysql -u root -p seats_5b < 02_sample_data.sql
mysql -u root -p seats_5b < 03_implementation.sql      # all numbered tasks of the PDF
mysql -u root -p seats_5b < 04_advanced_queries.sql    # extra examiner-style queries
```

Or let the helper run everything and rebuild the output file:

```bash
python tools/run_sql.py Experiment_05_Concurrency_Recovery/5B_Isolation_Levels
```

| File | Purpose |
|------|---------|
| `01_schema.sql` | database + tables (+ ER diagram in a comment) |
| `02_sample_data.sql` | the exact rows given in the PDF |
| `03_implementation.sql` | every numbered task, with comments |
| `04_advanced_queries.sql` | additional examiner-style queries |
| `05_expected_output.md` | **real** output captured from MySQL 8.0.46 |
| `06_explanation.md` | ER diagram, concepts, task-by-task logic |
| `07_viva_questions.md` | viva Q&A |
| `run_demo.py` | replays the multi-session tasks with real connections (`python run_demo.py [--emit]`) |
| `session1.sql`, `session2.sql` | the same steps per terminal for a manual two-terminal run |

**Two-terminal experiment.** `03_implementation.sql` is a script for two terminals (lines `-- S1>` / `-- S2>`); `05_expected_output.md` is the transcript of `run_demo.py` (needs `pip install mysql-connector-python`).
The demo uses real locks and waits: it needs a MySQL server where the user may create databases (and, in 5B Task 10, `SET GLOBAL`).

Notes: lines starting `-- |` in `03_implementation.sql` are statements that must be typed in a
*second terminal as another MySQL user*; they are comments so that a plain `mysql < file` run stays safe.
