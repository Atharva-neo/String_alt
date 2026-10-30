"""Loads the sample data of the PDF into hospitalDB with PyMongo (same content as database/insert_data.js).

  python -m backend.seed            (run from Experiment_10_Hospital_Management/)  -> drops and reloads the 5 collections
"""
import sys
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from backend.db import get_db

DOCTORS = [
    {"_id": "D1", "name": "Dr. Anjali Deshmukh", "specialization": "Cardiology", "fee": 600, "phone": "9890011111", "schedule": [{"day": "Mon", "from": "10:00", "to": "14:00"}, {"day": "Thu", "from": "10:00", "to": "14:00"}]},
    {"_id": "D2", "name": "Dr. Rahul Kulkarni", "specialization": "Orthopedics", "fee": 500, "phone": "9890022222", "schedule": [{"day": "Tue", "from": "09:00", "to": "13:00"}]},
    {"_id": "D3", "name": "Dr. Sneha Patil", "specialization": "General Medicine", "fee": 300, "phone": "9890033333", "schedule": [{"day": "Mon-Sat", "from": "09:00", "to": "17:00"}]},
]
PATIENTS = [
    {"_id": "PT01", "name": "Ramesh Jadhav", "age": 58, "gender": "M", "blood_group": "B+", "contact": {"phone": "9765011111", "city": "Sangli"}, "history": ["Hypertension"]},
    {"_id": "PT02", "name": "Sunita More", "age": 34, "gender": "F", "blood_group": "O+", "contact": {"phone": "9765022222", "city": "Miraj"}, "history": []},
    {"_id": "PT03", "name": "Vikram Shinde", "age": 45, "gender": "M", "blood_group": "A+", "contact": {"phone": "9765033333", "city": "Kolhapur"}, "history": ["Diabetes"]},
]
APPOINTMENTS = [
    {"_id": "A1001", "patient_id": "PT01", "doctor_id": "D1", "date": datetime(2026, 10, 27, 10, 30), "status": "Completed", "reason": "Chest pain"},
    {"_id": "A1002", "patient_id": "PT02", "doctor_id": "D3", "date": datetime(2026, 10, 27, 11, 0), "status": "Scheduled", "reason": "Fever"},
    {"_id": "A1003", "patient_id": "PT03", "doctor_id": "D2", "date": datetime(2026, 10, 28, 9, 30), "status": "Scheduled", "reason": "Knee pain"},
    {"_id": "A1004", "patient_id": "PT03", "doctor_id": "D1", "date": datetime(2026, 10, 28, 12, 0), "status": "Completed", "reason": "Palpitations"},   # from the Neo4j sample
]
PRESCRIPTIONS = [
    {"_id": "RX01", "appointment_id": "A1001", "patient_id": "PT01", "doctor_id": "D1", "diagnosis": "Angina", "medicines": [{"name": "Aspirin 75", "dose": "1-0-0", "days": 30}, {"name": "Atorvastatin 10", "dose": "0-0-1", "days": 30}]},
    {"_id": "RX02", "appointment_id": "A1002", "patient_id": "PT02", "doctor_id": "D3", "diagnosis": "Viral fever", "medicines": [{"name": "Paracetamol 500", "dose": "1-1-1", "days": 3}]},
    {"_id": "RX03", "appointment_id": "A1004", "patient_id": "PT03", "doctor_id": "D1", "diagnosis": "Arrhythmia", "medicines": [{"name": "Aspirin 75", "dose": "1-0-0", "days": 30}, {"name": "Metoprolol 25", "dose": "1-0-1", "days": 30}]},
]
BILLING = [
    {"_id": "BL01", "patient_id": "PT01", "appointment_id": "A1001", "items": [{"desc": "Consultation", "amount": 600}, {"desc": "ECG", "amount": 400}], "total": 1000, "status": "Paid", "date": datetime(2026, 10, 27)},
    {"_id": "BL02", "patient_id": "PT02", "appointment_id": "A1002", "items": [{"desc": "Consultation", "amount": 300}], "total": 300, "status": "Pending", "date": datetime(2026, 10, 27)},
    {"_id": "BL03", "patient_id": "PT03", "appointment_id": "A1004", "items": [{"desc": "Consultation", "amount": 600}, {"desc": "Holter test", "amount": 300}], "total": 900, "status": "Pending", "date": datetime(2026, 10, 28)},
]


def seed(db):
    for name, docs in (("doctors", DOCTORS), ("patients", PATIENTS), ("appointments", APPOINTMENTS), ("prescriptions", PRESCRIPTIONS), ("billing", BILLING)):
        db[name].drop()
        db[name].insert_many(docs)
    return {n: db[n].count_documents({}) for n in ("doctors", "patients", "appointments", "prescriptions", "billing")}


if __name__ == "__main__":
    print(seed(get_db()))
