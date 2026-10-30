// Graph Tasks 3 - 9 (Cypher, Neo4j 5). Parameters can be set in Neo4j Browser with  :param doctor => 'D1'
// ---- Task 3: all patients treated by a given doctor
:param doctor => 'D1';
MATCH (p:Patient)-[:BOOKED]->(:Appointment)-[:WITH]->(d:Doctor {id: $doctor})
RETURN DISTINCT d.name AS doctor, p.id AS patient_id, p.name AS patient ORDER BY patient_id;

// ---- Task 4: departments a patient has visited (3-hop path Patient -> Appointment -> Doctor -> Department)
:param patient => 'PT03';
MATCH (p:Patient {id: $patient})-[:BOOKED]->(:Appointment)-[:WITH]->(:Doctor)-[:WORKS_IN]->(dep:Department)
RETURN p.name AS patient, collect(DISTINCT dep.name) AS departments;

// ---- Task 5: patients prescribed the same medicine as PT01
MATCH (p1:Patient {id:'PT01'})-[:BOOKED]->(:Appointment)-[:RESULTED_IN]->(:Prescription)-[:CONTAINS]->(m:Medicine)
      <-[:CONTAINS]-(:Prescription)<-[:RESULTED_IN]-(:Appointment)<-[:BOOKED]-(p2:Patient)
WHERE p2 <> p1
RETURN p2.id AS patient_id, p2.name AS patient, collect(DISTINCT m.name) AS shared_medicines;

// ---- Task 6: doctors with the most appointments on a given day (the sample "today" is 2026-10-27; use date() on a live system)
:param day => date('2026-10-27');
MATCH (a:Appointment)-[:WITH]->(d:Doctor)
WHERE date(a.date) = $day
RETURN d.name AS doctor, count(a) AS appointments ORDER BY appointments DESC, doctor;

// ---- Task 7: patients with pending bills and the doctor they saw
MATCH (p:Patient)-[:BILLED]->(b:Bill {status:'Pending'})-[:FOR]->(:Appointment)-[:WITH]->(d:Doctor)
RETURN p.name AS patient, b.id AS bill, b.total AS amount, d.name AS doctor ORDER BY bill;

// ---- Task 8: shortest path between two patients through shared doctors (relationship direction ignored)
MATCH (p1:Patient {id:'PT01'}), (p3:Patient {id:'PT03'}),
      path = shortestPath((p1)-[:BOOKED|WITH*..8]-(p3))
RETURN [n IN nodes(path) | coalesce(n.name, n.id)] AS route, length(path) AS hops;

// ---- Task 9: patients per department
MATCH (p:Patient)-[:BOOKED]->(:Appointment)-[:WITH]->(:Doctor)-[:WORKS_IN]->(dep:Department)
RETURN dep.name AS department, count(DISTINCT p) AS patients ORDER BY patients DESC, department;
