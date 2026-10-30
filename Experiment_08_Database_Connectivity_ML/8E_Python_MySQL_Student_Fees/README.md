# 8E_Python_MySQL_Student_Fees - Python-MySQL connectivity (student fees)

## Setup
```bash
pip install -r requirements.txt
cp ../../.env.example ../../.env      # then edit MONGODB_URI / MYSQL_* (the scripts read ENVIRONMENT variables; export them or use your IDE's env file)
```

## Run
```bash
python main.py --roll 102 --amount 10000 --delete-roll 105      # non-interactive
python main.py                                                       # asks for roll number / amount
```

| File | Purpose |
|---|---|
| `main.py` | Tasks 1-12 (needs a MySQL 8 server and permission to create the database `collegeDB`) |
| `requirements.txt` | Python packages |
| `expected_output.md` | recorded output (see the note at its top about what was real and what was emulated) |
| `explanation.md` | what every task does |
| `viva_questions.md` | viva Q&A |
