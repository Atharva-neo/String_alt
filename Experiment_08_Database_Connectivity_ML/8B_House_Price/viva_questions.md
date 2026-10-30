# Viva questions - 8B_House_Price

**Q1. Why one-hot encode location?** A linear model would treat Sangli=1, Pune=2 as ordered numbers; one-hot columns give each city its own coefficient.

**Q2. What does StandardScaler do and why?** (x-mean)/std. Puts features on a comparable scale; essential for distance/regularised models, harmless for plain linear regression.

**Q3. What does R2 mean?** Fraction of the variance of the price explained by the model (1 = perfect, 0 = as good as predicting the mean).

**Q4. Why is R2 on training data misleading?** The model has seen those rows; use a test split or cross-validation.

**Q5. `$mul` vs read-modify-write?** `$mul` is atomic on the server and needs no round trip.

**Q6. Why index `location`?** Speeds up equality filters and `$group`/`$match` on location for large collections.

**Q7. How are nulls in age_years handled?** Mean imputation stored back into MongoDB so later reads are complete.
