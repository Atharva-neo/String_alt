"""LiveFeed: a background thread that tells the dashboard "something changed".

* change-stream mode  - db.watch() (needs a replica set): every insert/update pushes an event => version += 1
* polling fallback    - standalone MongoDB / mock: compares document counts every 2 s. The dashboard shows which mode is active,
                        so a polling dashboard is never presented as a change-stream one.
"""
import sys
import threading
import time
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from backend.db import get_db, supports_change_streams

WATCHED = ("appointments", "billing", "prescriptions")


class LiveFeed:
    def __init__(self):
        self.version = 0
        self.events = deque(maxlen=12)
        self.mode = "change stream" if supports_change_streams() else "polling fallback (no replica set)"
        self._lock = threading.Lock()
        threading.Thread(target=self._run_stream if self.mode == "change stream" else self._run_poll, daemon=True).start()

    def _bump(self, text):
        with self._lock:
            self.version += 1
            self.events.appendleft(f"{time.strftime('%H:%M:%S')}  {text}")

    def _run_stream(self):
        db = get_db()
        pipeline = [{"$match": {"operationType": {"$in": ["insert", "update", "replace", "delete"]}, "ns.coll": {"$in": list(WATCHED)}}}]
        while True:                                            # re-open the stream if the connection drops
            try:
                with db.watch(pipeline, full_document="updateLookup") as stream:
                    for ev in stream:
                        doc = ev.get("fullDocument") or {}
                        self._bump(f"{ev['operationType']} {ev['ns']['coll']} {doc.get('_id', '')}")
            except Exception as e:
                self._bump(f"stream error: {type(e).__name__}; retrying")
                time.sleep(3)

    def _run_poll(self):
        db, last = get_db(), None
        while True:
            now = {c: db[c].count_documents({}) for c in WATCHED}
            if last is not None and now != last:
                self._bump("count changed: " + ", ".join(f"{c}={n}" for c, n in now.items()))
            last = now
            time.sleep(2)
