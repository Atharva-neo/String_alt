#!/usr/bin/env python3
"""Graph Task 10 - load hospital data from MongoDB into Neo4j and keep the graph growing from the MongoDB change stream.

  pip install pymongo neo4j
  export NEO4J_URI=bolt://localhost:7687 NEO4J_USER=neo4j NEO4J_PASSWORD=<your password> MONGODB_URI="mongodb://localhost:27017/?replicaSet=rs0"
  python neo4j/live_loader.py --initial        # one-time full load of the existing MongoDB documents
  python neo4j/live_loader.py                  # then: follow the change stream (appointments, billing, prescriptions)
Open Neo4j Browser (http://localhost:7474) and run  MATCH p=(:Patient)-[*..4]-() RETURN p LIMIT 100  - insert a new appointment/bill in MongoDB
(or run realtime/generator.py) and re-run / use the auto-refresh: new nodes and relationships appear without reloading the page.

Every statement uses MERGE and PARAMETERS (never string formatting), so replays are harmless and Cypher injection is impossible.
"""
import argparse
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from backend.db import get_db, supports_change_streams

try:
    from neo4j import GraphDatabase
except ImportError:
    raise SystemExit("pip install neo4j")

Q_PATIENT = "MERGE (p:Patient {id:$id}) SET p.name=$name, p.age=$age, p.gender=$gender, p.blood_group=$bg, p.phone=$phone, p.city=$city"
Q_DOCTOR = ("MERGE (d:Doctor {id:$id}) SET d.name=$name, d.specialization=$spec, d.fee=$fee, d.phone=$phone "
            "MERGE (x:Department {name:$spec}) MERGE (d)-[:WORKS_IN]->(x)")
Q_APPT = ("MERGE (a:Appointment {id:$id}) SET a.date=datetime($date), a.status=$status, a.reason=$reason "
          "MERGE (p:Patient {id:$pid}) MERGE (d:Doctor {id:$did}) MERGE (p)-[:BOOKED]->(a) MERGE (a)-[:WITH]->(d)")
Q_RX = ("MERGE (r:Prescription {id:$id}) SET r.diagnosis=$diagnosis "
        "WITH r MATCH (a:Appointment {id:$aid}) MERGE (a)-[:RESULTED_IN]->(r) "
        "WITH r UNWIND $meds AS m MERGE (x:Medicine {name:m.name}) MERGE (r)-[c:CONTAINS]->(x) SET c.dose=m.dose, c.days=m.days")
Q_BILL = ("MERGE (b:Bill {id:$id}) SET b.total=$total, b.status=$status, b.date=date($date) "
          "MERGE (p:Patient {id:$pid}) MERGE (p)-[:BILLED]->(b) "
          "WITH b MATCH (a:Appointment {id:$aid}) MERGE (b)-[:FOR]->(a)")


def sync(session, coll, d):
    iso = lambda x: x.isoformat() if hasattr(x, "isoformat") else str(x)
    if coll == "patients":
        c = d.get("contact", {}); session.run(Q_PATIENT, id=d["_id"], name=d.get("name"), age=d.get("age"), gender=d.get("gender"), bg=d.get("blood_group"), phone=c.get("phone"), city=c.get("city"))
    elif coll == "doctors":
        session.run(Q_DOCTOR, id=d["_id"], name=d["name"], spec=d["specialization"], fee=d["fee"], phone=d.get("phone"))
    elif coll == "appointments":
        session.run(Q_APPT, id=d["_id"], date=iso(d["date"]), status=d["status"], reason=d.get("reason", ""), pid=d["patient_id"], did=d["doctor_id"])
    elif coll == "prescriptions":
        session.run(Q_RX, id=d["_id"], diagnosis=d["diagnosis"], aid=d["appointment_id"], meds=d["medicines"])
    elif coll == "billing":
        session.run(Q_BILL, id=d["_id"], total=d["total"], status=d["status"], date=iso(d["date"])[:10], pid=d["patient_id"], aid=d["appointment_id"])


def main():
    ap = argparse.ArgumentParser(); ap.add_argument("--initial", action="store_true"); a = ap.parse_args()
    driver = GraphDatabase.driver(os.environ.get("NEO4J_URI", "bolt://localhost:7687"), auth=(os.environ.get("NEO4J_USER", "neo4j"), os.environ["NEO4J_PASSWORD"]))
    db = get_db()
    with driver.session() as s:
        if a.initial:
            for coll in ("patients", "doctors", "appointments", "prescriptions", "billing"):     # order matters: parents before children
                n = 0
                for d in db[coll].find():
                    sync(s, coll, d); n += 1
                print(f"loaded {n} {coll}")
        if not supports_change_streams():
            print("No change stream available (standalone MongoDB). Initial load done; start a replica set to follow live inserts.")
            return
        print("following the change stream ... (Ctrl+C to stop)")
        with db.watch([{"$match": {"operationType": {"$in": ["insert", "update", "replace"]}}}], full_document="updateLookup") as stream:
            for ev in stream:
                coll = ev["ns"]["coll"]
                if coll in ("patients", "doctors", "appointments", "prescriptions", "billing") and ev.get("fullDocument"):
                    sync(s, coll, ev["fullDocument"])
                    print(f"synced {coll} {ev['fullDocument']['_id']}", flush=True)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nstopped")
