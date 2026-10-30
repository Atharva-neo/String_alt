"""Shared connection helpers for Experiment 8 (Python side).

Configuration comes from environment variables (see the repository's .env.example); nothing is hard-coded.
  MONGODB_URI   default mongodb://localhost:27017
  MYSQL_HOST / MYSQL_PORT / MYSQL_USER / MYSQL_PWD
  USE_MOCK_MONGO=1   use the in-memory `mongomock` package instead of a MongoDB server (TEST AID ONLY - prints a warning)
"""
import os
import sys


def get_mongo():
    if os.environ.get("USE_MOCK_MONGO") == "1":
        import mongomock
        print("[!] USE_MOCK_MONGO=1 -> using the in-memory mongomock emulation, NOT a real MongoDB server", file=sys.stderr)
        return mongomock.MongoClient()
    import pymongo
    client = pymongo.MongoClient(os.environ.get("MONGODB_URI", "mongodb://localhost:27017"), serverSelectionTimeoutMS=4000)
    client.admin.command("ping")                       # fail early with a clear error if the server is not running
    return client


def mysql_config(**overrides):
    cfg = dict(host=os.environ.get("MYSQL_HOST", "127.0.0.1"), port=int(os.environ.get("MYSQL_PORT", "3306")),
               user=os.environ.get("MYSQL_USER", "root"), password=os.environ.get("MYSQL_PWD", ""))
    cfg.update(overrides)
    return cfg


def heading(n, text):
    print(f"\n### Task {n} - {text}")
