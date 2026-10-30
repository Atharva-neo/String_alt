# Dashboard verification output

> Real output of `python dashboard/verify_dashboard.py` (Streamlit AppTest, in-memory mongomock, polling mode). It proves the app renders without exceptions and that an insert changes the data behind the four graphs. It does **not** prove change-stream delivery (needs a replica set). Date: 2026-10-30.

```text
exceptions during render: 0
metrics: {'Appointments': '4', 'Bills': '3', 'Paid (Rs)': '1000', 'Pending (Rs)': '1200'}
graph 1 hours with data : [{'hour': 10, 'appointments': 1}, {'hour': 11, 'appointments': 1}]
graph 2 patients/doctor : [{'doctor': 'Dr. Anjali Deshmukh', 'specialization': 'Cardiology', 'patients': 2}, {'doctor': 'Dr. Rahul Kulkarni', 'specialization': 'Orthopedics', 'patients': 1}, {'doctor': 'Dr. Sneha Patil', 'specialization': 'General Medicine', 'patients': 1}]
graph 3 revenue         : [{'day': '2026-10-27', 'status': 'Paid', 'amount': 1000}, {'day': '2026-10-27', 'status': 'Pending', 'amount': 300}, {'day': '2026-10-28', 'status': 'Pending', 'amount': 900}]
graph 4 top diagnoses   : [{'diagnosis': 'Angina', 'cases': 1}, {'diagnosis': 'Arrhythmia', 'cases': 1}, {'diagnosis': 'Viral fever', 'cases': 1}]
totals before insert: {'appointments': 4, 'bills': 3, 'paid': 1000, 'pending': 1200}
totals after  insert: {'appointments': 5, 'bills': 4, 'paid': 1000, 'pending': 1800}
re-rendered metrics    : {'Appointments': '5', 'Bills': '4', 'Paid (Rs)': '1000', 'Pending (Rs)': '1800'}
OK

```
