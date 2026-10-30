"""Connection helper for the hospital project. Configuration only from environment variables (see the repository .env.example).

  MONGODB_URI     e.g. mongodb://localhost:27017/?replicaSet=rs0      (change streams need a replica set or Atlas)
  MONGODB_DB      database name, default hospitalDB
  USE_MOCK_MONGO  1 = in-memory mongomock (TEST AID ONLY: no change streams, data lives in this process only)
"""
import os
import sys

_client = None


def get_client():
    global _client
    if _client is None:
        if os.environ.get("USE_MOCK_MONGO") == "1":
            import mongomock
            print("[!] USE_MOCK_MONGO=1 -> in-memory mongomock, NOT a real MongoDB server", file=sys.stderr)
            _client = mongomock.MongoClient()
        else:
            import pymongo
            _client = pymongo.MongoClient(os.environ.get("MONGODB_URI", "mongodb://localhost:27017"), serverSelectionTimeoutMS=4000)
            _client.admin.command("ping")
    return _client


def get_db():
    return get_client()[os.environ.get("MONGODB_DB", "hospitalDB")]


def supports_change_streams():
    """True only on a replica set / sharded cluster / Atlas (a standalone mongod rejects watch())."""
    if os.environ.get("USE_MOCK_MONGO") == "1":
        return False
    try:
        hello = get_client().admin.command("hello")
        return "setName" in hello or hello.get("msg") == "isdbgrid"
    except Exception:
        return False
