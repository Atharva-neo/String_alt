#!/usr/bin/env python3
"""8F - MySQL and MongoDB in one application (product catalogue): relational -> document conversion, verification, sync (Tasks 1-12)."""
import statistics
import sys
import time
from pathlib import Path

import mysql.connector

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "common"))
from dbconn import get_mongo, heading, mysql_config

heading(1, "Connect to MySQL (mysql-connector-python) and MongoDB (pymongo)")
sql_conn = mysql.connector.connect(**mysql_config())
print("MySQL connected, server", sql_conn.server_info)
client = get_mongo()
print("MongoDB connected, databases visible:", "ok")
cur = sql_conn.cursor(dictionary=True)

heading(2, "Create the three MySQL tables with keys and constraints and insert the data")
cur.execute("DROP DATABASE IF EXISTS catalog_8f")
cur.execute("CREATE DATABASE catalog_8f")
sql_conn.database = "catalog_8f"
cur.execute("CREATE TABLE category (cat_id INT PRIMARY KEY, name VARCHAR(30) NOT NULL UNIQUE) ENGINE=InnoDB")
cur.execute("""CREATE TABLE product (prod_id INT PRIMARY KEY, name VARCHAR(40) NOT NULL, cat_id INT NOT NULL,
    price DECIMAL(10,2) NOT NULL, stock INT NOT NULL,
    CONSTRAINT fk_prod_cat FOREIGN KEY (cat_id) REFERENCES category(cat_id), CONSTRAINT chk_price CHECK (price > 0), CONSTRAINT chk_stock CHECK (stock >= 0)) ENGINE=InnoDB""")
cur.execute("""CREATE TABLE review (review_id INT PRIMARY KEY, prod_id INT NOT NULL, `user` VARCHAR(30) NOT NULL, rating INT NOT NULL, comment VARCHAR(100),
    CONSTRAINT fk_rev_prod FOREIGN KEY (prod_id) REFERENCES product(prod_id), CONSTRAINT chk_rating CHECK (rating BETWEEN 1 AND 5)) ENGINE=InnoDB""")
cur.executemany("INSERT INTO category VALUES (%s, %s)", [(1, "Electronics"), (2, "Stationery"), (3, "Home")])
cur.executemany("INSERT INTO product VALUES (%s, %s, %s, %s, %s)",
                [(101, "Headphones", 1, 1500, 20), (102, "Power Bank", 1, 1200, 35), (103, "Notebook", 2, 60, 300), (104, "Desk Lamp", 3, 900, 15), (105, "USB Cable", 1, 250, 100)])
cur.executemany("INSERT INTO review VALUES (%s, %s, %s, %s, %s)",
                [(1, 101, "Riya", 5, "Great sound"), (2, 101, "Amit", 4, "Good value"), (3, 102, "Sneha", 3, "Average backup"),
                 (4, 104, "Omkar", 4, "Bright light"), (5, 105, "Neha", 2, "Stopped working")])
sql_conn.commit()
for t in ("category", "product", "review"):
    cur.execute(f"SELECT COUNT(*) AS n FROM {t}")
    print(f"{t:<9}: {cur.fetchone()['n']} rows")

heading(3, "Read each product with its category name using a JOIN")
cur.execute("SELECT p.prod_id, p.name, c.name AS category, p.price, p.stock FROM product p JOIN category c ON c.cat_id = p.cat_id ORDER BY p.prod_id")
products = cur.fetchall()
for p in products:
    print("  ", p)

heading(4, "Convert every product into the MongoDB document shape (embedded category + reviews)")
docs = []
for p in products:
    cur.execute("SELECT cat_id FROM product WHERE prod_id = %s", (p["prod_id"],))
    cat_id = cur.fetchone()["cat_id"]
    cur.execute("SELECT `user`, rating, comment FROM review WHERE prod_id = %s ORDER BY review_id", (p["prod_id"],))
    docs.append({"_id": p["prod_id"], "name": p["name"], "price": float(p["price"]), "stock": p["stock"],
                 "category": {"id": cat_id, "name": p["category"]}, "reviews": cur.fetchall()})
print(docs[0])

heading(5, "Insert the documents with insert_many")
mdb = client["catalogDB"]
mdb.drop_collection("products")
print("inserted:", len(mdb["products"].insert_many(docs).inserted_ids))
mcol = mdb["products"]

heading(6, "Verify that the product count is the same in MySQL and MongoDB")
cur.execute("SELECT COUNT(*) AS n FROM product")
n_sql, n_mongo = cur.fetchone()["n"], mcol.count_documents({})
print(f"MySQL {n_sql} | MongoDB {n_mongo} | equal: {n_sql == n_mongo}")

QUERY_SQL = ("SELECT p.prod_id FROM product p JOIN category c ON c.cat_id = p.cat_id WHERE c.name = %s AND p.price > %s ORDER BY p.prod_id")


def q7_sql():
    cur.execute(QUERY_SQL, ("Electronics", 1000))
    return [r["prod_id"] for r in cur.fetchall()]


def q7_mongo():
    return sorted(d["_id"] for d in mcol.find({"category.name": "Electronics", "price": {"$gt": 1000}}, {"_id": 1}))


heading(7, "Electronics products priced above 1000 in both databases")
a, b = q7_sql(), q7_mongo()
print("MySQL (WHERE + JOIN):", a, "\nMongoDB (find)       :", b, "\nresults match:", a == b)

heading(8, "Average rating per product in both (GROUP BY vs $unwind + $group)")
cur.execute("SELECT prod_id, ROUND(AVG(rating), 2) AS avg_rating FROM review GROUP BY prod_id ORDER BY prod_id")
sql_avg = {r["prod_id"]: float(r["avg_rating"]) for r in cur.fetchall()}
mongo_avg = {r["_id"]: round(r["avg"], 2) for r in mcol.aggregate([{"$unwind": "$reviews"}, {"$group": {"_id": "$_id", "avg": {"$avg": "$reviews.rating"}}}])}
print("MySQL  :", sql_avg, "\nMongoDB:", dict(sorted(mongo_avg.items())), "\nmatch:", sql_avg == dict(sorted(mongo_avg.items())))

heading(9, "Update the price of product 102 to 1100 in MySQL and sync it to MongoDB (update_one)")
cur.execute("UPDATE product SET price = %s WHERE prod_id = %s", (1100, 102))
sql_conn.commit()
mcol.update_one({"_id": 102}, {"$set": {"price": 1100.0}})
cur.execute("SELECT price FROM product WHERE prod_id = 102")
print("MySQL price:", cur.fetchone()["price"], "| MongoDB price:", mcol.find_one({"_id": 102})["price"])

heading(10, "Delete product 105 from both databases inside try/except so a failure in either is reported")
try:
    cur.execute("DELETE FROM product WHERE prod_id = %s", (105,))        # first attempt violates the FK from review
    sql_conn.commit()
except mysql.connector.Error as e:
    sql_conn.rollback()
    print(f"MySQL delete failed (as expected, reviews reference the product): errno {e.errno}: {e.msg}")
try:
    cur.execute("DELETE FROM review WHERE prod_id = %s", (105,))          # child rows first, then the parent, in one transaction
    cur.execute("DELETE FROM product WHERE prod_id = %s", (105,))
    sql_conn.commit()
    print("MySQL: reviews + product 105 deleted")
except mysql.connector.Error as e:
    sql_conn.rollback()
    print("MySQL FAILED:", e)
try:
    print("MongoDB: deleted", mcol.delete_one({"_id": 105}).deleted_count, "document")
except Exception as e:                                                     # pymongo.errors.PyMongoError in real life
    print("MongoDB FAILED:", e)
cur.execute("SELECT COUNT(*) AS n FROM product")
print("counts now - MySQL:", cur.fetchone()["n"], "MongoDB:", mcol.count_documents({}))

heading(11, "Time the query of Task 7 on both databases with time.perf_counter()")
def timed(fn, repeat=200):
    samples = []
    for _ in range(repeat):
        t0 = time.perf_counter(); fn(); samples.append(time.perf_counter() - t0)
    return statistics.median(samples) * 1000
print(f"MySQL   : {timed(q7_sql):.3f} ms (median of 200 runs)\nMongoDB : {timed(q7_mongo):.3f} ms (median of 200 runs)")
print("Note: with 4 rows both are dominated by network/driver overhead; the comparison only becomes meaningful on large data with indexes.")

heading(12, "Node.js script with mysql2 and mongodb that prints the product count of each database")
print("Run:  node node_count.js   (see this folder; output recorded in node_count_output.md)")
cur.close()
sql_conn.close()
