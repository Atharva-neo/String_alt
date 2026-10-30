# 8C_Review_Sentiment - Review sentiment analysis

## Setup
```bash
pip install -r requirements.txt
cp ../../.env.example ../../.env      # then edit MONGODB_URI / MYSQL_* (the scripts read ENVIRONMENT variables; export them or use your IDE's env file)
```

## Run
```bash
python main.py                       # asks for a review (Enter = default)
python main.py --review "Great sound, love it"
USE_MOCK_MONGO=1 python main.py       # no server ($text search falls back to a regex)
```

| File | Purpose |
|---|---|
| `main.py` | Tasks 1-12 (5 PDF reviews + 20 reviews written for the exercise) |
| `requirements.txt` | Python packages |
| `expected_output.md` | recorded output (see the note at its top about what was real and what was emulated) |
| `explanation.md` | what every task does |
| `viva_questions.md` | viva Q&A |
