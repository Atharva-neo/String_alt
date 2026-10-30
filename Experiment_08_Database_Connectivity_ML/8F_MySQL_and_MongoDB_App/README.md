# 8F_MySQL_and_MongoDB_App - MySQL and MongoDB in one application (product catalogue)

## Setup
```bash
pip install -r requirements.txt
cp ../../.env.example ../../.env      # then edit MONGODB_URI / MYSQL_* (the scripts read ENVIRONMENT variables; export them or use your IDE's env file)
```

## Run
```bash
python main.py                      # MySQL + MongoDB required
USE_MOCK_MONGO=1 python main.py     # MongoDB part emulated, MySQL part real
npm install   (once, repository root)
node node_count.js                  # Task 12: mysql2 + mongodb drivers
```

| File | Purpose |
|---|---|
| `main.py` | Tasks 1-11 (Python) |
| `node_count.js` | Task 12 (Node.js, mysql2 + mongodb) |
| `node_count_output.md` | recorded output of the Node script |
| `requirements.txt` | Python packages |
| `expected_output.md` | recorded output (see the note at its top about what was real and what was emulated) |
| `explanation.md` | what every task does |
| `viva_questions.md` | viva Q&A |
