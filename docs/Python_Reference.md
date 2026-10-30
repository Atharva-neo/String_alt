# Python reference for Experiments 5D, 8, 10

## MySQL (mysql-connector-python)
```python
import mysql.connector
conn = mysql.connector.connect(host=..., user=..., password=..., database=...)       # values from os.environ
cur = conn.cursor(dictionary=True)
cur.execute("SELECT * FROM t WHERE id = %s", (5,))          # ALWAYS placeholders -> no SQL injection
cur.executemany("INSERT INTO t VALUES (%s, %s)", rows); conn.commit()
cur.callproc("pay_fee", (104, 5000)); [rs.fetchall() for rs in cur.stored_results()]
conn.autocommit = False; ... conn.rollback()
except mysql.connector.Error as e: e.errno, e.sqlstate, e.msg        # finally: cur.close(); conn.close()
```
## PyMongo
```python
from pymongo import MongoClient
col = MongoClient(uri)["mlDB"]["titanic"]
col.insert_many(docs); col.find({"Sex": "female"}, {"_id": 0, "Name": 1}); col.count_documents({})
col.update_many({"Age": None}, {"$set": {"Age": 30.0}})   # None matches null and missing
col.aggregate([{"$group": {"_id": "$Pclass", "rate": {"$avg": "$Survived"}}}])
col.create_index("location"); col.index_information(); col.delete_many({"Fare": 0})
with db.watch([...]) as stream: for ev in stream: ...        # change stream (replica set)
```
## pandas / scikit-learn pipeline
```python
df = pd.DataFrame(list(col.find({}, {"_id": 0})))
df["Age"] = df["Age"].fillna(df["Age"].median())            # missing values
pd.get_dummies(df, columns=["location"])                    # one-hot encoding
StandardScaler().fit_transform(df[["area"]])                # scaling
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
LogisticRegression().fit(X_train, y_train); accuracy_score(y_test, model.predict(X_test))
LinearRegression() -> r2_score;  TfidfVectorizer() + MultinomialNB() -> confusion_matrix
```
Rules used in this repo: parameterised queries only; credentials from environment variables; `random_state`/seeds fixed so outputs are reproducible; close cursors and connections in `finally`.
## Node.js
`express`, `mongodb` (`MongoClient`, `ObjectId`), `mysql2/promise` (`execute()` = prepared statement). One client for the whole process; validate input; 400/404 status codes.
