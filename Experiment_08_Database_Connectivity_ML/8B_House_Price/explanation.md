# Explanation - 8B_House_Price

| Task | What happens |
|---|---|
| 1 | 5 documents of the PDF + 16 generated with random values (`random.seed(42)`) = 21 documents |
| 2 | `{location:'Pune', area_sqft:{$gt:1000}}` |
| 3 | `$group` by location with `$avg` |
| 4 | pandas mean of `age_years` (nulls skipped) -> `update_many({age_years: None}, $set)` |
| 5 | `pd.get_dummies(df, columns=['location'])` |
| 6 | `StandardScaler`: mean 0, std 1 |
| 7 | `LinearRegression`, `r2_score` (computed on the training data - for a real evaluation split first) |
| 8 | `update_one` per house with `predicted_price` |
| 9 | relative error > 10% -> list |
| 10 | `create_index('location')`, `index_information()` |
| 11 | `$mul: 1.05` (atomic, server side) |
| 12 | DataFrame -> `houses_out.csv` |
