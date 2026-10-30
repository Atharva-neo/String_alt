#!/usr/bin/env python3
"""8A - Titanic dataset with PyMongo: CSV -> MongoDB -> clean -> encode -> aggregate -> train -> store predictions (Tasks 1-12).

  python main.py            (needs a MongoDB server; MONGODB_URI optional)
  USE_MOCK_MONGO=1 python main.py     test run without a server (in-memory mongomock; prints a warning)
"""
import sys
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score
from sklearn.model_selection import train_test_split

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "common"))
from dbconn import get_mongo, heading

HERE = Path(__file__).resolve().parent
CSV = HERE / "data" / "titanic.csv"

heading(1, "Connect with PyMongo, create database mlDB and collection titanic")
client = get_mongo()
db = client["mlDB"]
db.drop_collection("titanic")
db.drop_collection("results")
col = db["titanic"]
print("connected; database:", db.name, "| collections:", db.list_collection_names())

heading(2, "Read the CSV with pandas and insert all rows with insert_many")
df = pd.read_csv(CSV)
print(df.head(6).to_string(index=False))
docs = df.astype(object).where(df.notna(), None).to_dict("records")      # NaN -> None so that MongoDB stores null
res = col.insert_many(docs)
print("inserted:", len(res.inserted_ids))

heading(3, "Count documents and survivors (count_documents)")
print("total passengers :", col.count_documents({}))
print("survivors        :", col.count_documents({"Survived": 1}))

heading(4, "Female passengers in Pclass 1 - name and fare")
for d in col.find({"Sex": "female", "Pclass": 1}, {"_id": 0, "Name": 1, "Fare": 1}):
    print("  ", d)

heading(5, "Documents with missing Age ($exists / null) -> fill with the median age")
missing = col.count_documents({"Age": None})                # {"Age": None} matches null AND missing fields
median_age = float(df["Age"].median())
upd = col.update_many({"Age": None}, {"$set": {"Age": median_age}})
print(f"missing before: {missing}, median age: {median_age}, updated: {upd.modified_count}, missing after: {col.count_documents({'Age': None})}")

heading(6, "Encode Sex (male=0, female=1) and Embarked (S=0, C=1, Q=2) with update_many")
col.update_many({"Sex": "male"}, {"$set": {"Sex": 0}})
col.update_many({"Sex": "female"}, {"$set": {"Sex": 1}})
for port, code in {"S": 0, "C": 1, "Q": 2}.items():
    col.update_many({"Embarked": port}, {"$set": {"Embarked": code}})
print(col.find_one({"PassengerId": 2}, {"_id": 0}))

heading(7, "Survival rate per Pclass (aggregation pipeline)")
for r in col.aggregate([{"$group": {"_id": "$Pclass", "passengers": {"$sum": 1}, "survival_rate": {"$avg": "$Survived"}}}, {"$sort": {"_id": 1}}]):
    print(f"  Pclass {r['_id']}: {r['passengers']:>2} passengers, survival rate {r['survival_rate']:.2%}")

heading(8, "Load the cleaned data back into a DataFrame from find()")
data = pd.DataFrame(list(col.find({}, {"_id": 0})))
print(data.dtypes.to_string())
print("rows:", len(data), "| missing values:", int(data[["Age", "Fare", "Sex", "Embarked"]].isna().sum().sum()))

heading(9, "80/20 split, Logistic Regression, accuracy")
features = ["Pclass", "Sex", "Age", "Fare", "Embarked"]
X, y = data[features], data["Survived"]
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
model = LogisticRegression(max_iter=1000).fit(X_train, y_train)
acc = accuracy_score(y_test, model.predict(X_test))
print(f"train rows {len(X_train)}, test rows {len(X_test)}, accuracy on the test set: {acc:.3f}")

heading(10, "Store each passenger's predicted label in the document (field predicted)")
data["predicted"] = model.predict(X)
for pid, pred in zip(data["PassengerId"], data["predicted"]):
    col.update_one({"PassengerId": int(pid)}, {"$set": {"predicted": int(pred)}})        # parameter values are plain Python ints
print("documents with a prediction:", col.count_documents({"predicted": {"$exists": True}}))
print(col.find_one({"PassengerId": 1}, {"_id": 0}))

heading(11, "Insert a results document {model, accuracy, date} into the results collection")
db["results"].insert_one({"model": "LogisticRegression", "accuracy": round(float(acc), 4), "date": datetime.now(timezone.utc)})
print(db["results"].find_one({}, {"_id": 0}))

heading(12, "Delete passengers with Fare = 0 and print the remaining count")
d = col.delete_many({"Fare": 0})
print("deleted:", d.deleted_count, "| remaining:", col.count_documents({}))
