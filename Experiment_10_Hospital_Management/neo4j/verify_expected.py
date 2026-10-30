#!/usr/bin/env python3
"""Independent re-implementation of the graph queries 3-9 on the PDF's edge list (plain Python, no Neo4j needed).
It computes the answers the Cypher queries must return and checks the node/relationship counts of load_graph.cypher.
This is NOT an execution of Cypher; it is a cross-check of the expected results.      python neo4j/verify_expected.py
"""
from collections import defaultdict, deque

E = {  # relationship type -> list of (from, to)
    "BOOKED": [("PT01", "A1001"), ("PT02", "A1002"), ("PT03", "A1003"), ("PT03", "A1004")],
    "WITH": [("A1001", "D1"), ("A1002", "D3"), ("A1003", "D2"), ("A1004", "D1")],
    "WORKS_IN": [("D1", "Cardiology"), ("D2", "Orthopedics"), ("D3", "General Medicine")],
    "RESULTED_IN": [("A1001", "RX01"), ("A1002", "RX02"), ("A1004", "RX03")],
    "CONTAINS": [("RX01", "Aspirin 75"), ("RX01", "Atorvastatin 10"), ("RX02", "Paracetamol 500"), ("RX03", "Aspirin 75"), ("RX03", "Metoprolol 25")],
    "BILLED": [("PT01", "BL01"), ("PT02", "BL02"), ("PT03", "BL03")],
    "FOR": [("BL01", "A1001"), ("BL02", "A1002"), ("BL03", "A1004")],
}
NAMES = {"PT01": "Ramesh Jadhav", "PT02": "Sunita More", "PT03": "Vikram Shinde", "D1": "Dr. Anjali Deshmukh", "D2": "Dr. Rahul Kulkarni", "D3": "Dr. Sneha Patil"}
APPT_DAY = {"A1001": "2026-10-27", "A1002": "2026-10-27", "A1003": "2026-10-28", "A1004": "2026-10-28"}
BILL = {"BL01": (1000, "Paid"), "BL02": (300, "Pending"), "BL03": (900, "Pending")}
out = lambda rel, a: [t for f, t in E[rel] if f == a]
into = lambda rel, b: [f for f, t in E[rel] if t == b]
nodes = {n for pairs in E.values() for p in pairs for n in p}
print(f"nodes: {len(nodes)} (expected 3 patients + 3 doctors + 3 departments + 4 appointments + 3 prescriptions + 4 medicines + 3 bills = 23)")
print("relationships:", sum(len(v) for v in E.values()), "(expected 25)")

print("\nTask 3 - patients treated by D1:", sorted({NAMES[p] for p in {f for f, a in E['BOOKED'] for a2, d in E['WITH'] if a2 == a and d == 'D1'}}))
print("Task 4 - departments visited by PT03:", sorted({dep for a in out('BOOKED', 'PT03') for d in out('WITH', a) for dep in out('WORKS_IN', d)}))
meds = lambda p: {m for a in out('BOOKED', p) for r in out('RESULTED_IN', a) for m in out('CONTAINS', r)}
print("Task 5 - patients sharing a medicine with PT01:", {NAMES[p]: sorted(meds('PT01') & meds(p)) for p in ('PT02', 'PT03') if meds('PT01') & meds(p)})
cnt = defaultdict(int)
for a, d in E["WITH"]:
    if APPT_DAY[a] == "2026-10-27":
        cnt[NAMES[d]] += 1
print("Task 6 - appointments on 2026-10-27 per doctor:", dict(cnt))
print("Task 7 - pending bills:", [(NAMES[p], b, BILL[b][0], NAMES[d]) for p, b in E['BILLED'] if BILL[b][1] == 'Pending' for a in out('FOR', b) for d in out('WITH', a)])
adj = defaultdict(set)
for rel in ("BOOKED", "WITH"):
    for f, t in E[rel]:
        adj[f].add(t); adj[t].add(f)
def bfs(s, g):
    q, prev = deque([s]), {s: None}
    while q:
        u = q.popleft()
        if u == g:
            path = []
            while u: path.append(NAMES.get(u, u)); u = prev[u]
            return path[::-1]
        for v in sorted(adj[u]):
            if v not in prev: prev[v] = u; q.append(v)
route = bfs("PT01", "PT03")
print("Task 8 - shortest path PT01 -> PT03:", route, "hops =", len(route) - 1)
dep = defaultdict(set)
for p, a in E["BOOKED"]:
    for d in out("WITH", a):
        for x in out("WORKS_IN", d):
            dep[x].add(p)
print("Task 9 - patients per department:", {k: len(v) for k, v in sorted(dep.items())})
