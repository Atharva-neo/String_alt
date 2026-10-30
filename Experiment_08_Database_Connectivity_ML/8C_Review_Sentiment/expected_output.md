# Expected output - Experiment_08_Database_Connectivity_ML / 8C_Review_Sentiment

> **MongoDB part produced with the in-memory `mongomock` emulation (USE_MOCK_MONGO=1) - no MongoDB server was available.** MySQL parts, if any, ran against a real MySQL 8.0 server. Re-run without `--mock` on a machine with MongoDB for a real transcript. Date: 2026-10-30. Values such as timings or dates differ between runs.

```text
### Task 1 - Insert 20+ reviews with PyMongo (5 from the PDF + 20 written for this exercise)
inserted: 25

### Task 2 - Add field label: positive (rating >= 4), negative (<= 2), neutral (3)
{'negative': 9, 'neutral': 5, 'positive': 11}

### Task 3 - All negative reviews for Earbuds
   {'review': 'Stopped working after a week. Waste of money', 'rating': 1}
   {'review': 'Left bud stopped connecting, poor quality', 'rating': 2}
   {'review': 'Terrible sound, returned it', 'rating': 1}

### Task 4 - Count of reviews per product and average rating per product
   Charger  reviews= 8 avg rating=3.12
   Earbuds  reviews= 9 avg rating=3.44
   Watch    reviews= 8 avg rating=2.88

### Task 5 - Clean the text (lowercase, no punctuation, no stop words) and store it as clean_review
   {'review': 'Sound quality is excellent, very happy!', 'clean_review': 'sound quality excellent happy'}
   {'review': 'Stopped working after a week. Waste of money', 'clean_review': 'stopped working week waste money'}
   {'review': 'Charges fast, good build', 'clean_review': 'charges fast good build'}

### Task 6 - TF-IDF vectorisation + Multinomial Naive Bayes (80/20 split)
train 20 / test 5; vocabulary size 57

### Task 7 - Accuracy and confusion matrix (test set)
accuracy: 0.600
classes (rows = true, columns = predicted): ['negative', 'neutral', 'positive']
[[0 0 1]
 [1 0 0]
 [0 0 3]]

### Task 8 - Store predicted_label in every document
documents with predicted_label: 25

### Task 9 - Count documents where label != predicted_label
mismatches: 2 of 25 (includes the training reviews; Naive Bayes is not perfect even on them)

### Task 10 - Text index on review and a search for 'quality'
regex fallback (NotImplementedError: $text unavailable in this environment) -> 5 reviews
   Sound quality is excellent, very happy!
   Left bud stopped connecting, poor quality
   Excellent quality and fast charging
   Screen scratched easily, poor quality
   Very happy with the quality

### Task 11 - Delete neutral reviews
deleted: 5 | remaining: 20

### Task 12 - Insert a new review from user input and print its predicted sentiment
Type a review (Enter = default): (no keyboard input available - using the default review)
review: "Battery is excellent and the sound quality is great"
predicted sentiment: positive
```
