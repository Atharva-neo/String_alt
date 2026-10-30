# Viva questions - 8A_Titanic

**Q1. Why encode Sex and Embarked as numbers?** Scikit-learn models need numeric input; male/female -> 0/1, ports -> 0/1/2 (for nominal data with many values prefer one-hot encoding so no false order is implied).

**Q2. Why fill missing Age with the median?** The median is robust to outliers; the mean could be pulled by very old/young passengers. Fill using training data only in real projects to avoid leakage.

**Q3. What does `{Age: None}` match?** Documents where Age is null or the field is missing (use `$exists`/`$type` to separate the two).

**Q4. Why a train/test split?** To measure accuracy on unseen data; accuracy on training data is optimistic.

**Q5. insert_many vs a loop of insert_one?** One round trip, much faster; ordered by default.

**Q6. How would you improve the model?** More data, feature engineering (title from Name, family size), cross-validation, other models (tree, random forest).

**Q7. Why store predictions in MongoDB?** So applications/dashboards can read results next to the source documents; keep the model name and accuracy in `results`.
