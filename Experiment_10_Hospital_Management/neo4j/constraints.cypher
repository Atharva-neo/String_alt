// Graph Task 2 - uniqueness constraints (Neo4j 5 syntax). Run in Neo4j Browser or:  cypher-shell -u neo4j -p <password> -f constraints.cypher
CREATE CONSTRAINT patient_id_unique     IF NOT EXISTS FOR (p:Patient)     REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT doctor_id_unique      IF NOT EXISTS FOR (d:Doctor)      REQUIRE d.id IS UNIQUE;
CREATE CONSTRAINT appointment_id_unique IF NOT EXISTS FOR (a:Appointment) REQUIRE a.id IS UNIQUE;
// bonus: the other labels that are looked up by key
CREATE CONSTRAINT department_name_unique IF NOT EXISTS FOR (d:Department)   REQUIRE d.name IS UNIQUE;
CREATE CONSTRAINT medicine_name_unique   IF NOT EXISTS FOR (m:Medicine)     REQUIRE m.name IS UNIQUE;
CREATE CONSTRAINT prescription_id_unique IF NOT EXISTS FOR (r:Prescription) REQUIRE r.id IS UNIQUE;
CREATE CONSTRAINT bill_id_unique         IF NOT EXISTS FOR (b:Bill)         REQUIRE b.id IS UNIQUE;
SHOW CONSTRAINTS;

// Negative test (after load_graph.cypher): creating a second Patient with an existing id fails with
//   Neo.ClientError.Schema.ConstraintValidationFailed: Node(...) already exists with label `Patient` and property `id` = 'PT01'
// CREATE (:Patient {id: 'PT01', name: 'Duplicate'});
