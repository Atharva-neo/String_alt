#!/usr/bin/env python3
"""8C - Review sentiment: MongoDB reviews + text cleaning + TF-IDF + Multinomial Naive Bayes (Tasks 1-12).

  python main.py                      (the new review of Task 12 is read from the keyboard; press Enter for the default text)
  python main.py --review "text"      non-interactive
"""
import re
import string
import sys
from pathlib import Path

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics import accuracy_score, confusion_matrix
from sklearn.model_selection import train_test_split
from sklearn.naive_bayes import MultinomialNB

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "common"))
from dbconn import get_mongo, heading

STOP = {"a", "an", "the", "is", "it", "its", "was", "are", "very", "for", "of", "to", "and", "this", "that", "i", "my", "after", "too", "at", "in", "on", "with"}
client = get_mongo()
col = client["mlDB"]["reviews"]
col.drop()

heading(1, "Insert 20+ reviews with PyMongo (5 from the PDF + 20 written for this exercise)")
reviews = [
    ("Earbuds", "Sound quality is excellent, very happy!", 5), ("Earbuds", "Stopped working after a week. Waste of money", 1),
    ("Charger", "Charges fast, good build", 4), ("Charger", "Gets too hot, not satisfied", 2), ("Watch", "Average product for the price", 3),
    ("Earbuds", "Battery lasts long and the bass is great", 5), ("Earbuds", "Left bud stopped connecting, poor quality", 2),
    ("Earbuds", "Terrible sound, returned it", 1), ("Earbuds", "Comfortable and clear sound, love it", 5),
    ("Charger", "Works well, charges my phone quickly", 5), ("Charger", "Cable broke in two days, bad build", 1),
    ("Charger", "Okay charger, nothing special", 3), ("Charger", "Excellent quality and fast charging", 5),
    ("Watch", "Looks stylish and the battery is great", 4), ("Watch", "Strap broke, very disappointed", 1),
    ("Watch", "Decent watch, does the job", 3), ("Watch", "Accurate tracking, good value", 4),
    ("Watch", "Screen scratched easily, poor quality", 2), ("Earbuds", "Fine for the price, average sound", 3),
    ("Charger", "Not satisfied, stopped charging", 2), ("Watch", "Love this watch, excellent display", 5),
    ("Earbuds", "Good bass and good fit, happy with it", 4), ("Charger", "Average speed, works fine", 3),
    ("Watch", "Waste of money, battery dies fast", 1), ("Earbuds", "Very happy with the quality", 5),
]
col.insert_many([{"product": p, "review": t, "rating": r} for p, t, r in reviews])
print("inserted:", col.count_documents({}))

heading(2, "Add field label: positive (rating >= 4), negative (<= 2), neutral (3)")
col.update_many({"rating": {"$gte": 4}}, {"$set": {"label": "positive"}})
col.update_many({"rating": {"$lte": 2}}, {"$set": {"label": "negative"}})
col.update_many({"rating": 3}, {"$set": {"label": "neutral"}})
print({r["_id"]: r["n"] for r in col.aggregate([{"$group": {"_id": "$label", "n": {"$sum": 1}}}, {"$sort": {"_id": 1}}])})

heading(3, "All negative reviews for Earbuds")
for d in col.find({"product": "Earbuds", "label": "negative"}, {"_id": 0, "review": 1, "rating": 1}):
    print("  ", d)

heading(4, "Count of reviews per product and average rating per product")
for r in col.aggregate([{"$group": {"_id": "$product", "reviews": {"$sum": 1}, "avg_rating": {"$avg": "$rating"}}}, {"$sort": {"_id": 1}}]):
    print(f"   {r['_id']:<8} reviews={r['reviews']:>2} avg rating={r['avg_rating']:.2f}")


def clean(text):
    """lower-case, remove punctuation, drop stop words"""
    text = text.lower().translate(str.maketrans("", "", string.punctuation))
    return " ".join(w for w in re.findall(r"[a-z0-9]+", text) if w not in STOP)


heading(5, "Clean the text (lowercase, no punctuation, no stop words) and store it as clean_review")
for d in col.find({}, {"review": 1}):
    col.update_one({"_id": d["_id"]}, {"$set": {"clean_review": clean(d["review"])}})
for d in col.find({}, {"_id": 0, "review": 1, "clean_review": 1}).limit(3):
    print("  ", d)

heading(6, "TF-IDF vectorisation + Multinomial Naive Bayes (80/20 split)")
docs = list(col.find({}, {"clean_review": 1, "label": 1}))
texts, labels = [d["clean_review"] for d in docs], [d["label"] for d in docs]
X_train, X_test, y_train, y_test = train_test_split(texts, labels, test_size=0.2, random_state=42)
vec = TfidfVectorizer()
model = MultinomialNB().fit(vec.fit_transform(X_train), y_train)
print(f"train {len(X_train)} / test {len(X_test)}; vocabulary size {len(vec.vocabulary_)}")

heading(7, "Accuracy and confusion matrix (test set)")
pred_test = model.predict(vec.transform(X_test))
print(f"accuracy: {accuracy_score(y_test, pred_test):.3f}")
classes = sorted(set(labels))
print("classes (rows = true, columns = predicted):", classes)
print(confusion_matrix(y_test, pred_test, labels=classes))

heading(8, "Store predicted_label in every document")
for d, p in zip(docs, model.predict(vec.transform(texts))):
    col.update_one({"_id": d["_id"]}, {"$set": {"predicted_label": str(p)}})
print("documents with predicted_label:", col.count_documents({"predicted_label": {"$exists": True}}))

heading(9, "Count documents where label != predicted_label")
wrong = sum(1 for d in col.find({}, {"label": 1, "predicted_label": 1}) if d["label"] != d["predicted_label"])
print("mismatches:", wrong, "of", col.count_documents({}), "(includes the training reviews; Naive Bayes is not perfect even on them)")

heading(10, "Text index on review and a search for 'quality'")
try:
    col.create_index([("review", "text")])
    hits = list(col.find({"$text": {"$search": "quality"}}, {"_id": 0, "review": 1}))
    how = "$text search"
except Exception as e:                                          # mongomock has no $text support -> regex fallback (same result for a single word)
    hits = list(col.find({"review": {"$regex": "quality", "$options": "i"}}, {"_id": 0, "review": 1}))
    how = f"regex fallback ({type(e).__name__}: $text unavailable in this environment)"
print(how, "->", len(hits), "reviews")
for h in hits:
    print("  ", h["review"])

heading(11, "Delete neutral reviews")
print("deleted:", col.delete_many({"label": "neutral"}).deleted_count, "| remaining:", col.count_documents({}))

heading(12, "Insert a new review from user input and print its predicted sentiment")
args = sys.argv[1:]
if "--review" in args:
    text = args[args.index("--review") + 1]
else:
    DEFAULT = "Battery is excellent and the sound quality is great"
    try:
        text = input("Type a review (Enter = default): ").strip() or DEFAULT
    except EOFError:                                              # no keyboard attached (e.g. piped run)
        text = DEFAULT
        print("(no keyboard input available - using the default review)")
pred = str(model.predict(vec.transform([clean(text)]))[0])
col.insert_one({"product": "Earbuds", "review": text, "clean_review": clean(text), "predicted_label": pred})
print(f'review: "{text}"\npredicted sentiment: {pred}')
