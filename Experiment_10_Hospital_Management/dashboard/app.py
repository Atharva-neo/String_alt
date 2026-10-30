"""Live hospital dashboard (Streamlit + PyMongo + Plotly).

  streamlit run dashboard/app.py          (from Experiment_10_Hospital_Management/)

How "live" works: dashboard/live.py runs a MongoDB CHANGE STREAM in a background thread. Every insert bumps a version counter.
A Streamlit fragment re-runs every 2 s *in the browser session without reloading the page*, notices the new version and re-queries
MongoDB, so all four graphs update by themselves while realtime/generator.py inserts data.
"""
import os
import sys
from pathlib import Path

import pandas as pd
import plotly.express as px
import streamlit as st

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
from backend import hospital_queries as q
from backend.db import get_db
from live import LiveFeed

st.set_page_config(page_title="Hospital live dashboard", layout="wide")
st.title("Hospital management - live dashboard")


@st.cache_resource
def get_feed():
    db = get_db()
    if os.environ.get("USE_MOCK_MONGO") == "1" and db.patients.count_documents({}) == 0:     # test mode: the mock database starts empty
        from backend.seed import seed
        seed(db)
    return LiveFeed()


feed = get_feed()
db = get_db()
st.caption(f"Database `{db.name}` | update source: **{feed.mode}** | the graphs refresh whenever a change event arrives")


def draw():
    totals = q.totals(db)
    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Appointments", totals["appointments"]); c2.metric("Bills", totals["bills"])
    c3.metric("Paid (Rs)", totals["paid"]); c4.metric("Pending (Rs)", totals["pending"])
    left, right = st.columns(2)
    with left:
        h = pd.DataFrame(q.appointments_per_hour(db))
        st.plotly_chart(px.line(h, x="hour", y="appointments", markers=True, title="1. Appointments per hour (today, UTC)"), width="stretch", key="g1")
        r = pd.DataFrame(q.daily_revenue(db))
        if r.empty:
            st.info("no billing data yet")
        else:
            st.plotly_chart(px.bar(r, x="day", y="amount", color="status", barmode="stack", title="3. Daily revenue: paid vs pending",
                                   color_discrete_map={"Paid": "#2e7d32", "Pending": "#ef6c00"}), width="stretch", key="g3")
    with right:
        p = pd.DataFrame(q.patients_per_doctor(db))
        if not p.empty:
            st.plotly_chart(px.bar(p, x="doctor", y="patients", color="specialization", title="2. Patients per doctor"), width="stretch", key="g2")
        d = pd.DataFrame(q.top_diagnoses(db))
        if not d.empty:
            st.plotly_chart(px.bar(d, x="diagnosis", y="cases", title="4. Top 5 diagnoses"), width="stretch", key="g4")
    st.subheader("Latest change events")
    st.code("\n".join(feed.events) or "(none yet - start realtime/generator.py)")


@st.fragment(run_every="2s")
def live_area():
    if st.session_state.get("seen_version") != feed.version:          # only a change event (new version) triggers a re-query
        st.session_state["seen_version"] = feed.version
    draw()


live_area()
