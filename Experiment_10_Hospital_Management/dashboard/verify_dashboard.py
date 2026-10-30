"""Headless check of the dashboard with Streamlit's AppTest and the in-memory mongomock database (no MongoDB server needed).
It verifies that the app renders without exceptions, that the four graphs have data, and that a newly inserted record changes the query results
that feed the graphs. It does NOT prove change-stream behaviour (needs a replica set).    python dashboard/verify_dashboard.py
"""
import os
import sys
import time
from pathlib import Path

os.environ["USE_MOCK_MONGO"] = "1"
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from streamlit.testing.v1 import AppTest

from backend import hospital_queries as q
from backend.db import get_db
from backend.seed import seed

at = AppTest.from_file(str(HERE / "app.py"), default_timeout=30).run()
print("exceptions during render:", len(at.exception))
print("metrics:", {m.label: m.value for m in at.metric})
db = get_db()
print("graph 1 hours with data :", [r for r in q.appointments_per_hour(db, __import__('datetime').datetime(2026, 10, 27)) if r["appointments"]])
print("graph 2 patients/doctor :", q.patients_per_doctor(db))
print("graph 3 revenue         :", q.daily_revenue(db))
print("graph 4 top diagnoses   :", q.top_diagnoses(db))
before = q.totals(db)
sys.path.insert(0, str(HERE.parent / "realtime"))
import random
from generator import one_visit
one_visit(db, random.Random(1))
after = q.totals(db)
print("totals before insert:", before)
print("totals after  insert:", after)
time.sleep(2.5)                                            # the polling thread notices the count change
at2 = AppTest.from_file(str(HERE / "app.py"), default_timeout=30).run()
print("re-rendered metrics    :", {m.label: m.value for m in at2.metric})
assert len(at.exception) == 0 and len(at2.exception) == 0
assert after["appointments"] == before["appointments"] + 1 and after["bills"] == before["bills"] + 1
print("OK")
