"""Aggregation pipelines of the hospital project (used by the dashboard and by the tests). Each function returns plain Python lists."""
from datetime import datetime, timedelta, timezone


def _day_range(day=None):
    day = day or datetime.now(timezone.utc)
    start = datetime(day.year, day.month, day.day)                 # naive UTC midnight, like the stored dates
    return start, start + timedelta(days=1)


def appointments_per_hour(db, day=None):
    """Graph 1 (line): number of appointments per hour of the given day (default today, UTC)."""
    start, end = _day_range(day)
    rows = db.appointments.aggregate([{"$match": {"date": {"$gte": start, "$lt": end}}},
                                      {"$group": {"_id": {"$hour": "$date"}, "appointments": {"$sum": 1}}}, {"$sort": {"_id": 1}}])
    got = {r["_id"]: r["appointments"] for r in rows}
    return [{"hour": h, "appointments": got.get(h, 0)} for h in range(24)]


def patients_per_doctor(db):
    """Graph 2 (bar): distinct patients per doctor (doctor name via $lookup)."""
    rows = db.appointments.aggregate([
        {"$group": {"_id": "$doctor_id", "patients": {"$addToSet": "$patient_id"}}},
        {"$lookup": {"from": "doctors", "localField": "_id", "foreignField": "_id", "as": "d"}}, {"$unwind": "$d"},
        {"$project": {"_id": 0, "doctor": "$d.name", "specialization": "$d.specialization", "patients": {"$size": "$patients"}}},
        {"$sort": {"doctor": 1}}])
    return list(rows)


def daily_revenue(db):
    """Graph 3 (stacked bar): revenue per day, Paid vs Pending (Cancelled bills ignored)."""
    rows = db.billing.aggregate([
        {"$match": {"status": {"$in": ["Paid", "Pending"]}}},
        {"$group": {"_id": {"day": {"$dateToString": {"format": "%Y-%m-%d", "date": "$date"}}, "status": "$status"}, "amount": {"$sum": "$total"}}},
        {"$sort": {"_id.day": 1, "_id.status": 1}}])
    return [{"day": r["_id"]["day"], "status": r["_id"]["status"], "amount": r["amount"]} for r in rows]


def top_diagnoses(db, n=5):
    """Graph 4 (bar): the n most frequent diagnoses."""
    rows = db.prescriptions.aggregate([{"$group": {"_id": "$diagnosis", "cases": {"$sum": 1}}}, {"$sort": {"cases": -1, "_id": 1}}, {"$limit": n}])
    return [{"diagnosis": r["_id"], "cases": r["cases"]} for r in rows]


def top_medicines(db, n=5):
    rows = db.prescriptions.aggregate([{"$unwind": "$medicines"}, {"$group": {"_id": "$medicines.name", "prescribed": {"$sum": 1}}},
                                       {"$sort": {"prescribed": -1, "_id": 1}}, {"$limit": n}])
    return [{"medicine": r["_id"], "prescribed": r["prescribed"]} for r in rows]


def totals(db):
    pending = list(db.billing.aggregate([{"$match": {"status": "Pending"}}, {"$group": {"_id": None, "amount": {"$sum": "$total"}}}]))
    paid = list(db.billing.aggregate([{"$match": {"status": "Paid"}}, {"$group": {"_id": None, "amount": {"$sum": "$total"}}}]))
    return {"appointments": db.appointments.count_documents({}), "bills": db.billing.count_documents({}),
            "paid": paid[0]["amount"] if paid else 0, "pending": pending[0]["amount"] if pending else 0}
