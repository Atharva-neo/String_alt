# Expected output - Experiment_08_Database_Connectivity_ML / 8A_Titanic

> **MongoDB part produced with the in-memory `mongomock` emulation (USE_MOCK_MONGO=1) - no MongoDB server was available.** MySQL parts, if any, ran against a real MySQL 8.0 server. Re-run without `--mock` on a machine with MongoDB for a real transcript. Date: 2026-10-30. Values such as timings or dates differ between runs.

```text
### Task 1 - Connect with PyMongo, create database mlDB and collection titanic
connected; database: mlDB | collections: []

### Task 2 - Read the CSV with pandas and insert all rows with insert_many
 PassengerId  Survived  Pclass                  Name    Sex  Age  Fare Embarked
           1         0       3       Braund Mr. Owen   male 22.0  7.25        S
           2         1       1     Cumings Mrs. John female 38.0 71.28        C
           3         1       3 Heikkinen Miss. Laina female 26.0  7.92        S
           4         1       1 Futrelle Mrs. Jacques female 35.0 53.10        S
           5         0       3     Allen Mr. William   male  NaN  8.05        S
           6         0       3       Moran Mr. James   male  NaN  8.46        Q
inserted: 60

### Task 3 - Count documents and survivors (count_documents)
total passengers : 60
survivors        : 25

### Task 4 - Female passengers in Pclass 1 - name and fare
   {'Name': 'Cumings Mrs. John', 'Fare': 71.28}
   {'Name': 'Futrelle Mrs. Jacques', 'Fare': 53.1}
   {'Name': 'Passenger 11', 'Fare': 104.75}
   {'Name': 'Passenger 16', 'Fare': 88.46}
   {'Name': 'Passenger 26', 'Fare': 112.91}
   {'Name': 'Passenger 34', 'Fare': 66.7}
   {'Name': 'Passenger 36', 'Fare': 47.85}
   {'Name': 'Passenger 41', 'Fare': 78.42}
   {'Name': 'Passenger 50', 'Fare': 110.53}
   {'Name': 'Passenger 52', 'Fare': 76.09}
   {'Name': 'Passenger 58', 'Fare': 42.29}

### Task 5 - Documents with missing Age ($exists / null) -> fill with the median age
missing before: 9, median age: 30.0, updated: 9, missing after: 0

### Task 6 - Encode Sex (male=0, female=1) and Embarked (S=0, C=1, Q=2) with update_many
{'PassengerId': 2, 'Survived': 1, 'Pclass': 1, 'Name': 'Cumings Mrs. John', 'Sex': 1, 'Age': 38.0, 'Fare': 71.28, 'Embarked': 1}

### Task 7 - Survival rate per Pclass (aggregation pipeline)
  Pclass 1: 19 passengers, survival rate 57.89%
  Pclass 2: 13 passengers, survival rate 38.46%
  Pclass 3: 28 passengers, survival rate 32.14%

### Task 8 - Load the cleaned data back into a DataFrame from find()
PassengerId      int64
Survived         int64
Pclass           int64
Name               str
Sex              int64
Age            float64
Fare           float64
Embarked         int64
rows: 60 | missing values: 0

### Task 9 - 80/20 split, Logistic Regression, accuracy
train rows 48, test rows 12, accuracy on the test set: 1.000

### Task 10 - Store each passenger's predicted label in the document (field predicted)
documents with a prediction: 60
{'PassengerId': 1, 'Survived': 0, 'Pclass': 3, 'Name': 'Braund Mr. Owen', 'Sex': 0, 'Age': 22.0, 'Fare': 7.25, 'Embarked': 0, 'predicted': 0}

### Task 11 - Insert a results document {model, accuracy, date} into the results collection
{'model': 'LogisticRegression', 'accuracy': 1.0, 'date': datetime.datetime(2026, 10, 30, 5, 29, 41, 39000)}

### Task 12 - Delete passengers with Fare = 0 and print the remaining count
deleted: 1 | remaining: 59
```
