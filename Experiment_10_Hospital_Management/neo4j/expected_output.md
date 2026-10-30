# Neo4j expected results

> The Cypher in this folder was **not executed** (no Neo4j server was available). The answers below were computed by `python neo4j/verify_expected.py`, an independent plain-Python re-implementation of every query on the PDF edge list. Running `queries.cypher` in Neo4j must return the same.

```text
nodes: 23 (expected 3 patients + 3 doctors + 3 departments + 4 appointments + 3 prescriptions + 4 medicines + 3 bills = 23)
relationships: 25 (expected 25)

Task 3 - patients treated by D1: ['Ramesh Jadhav', 'Vikram Shinde']
Task 4 - departments visited by PT03: ['Cardiology', 'Orthopedics']
Task 5 - patients sharing a medicine with PT01: {'Vikram Shinde': ['Aspirin 75']}
Task 6 - appointments on 2026-10-27 per doctor: {'Dr. Anjali Deshmukh': 1, 'Dr. Sneha Patil': 1}
Task 7 - pending bills: [('Sunita More', 'BL02', 300, 'Dr. Sneha Patil'), ('Vikram Shinde', 'BL03', 900, 'Dr. Anjali Deshmukh')]
Task 8 - shortest path PT01 -> PT03: ['Ramesh Jadhav', 'A1001', 'Dr. Anjali Deshmukh', 'A1004', 'Vikram Shinde'] hops = 4
Task 9 - patients per department: {'Cardiology': 2, 'General Medicine': 1, 'Orthopedics': 1}
```
