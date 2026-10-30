# Viva questions - Experiment 10 Hospital management

**Q1. Which data did you embed and which did you reference? Why?** Embedded: medicines (in prescriptions), bill items, doctor schedule, patient contact - small, owned, read together. Referenced: patient/doctor/appointment ids - shared entities with their own lifecycle.

**Q2. How is data validated?** `$jsonSchema` validators per collection (required fields, 10-digit phone, `total > 0`, status enum). Invalid inserts fail with error 121.

**Q3. What is a change stream? What does it need?** A real-time feed of data changes of a collection/database/deployment built on the oplog; needs a replica set (a single-node replica set is enough) or Atlas; resumable with a resume token.

**Q4. Why can't you use `watch()` on a standalone mongod?** Standalone servers have no oplog; the server rejects the command (the code checks `hello.setName`).

**Q5. How does the dashboard update without a page reload?** A Streamlit fragment re-runs every 2 s; a background change-stream thread bumps a version counter; the fragment re-queries and redraws the Plotly figures when the version changed.

**Q6. How do you get a patient's full history in one query?** Start from `patients`, `$lookup` appointments, prescriptions and billing by `patient_id`, then shape with `$map`/`$reduce` (or `$unwind`).

**Q7. How is "appointments per hour" computed?** `$group` by `{$hour: "$date"}` after a `$match` on today's range; hours without data are filled with 0 in Python.

**Q8. Which indexes did you create and why?** `{doctor_id, date}` (agenda: equality + range), `{status}` (unpaid report), `patient_id` on appointments/billing/prescriptions, multikey `medicines.name`.

**Q9. What is a multikey index?** An index on an array field: one index entry per array element.

**Q10. Graph model vs documents - when is the graph better?** Multi-hop relationship questions (patient -> appointment -> doctor -> department, shared medicines, shortest path) are single path patterns in Cypher but several `$lookup`s in MongoDB.

**Q11 (follow-up). How do you keep MongoDB and Neo4j in sync?** Consume the change stream and `MERGE` nodes/relationships (idempotent) - `neo4j/live_loader.py`.

**Q12 (follow-up). What happens if the watcher crashes?** Store the resume token and restart with `resume_after`, otherwise events in the gap are missed.

**Q13 (follow-up). Why a generator thread/process separate from the dashboard?** It simulates other applications writing to the database; the dashboard only reads.
