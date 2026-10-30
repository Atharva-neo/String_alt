#!/usr/bin/env python3
"""Task 11 - change stream: prints every new appointment / bill / prescription as it is inserted.

Change streams require a REPLICA SET (or MongoDB Atlas). Single-node replica set for local use:
    mongod --replSet rs0 --dbpath <dir> --port 27017        then once:  mongosh --eval "rs.initiate()"
    export MONGODB_URI="mongodb://localhost:27017/?replicaSet=rs0"
  python realtime/watcher.py
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from backend.db import get_db, supports_change_streams


def main():
    if not supports_change_streams():
        print("This MongoDB deployment does not support change streams (standalone server or mock).\n"
              "Start a single-node replica set - see the docstring of this file - and set MONGODB_URI with ?replicaSet=rs0.")
        raise SystemExit(2)
    db = get_db()
    pipeline = [{"$match": {"operationType": {"$in": ["insert", "update"]}, "ns.coll": {"$in": ["appointments", "billing", "prescriptions"]}}}]
    print(f"watching {db.name}.(appointments|billing|prescriptions) ... (Ctrl+C to stop)")
    with db.watch(pipeline, full_document="updateLookup") as stream:               # blocks; yields one event per change
        for ev in stream:
            doc = ev.get("fullDocument") or {}
            coll = ev["ns"]["coll"]
            if coll == "appointments":
                print(f"[{ev['operationType']}] appointment {doc.get('_id')}: {doc.get('patient_id')} -> {doc.get('doctor_id')} {doc.get('status')} ({doc.get('reason')})", flush=True)
            elif coll == "billing":
                print(f"[{ev['operationType']}] bill {doc.get('_id')}: {doc.get('total')} {doc.get('status')}", flush=True)
            else:
                print(f"[{ev['operationType']}] prescription {doc.get('_id')}: {doc.get('diagnosis')}", flush=True)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nstopped")
