# Explanation - 8C_Review_Sentiment

| Task | What happens |
|---|---|
| 1 | 25 reviews inserted |
| 2 | `update_many` with rating ranges sets `label` |
| 3 | negative Earbuds reviews |
| 4 | `$group` count and `$avg` rating per product |
| 5 | `clean()`: lowercase, strip punctuation, remove stop words -> `clean_review` |
| 6 | `TfidfVectorizer` + `MultinomialNB`, 80/20 split |
| 7 | accuracy and `confusion_matrix` |
| 8 | `predicted_label` stored |
| 9 | mismatches between `label` and `predicted_label` |
| 10 | text index on `review`, `$text` search 'quality' |
| 11 | `delete_many({label:'neutral'})` |
| 12 | new review from the keyboard -> clean -> predict -> insert |
