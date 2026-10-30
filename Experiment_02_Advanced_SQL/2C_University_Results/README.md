# Experiment_02_Advanced_SQL / 2C_University_Results

Database name: `univ_2c` (created by `01_schema.sql`; safe to re-run, it drops and recreates it).

## Run order

```bash
mysql -u root -p < 01_schema.sql
mysql -u root -p univ_2c < 02_sample_data.sql
mysql -u root -p univ_2c < 03_implementation.sql      # all numbered tasks of the PDF
mysql -u root -p univ_2c < 04_advanced_queries.sql    # extra examiner-style queries
```

Or let the helper run everything and rebuild the output file:

```bash
python tools/run_sql.py Experiment_02_Advanced_SQL/2C_University_Results
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

Notes: lines starting `-- |` in `03_implementation.sql` are statements that must be typed in a
*second terminal as another MySQL user*; they are comments so that a plain `mysql < file` run stays safe.
