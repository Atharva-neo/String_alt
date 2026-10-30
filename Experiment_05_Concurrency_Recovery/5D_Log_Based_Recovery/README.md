# 5D - Log-based recovery program

```bash
pip install -r requirements.txt          # only needed for Task 12 (MySQL)
python main.py                           # Tasks 1-12 (reads data/log.txt and data/log_t2_commit.txt)
python main.py --no-mysql                # skip Task 12 if no MySQL server is available
python main.py --log data/log.txt --mode deferred     # one scenario on any log file
```

MySQL connection for Task 12 comes from environment variables (see the root `.env.example`): `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USER`, `MYSQL_PWD`.

| File | Purpose |
|---|---|
| `main.py` | parser, analysis (committed / uncommitted / checkpoint / UNDO-REDO lists), immediate and deferred recovery, MySQL step |
| `data/log.txt` | the log from the PDF (Task 1) |
| `data/log_t2_commit.txt` | the same log with `<T2, commit>` added (Task 11) |
| `mysql_5d.sql` | the SQL equivalent of Task 12 |
| `expected_output.md` | **real captured output** |
| `explanation.md` | theory + diagram |
| `viva_questions.md` | viva Q&A |
