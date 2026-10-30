#!/usr/bin/env python3
"""8B - House price prediction: MongoDB houses collection + pandas preprocessing + Linear Regression (Tasks 1-12)."""
import random
import sys
from pathlib import Path

import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.metrics import r2_score
from sklearn.preprocessing import StandardScaler

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "common"))
from dbconn import get_mongo, heading

HERE = Path(__file__).resolve().parent
client = get_mongo()
col = client["mlDB"]["houses"]
col.drop()

heading(1, "Insert at least 20 documents (the 5 sample documents of the PDF + 16 generated with random values, seed 42)")
pdf_docs = [
    {"area_sqft": 850, "bedrooms": 2, "location": "Sangli", "age_years": 5, "price_lakh": 32},
    {"area_sqft": 1200, "bedrooms": 3, "location": "Pune", "age_years": 2, "price_lakh": 85},
    {"area_sqft": 650, "bedrooms": 1, "location": "Kolhapur", "age_years": 10, "price_lakh": 22},
    {"area_sqft": 1500, "bedrooms": 3, "location": "Pune", "age_years": None, "price_lakh": 110},
    {"area_sqft": 1000, "bedrooms": 2, "location": "Sangli", "age_years": 8, "price_lakh": 38},
]
random.seed(42)
rate = {"Sangli": 0.038, "Pune": 0.075, "Kolhapur": 0.034}          # lakh per sqft used to generate prices
gen = []
for _ in range(16):
    loc = random.choice(list(rate))
    area = random.randrange(500, 1800, 50)
    beds = 1 if area < 800 else 2 if area < 1300 else 3
    age = None if random.random() < 0.1 else random.randint(0, 20)
    price = round(area * rate[loc] * (1 - 0.01 * (age or 5)) + random.uniform(-3, 3), 1)
    gen.append({"area_sqft": area, "bedrooms": beds, "location": loc, "age_years": age, "price_lakh": price})
res = col.insert_many(pdf_docs + gen)
print("inserted:", len(res.inserted_ids), "documents")

heading(2, "Houses in Pune with area > 1000 sqft")
for d in col.find({"location": "Pune", "area_sqft": {"$gt": 1000}}, {"_id": 0}):
    print("  ", d)

heading(3, "Average price per location (aggregation)")
for r in col.aggregate([{"$group": {"_id": "$location", "houses": {"$sum": 1}, "avg_price": {"$avg": "$price_lakh"}}}, {"$sort": {"_id": 1}}]):
    print(f"  {r['_id']:<9} houses={r['houses']:>2}  avg price = {r['avg_price']:.2f} lakh")

heading(4, "Fill missing age_years with the mean age")
df = pd.DataFrame(list(col.find({}, {"_id": 0})))
mean_age = round(float(df["age_years"].mean()), 2)                   # pandas skips null when averaging
n = col.update_many({"age_years": None}, {"$set": {"age_years": mean_age}}).modified_count
print(f"mean age = {mean_age}; documents updated: {n}; still missing: {col.count_documents({'age_years': None})}")

heading(5, "One-hot encode location in pandas")
df = pd.DataFrame(list(col.find({}, {"_id": 1, "area_sqft": 1, "bedrooms": 1, "location": 1, "age_years": 1, "price_lakh": 1})))
encoded = pd.get_dummies(df, columns=["location"], dtype=int)
print(encoded.drop(columns=["_id"]).head(5).to_string(index=False))

heading(6, "Scale area_sqft with StandardScaler")
scaler = StandardScaler()
encoded["area_scaled"] = scaler.fit_transform(encoded[["area_sqft"]])
print(f"mean after scaling = {encoded['area_scaled'].mean():.4f}, std = {encoded['area_scaled'].std(ddof=0):.4f}")

heading(7, "Train Linear Regression and print R2")
feature_cols = ["area_scaled", "bedrooms", "age_years"] + [c for c in encoded.columns if c.startswith("location_")]
model = LinearRegression().fit(encoded[feature_cols], encoded["price_lakh"])
pred = model.predict(encoded[feature_cols])
print("features:", feature_cols)
print(f"R2 score (on the training data): {r2_score(encoded['price_lakh'], pred):.4f}")

heading(8, "Write predicted_price into each document with update_one")
for _id, p in zip(encoded["_id"], pred):
    col.update_one({"_id": _id}, {"$set": {"predicted_price": round(float(p), 2)}})
print("documents with predicted_price:", col.count_documents({"predicted_price": {"$exists": True}}))

heading(9, "Houses where the predicted price differs from the actual price by more than 10%")
count = 0
for d in col.find({}, {"_id": 0}):
    diff = abs(d["predicted_price"] - d["price_lakh"]) / d["price_lakh"]
    if diff > 0.10:
        count += 1
        print(f"   {d['location']:<9} area {d['area_sqft']:>4}  actual {d['price_lakh']:>6}  predicted {d['predicted_price']:>7}  diff {diff:.1%}")
print("houses off by more than 10%:", count)

heading(10, "Create an index on location and show it")
print("created:", col.create_index("location"))
print(sorted(col.index_information().keys()))

heading(11, "Raise all Sangli prices by 5% with update_many")
before = [d["price_lakh"] for d in col.find({"location": "Sangli"}, {"price_lakh": 1}).sort("_id", 1)][:3]
try:
    r = col.update_many({"location": "Sangli"}, {"$mul": {"price_lakh": 1.05}})          # real MongoDB: one atomic server-side operation
except ValueError:                                                                        # mongomock does not implement $mul -> same effect document by document
    class r:  # noqa: N801
        modified_count = 0
    for d in col.find({"location": "Sangli"}, {"price_lakh": 1}):
        col.update_one({"_id": d["_id"]}, {"$set": {"price_lakh": d["price_lakh"] * 1.05}}); r.modified_count += 1
after = [round(d["price_lakh"], 2) for d in col.find({"location": "Sangli"}, {"price_lakh": 1}).sort("_id", 1)][:3]
print(f"Sangli houses updated: {r.modified_count}; first three prices {before} -> {after}")

heading(12, "Export the collection to houses_out.csv")
out = pd.DataFrame(list(col.find({}, {"_id": 0})))
out.to_csv(HERE / "houses_out.csv", index=False)
print("written houses_out.csv:", len(out), "rows,", len(out.columns), "columns:", list(out.columns))
