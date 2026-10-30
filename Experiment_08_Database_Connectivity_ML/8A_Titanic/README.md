# 8A_Titanic - Titanic dataset with PyMongo

## Setup
```bash
pip install -r requirements.txt
cp ../../.env.example ../../.env      # then edit MONGODB_URI / MYSQL_* (the scripts read ENVIRONMENT variables; export them or use your IDE's env file)
```

## Run
```bash
python data/make_titanic.py     # (re)creates data/titanic.csv: 6 PDF rows + 54 synthetic rows (seed 42)
python main.py                      # needs MongoDB on MONGODB_URI (default mongodb://localhost:27017)
USE_MOCK_MONGO=1 python main.py     # no server: in-memory mongomock (PowerShell: $env:USE_MOCK_MONGO='1')
```

| File | Purpose |
|---|---|
| `data/titanic.csv` | the 6 sample rows of the PDF + 54 reproducible synthetic rows (the PDF only lists samples; 6 rows are too few to split 80/20) |
| `data/make_titanic.py` | generator of that file |
| `main.py` | Tasks 1-12 |
| `requirements.txt` | Python packages |
| `expected_output.md` | recorded output (see the note at its top about what was real and what was emulated) |
| `explanation.md` | what every task does |
| `viva_questions.md` | viva Q&A |
