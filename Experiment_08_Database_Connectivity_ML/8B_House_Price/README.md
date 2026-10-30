# 8B_House_Price - House price prediction

## Setup
```bash
pip install -r requirements.txt
cp ../../.env.example ../../.env      # then edit MONGODB_URI / MYSQL_* (the scripts read ENVIRONMENT variables; export them or use your IDE's env file)
```

## Run
```bash
python main.py                      # MongoDB required
USE_MOCK_MONGO=1 python main.py     # no server (mongomock; $mul is emulated document by document)
```

| File | Purpose |
|---|---|
| `main.py` | Tasks 1-12 (5 PDF documents + 16 generated, seed 42) |
| `houses_out.csv` | export written by Task 12 |
| `requirements.txt` | Python packages |
| `expected_output.md` | recorded output (see the note at its top about what was real and what was emulated) |
| `explanation.md` | what every task does |
| `viva_questions.md` | viva Q&A |
