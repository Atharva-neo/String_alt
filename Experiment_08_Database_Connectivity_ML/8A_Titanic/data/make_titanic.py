"""Builds data/titanic.csv: the 6 sample rows of the PDF + 54 reproducible synthetic rows (seed 42) so that an 80/20 split has something to learn from."""
import csv
import random
from pathlib import Path

PDF_ROWS = [
    (1, 0, 3, "Braund Mr. Owen", "male", 22, 7.25, "S"),
    (2, 1, 1, "Cumings Mrs. John", "female", 38, 71.28, "C"),
    (3, 1, 3, "Heikkinen Miss. Laina", "female", 26, 7.92, "S"),
    (4, 1, 1, "Futrelle Mrs. Jacques", "female", 35, 53.10, "S"),
    (5, 0, 3, "Allen Mr. William", "male", "", 8.05, "S"),
    (6, 0, 3, "Moran Mr. James", "male", "", 8.46, "Q"),
]
random.seed(42)
rows = list(PDF_ROWS)
for pid in range(7, 61):
    pclass = random.choices([1, 2, 3], [0.25, 0.2, 0.55])[0]
    sex = random.choice(["male", "female"])
    age = "" if random.random() < 0.12 else random.randint(1, 70)
    fare = 0.0 if pid == 33 else round(random.uniform(5, 30) * (4 if pclass == 1 else 2 if pclass == 2 else 1), 2)
    p = 0.15 + (0.55 if sex == "female" else 0) + (0.15 if pclass == 1 else 0) - (0.1 if pclass == 3 else 0)   # survival likelihood rule used to generate labels
    survived = 1 if random.random() < p else 0
    rows.append((pid, survived, pclass, f"Passenger {pid:02d}", sex, age, fare, random.choices(["S", "C", "Q"], [0.7, 0.2, 0.1])[0]))
out = Path(__file__).parent / "titanic.csv"
with out.open("w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["PassengerId", "Survived", "Pclass", "Name", "Sex", "Age", "Fare", "Embarked"])
    w.writerows(rows)
print("written", out, len(rows), "rows")
