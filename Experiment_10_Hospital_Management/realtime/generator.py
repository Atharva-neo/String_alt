#!/usr/bin/env python3
"""Task 11 - data generator: inserts a random appointment (+ its bill, and a prescription for half of them) every N seconds.

  python realtime/generator.py                      # every 5 seconds until Ctrl+C
  python realtime/generator.py --interval 2 --count 20
Run it in one terminal, realtime/watcher.py (change stream) in another and the dashboard in a third: the graphs move with every insert.
"""
import argparse
import random
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from backend.db import get_db

DIAGNOSES = {"Angina": [("Aspirin 75", "1-0-0", 30), ("Atorvastatin 10", "0-0-1", 30)], "Viral fever": [("Paracetamol 500", "1-1-1", 3)],
             "Arrhythmia": [("Metoprolol 25", "1-0-1", 30), ("Aspirin 75", "1-0-0", 30)], "Hypertension": [("Amlodipine 5", "1-0-0", 60)],
             "Knee sprain": [("Ibuprofen 400", "1-0-1", 5)], "Diabetes": [("Metformin 500", "1-0-1", 90)]}
REASONS = ["Chest pain", "Fever", "Knee pain", "Headache", "Routine check-up", "Palpitations", "Back pain"]


def one_visit(db, rng):
    patients = [p["_id"] for p in db.patients.find({}, {"_id": 1})]
    doctors = list(db.doctors.find({}, {"_id": 1, "fee": 1}))
    if not patients or not doctors:
        raise SystemExit("patients/doctors are empty - load the sample data first (mongosh --file database/insert_data.js or python -m backend.seed)")
    now = datetime.now(timezone.utc).replace(tzinfo=None, microsecond=0)         # stored as UTC (naive in PyMongo = UTC)
    stamp = int(time.time() * 1000) % 10**9
    doc = rng.choice(doctors)
    appt = {"_id": f"A{stamp}", "patient_id": rng.choice(patients), "doctor_id": doc["_id"], "date": now,
            "status": rng.choice(["Scheduled", "Completed"]), "reason": rng.choice(REASONS)}
    db.appointments.insert_one(appt)                                               # <- first change-stream event
    extras = rng.choice([[], [("ECG", 400)], [("Lab test", 250)], [("X-ray", 350)]])
    items = [{"desc": "Consultation", "amount": doc["fee"]}] + [{"desc": d, "amount": a} for d, a in extras]
    bill = {"_id": f"BL{stamp}", "patient_id": appt["patient_id"], "appointment_id": appt["_id"], "items": items,
            "total": sum(i["amount"] for i in items), "status": rng.choice(["Paid", "Pending"]), "date": now.replace(hour=0, minute=0, second=0)}
    db.billing.insert_one(bill)                                                    # <- second change-stream event
    rx = None
    if rng.random() < 0.5:
        dg = rng.choice(list(DIAGNOSES))
        rx = {"_id": f"RX{stamp}", "appointment_id": appt["_id"], "patient_id": appt["patient_id"], "doctor_id": doc["_id"], "diagnosis": dg,
              "medicines": [{"name": n, "dose": d, "days": days} for n, d, days in DIAGNOSES[dg]]}
        db.prescriptions.insert_one(rx)
    return appt, bill, rx


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--interval", type=float, default=5.0)
    ap.add_argument("--count", type=int, default=0, help="stop after N visits (0 = run until Ctrl+C)")
    ap.add_argument("--seed", type=int, default=None)
    a = ap.parse_args()
    rng, db, n = random.Random(a.seed), get_db(), 0
    print(f"inserting a random appointment + bill every {a.interval} s into {db.name} (Ctrl+C to stop)")
    try:
        while a.count == 0 or n < a.count:
            appt, bill, rx = one_visit(db, rng)
            n += 1
            print(f"[{n}] {appt['_id']} {appt['patient_id']} -> {appt['doctor_id']} ({appt['reason']}, {appt['status']}) | bill {bill['_id']} {bill['total']} {bill['status']}" + (f" | {rx['_id']} {rx['diagnosis']}" if rx else ""), flush=True)
            if a.count == 0 or n < a.count:
                time.sleep(a.interval)
    except KeyboardInterrupt:
        print("\nstopped")


if __name__ == "__main__":
    main()
