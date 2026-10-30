// Graph Task 1 - create all node labels and relationships for the sample data of the PDF (7 labels, 7 relationship types).
// Idempotent: MERGE never duplicates. Run constraints.cypher first.
// ---------------- nodes ----------------
UNWIND [
  {id:'PT01', name:'Ramesh Jadhav', age:58, gender:'M', blood_group:'B+', phone:'9765011111', city:'Sangli'},
  {id:'PT02', name:'Sunita More',   age:34, gender:'F', blood_group:'O+', phone:'9765022222', city:'Miraj'},
  {id:'PT03', name:'Vikram Shinde', age:45, gender:'M', blood_group:'A+', phone:'9765033333', city:'Kolhapur'}] AS r
MERGE (p:Patient {id:r.id}) SET p += r;

UNWIND [
  {id:'D1', name:'Dr. Anjali Deshmukh', specialization:'Cardiology',       fee:600, phone:'9890011111'},
  {id:'D2', name:'Dr. Rahul Kulkarni',  specialization:'Orthopedics',      fee:500, phone:'9890022222'},
  {id:'D3', name:'Dr. Sneha Patil',     specialization:'General Medicine', fee:300, phone:'9890033333'}] AS r
MERGE (d:Doctor {id:r.id}) SET d += r;

UNWIND ['Cardiology', 'Orthopedics', 'General Medicine'] AS n MERGE (:Department {name:n});

UNWIND [
  {id:'A1001', date:datetime('2026-10-27T10:30:00'), status:'Completed', reason:'Chest pain'},
  {id:'A1002', date:datetime('2026-10-27T11:00:00'), status:'Completed', reason:'Fever'},
  {id:'A1003', date:datetime('2026-10-28T09:30:00'), status:'Scheduled', reason:'Knee pain'},
  {id:'A1004', date:datetime('2026-10-28T12:00:00'), status:'Completed', reason:'Palpitations'}] AS r
MERGE (a:Appointment {id:r.id}) SET a += r;

UNWIND [{id:'RX01', diagnosis:'Angina'}, {id:'RX02', diagnosis:'Viral fever'}, {id:'RX03', diagnosis:'Arrhythmia'}] AS r MERGE (x:Prescription {id:r.id}) SET x += r;
UNWIND ['Aspirin 75', 'Atorvastatin 10', 'Paracetamol 500', 'Metoprolol 25'] AS n MERGE (:Medicine {name:n});
UNWIND [
  {id:'BL01', total:1000, status:'Paid',    date:date('2026-10-27')},
  {id:'BL02', total:300,  status:'Pending', date:date('2026-10-27')},
  {id:'BL03', total:900,  status:'Pending', date:date('2026-10-28')}] AS r
MERGE (b:Bill {id:r.id}) SET b += r;

// ---------------- relationships (the edge list of the PDF) ----------------
UNWIND [['PT01','A1001'], ['PT02','A1002'], ['PT03','A1003'], ['PT03','A1004']] AS e
MATCH (p:Patient {id:e[0]}), (a:Appointment {id:e[1]}) MERGE (p)-[:BOOKED]->(a);
UNWIND [['A1001','D1'], ['A1002','D3'], ['A1003','D2'], ['A1004','D1']] AS e
MATCH (a:Appointment {id:e[0]}), (d:Doctor {id:e[1]}) MERGE (a)-[:WITH]->(d);
UNWIND [['D1','Cardiology'], ['D2','Orthopedics'], ['D3','General Medicine']] AS e
MATCH (d:Doctor {id:e[0]}), (x:Department {name:e[1]}) MERGE (d)-[:WORKS_IN]->(x);
UNWIND [['A1001','RX01'], ['A1002','RX02'], ['A1004','RX03']] AS e
MATCH (a:Appointment {id:e[0]}), (r:Prescription {id:e[1]}) MERGE (a)-[:RESULTED_IN]->(r);
UNWIND [['RX01','Aspirin 75','1-0-0',30], ['RX01','Atorvastatin 10','0-0-1',30], ['RX02','Paracetamol 500','1-1-1',3],
        ['RX03','Aspirin 75','1-0-0',30], ['RX03','Metoprolol 25','1-0-1',30]] AS e
MATCH (r:Prescription {id:e[0]}), (m:Medicine {name:e[1]}) MERGE (r)-[c:CONTAINS]->(m) SET c.dose = e[2], c.days = e[3];     // dose and days are relationship properties
UNWIND [['PT01','BL01'], ['PT02','BL02'], ['PT03','BL03']] AS e
MATCH (p:Patient {id:e[0]}), (b:Bill {id:e[1]}) MERGE (p)-[:BILLED]->(b);
UNWIND [['BL01','A1001'], ['BL02','A1002'], ['BL03','A1004']] AS e
MATCH (b:Bill {id:e[0]}), (a:Appointment {id:e[1]}) MERGE (b)-[:FOR]->(a);

// check: 3 + 3 + 3 + 4 + 3 + 4 + 3 = 23 nodes, 4+4+3+3+5+3+3 = 25 relationships
MATCH (n) RETURN count(n) AS nodes;
MATCH ()-[r]->() RETURN count(r) AS relationships;
