# Expected output - Experiment_08_Database_Connectivity_ML / 8B_House_Price

> **MongoDB part produced with the in-memory `mongomock` emulation (USE_MOCK_MONGO=1) - no MongoDB server was available.** MySQL parts, if any, ran against a real MySQL 8.0 server. Re-run without `--mock` on a machine with MongoDB for a real transcript. Date: 2026-10-30. Values such as timings or dates differ between runs.

```text
### Task 1 - Insert at least 20 documents (the 5 sample documents of the PDF + 16 generated with random values, seed 42)
inserted: 21 documents

### Task 2 - Houses in Pune with area > 1000 sqft
   {'area_sqft': 1200, 'bedrooms': 3, 'location': 'Pune', 'age_years': 2, 'price_lakh': 85}
   {'area_sqft': 1500, 'bedrooms': 3, 'location': 'Pune', 'age_years': None, 'price_lakh': 110}
   {'area_sqft': 1750, 'bedrooms': 3, 'location': 'Pune', 'age_years': 5, 'price_lakh': 125.9}
   {'area_sqft': 1400, 'bedrooms': 3, 'location': 'Pune', 'age_years': 2, 'price_lakh': 100.2}

### Task 3 - Average price per location (aggregation)
  Kolhapur  houses= 6  avg price = 38.95 lakh
  Pune      houses= 8  avg price = 74.71 lakh
  Sangli    houses= 7  avg price = 41.71 lakh

### Task 4 - Fill missing age_years with the mean age
mean age = 9.0; documents updated: 5; still missing: 0

### Task 5 - One-hot encode location in pandas
 area_sqft  bedrooms  age_years  price_lakh  location_Kolhapur  location_Pune  location_Sangli
       850         2        5.0        32.0                  0              0                1
      1200         3        2.0        85.0                  0              1                0
       650         1       10.0        22.0                  1              0                0
      1500         3        9.0       110.0                  0              1                0
      1000         2        8.0        38.0                  0              0                1

### Task 6 - Scale area_sqft with StandardScaler
mean after scaling = -0.0000, std = 1.0000

### Task 7 - Train Linear Regression and print R2
features: ['area_scaled', 'bedrooms', 'age_years', 'location_Kolhapur', 'location_Pune', 'location_Sangli']
R2 score (on the training data): 0.9233

### Task 8 - Write predicted_price into each document with update_one
documents with predicted_price: 21

### Task 9 - Houses where the predicted price differs from the actual price by more than 10%
   Kolhapur  area  650  actual     22  predicted   10.39  diff 52.8%
   Pune      area 1500  actual    110  predicted   94.92  diff 13.7%
   Kolhapur  area  650  actual   19.6  predicted   11.25  diff 42.6%
   Sangli    area  700  actual   19.6  predicted   14.21  diff 27.5%
   Pune      area  550  actual   37.5  predicted   49.74  diff 32.6%
   Kolhapur  area 1600  actual   50.3  predicted   58.14  diff 15.6%
   Pune      area 1750  actual  125.9  predicted  112.22  diff 10.9%
   Pune      area  900  actual   58.4  predicted   64.53  diff 10.5%
   Pune      area  650  actual   44.0  predicted   53.58  diff 21.8%
   Sangli    area 1650  actual   63.7  predicted   71.36  diff 12.0%
   Pune      area  600  actual   36.7  predicted    43.1  diff 17.4%
   Sangli    area 1700  actual   65.4  predicted    75.0  diff 14.7%
   Sangli    area 1100  actual   35.4  predicted   30.07  diff 15.1%
   Kolhapur  area 1650  actual   47.5  predicted   54.93  diff 15.6%
houses off by more than 10%: 14

### Task 10 - Create an index on location and show it
created: location_1
['_id_', 'location_1']

### Task 11 - Raise all Sangli prices by 5% with update_many
Sangli houses updated: 7; first three prices [32, 38, 19.6] -> [33.6, 39.9, 20.58]

### Task 12 - Export the collection to houses_out.csv
written houses_out.csv: 21 rows, 6 columns: ['area_sqft', 'bedrooms', 'location', 'age_years', 'price_lakh', 'predicted_price']
```
