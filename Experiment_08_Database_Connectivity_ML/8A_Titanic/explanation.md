# Explanation - 8A_Titanic

| Task | What happens |
|---|---|
| 1-2 | `MongoClient`, `insert_many` of `DataFrame.to_dict('records')` (NaN converted to `None` so MongoDB stores null) |
| 3 | `count_documents` |
| 4 | filter `{Sex:'female', Pclass:1}` + projection |
| 5 | `{Age: None}` matches null AND missing; filled with the pandas median |
| 6 | `update_many` encodes Sex (male 0/female 1) and Embarked (S0 C1 Q2) in the database |
| 7 | `$group` + `$avg` of the 0/1 `Survived` = survival rate |
| 8 | `DataFrame(list(find()))` |
| 9 | `train_test_split(test_size=0.2)`, `LogisticRegression`, accuracy (tiny synthetic data: treat the number as a demonstration) |
| 10 | `update_one` per passenger with `predicted` |
| 11 | results document {model, accuracy, date} |
| 12 | `delete_many({Fare: 0})` then remaining count |
