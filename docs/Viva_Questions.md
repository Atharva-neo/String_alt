# Pooled viva question bank (concise answers) - each variation also has its own `07_viva_questions.md` / `viva_questions.md`

## Basics
1. **DBMS vs file system?** Central control, integrity, concurrency, recovery, security, query language, data independence.
2. **DDL, DML, DCL, TCL?** DDL CREATE/ALTER/DROP/TRUNCATE; DML INSERT/UPDATE/DELETE/SELECT; DCL GRANT/REVOKE; TCL COMMIT/ROLLBACK/SAVEPOINT.
3. **Keys?** Super, candidate, primary, alternate, foreign, composite, surrogate.
4. **Integrity constraints?** Entity (PK not null/unique), referential (FK), domain (CHECK/type/DEFAULT), UNIQUE, NOT NULL.
5. **ER cardinalities?** 1:1, 1:N, M:N (resolved by a junction table, which carries relationship attributes).
6. **DELETE vs TRUNCATE vs DROP?** Rows with WHERE & rollback / all rows, DDL, resets identity / table itself.
7. **WHERE vs HAVING? COUNT(*) vs COUNT(col)?** Row filter vs group filter; counts rows vs non-NULL values.
8. **INNER, LEFT, RIGHT, SELF join? NOT IN vs NOT EXISTS?** NOT IN fails with NULLs in the subquery.
9. **View: advantages, updatable?** Security/simplicity; simple one-table views; WITH CHECK OPTION.
10. **Index?** B-tree structure speeding lookups, costs writes/space; composite index follows the left-prefix rule.

## Normalization
11. **1NF/2NF/3NF/BCNF/4NF in one line each?** see `Normalization_Notes.md`. 12. **Lossless vs dependency preserving?** 13. **Why denormalise?** Read performance, reporting; accept redundancy knowingly.

## Transactions / concurrency / recovery
14. **ACID?** `ACID_Notes.md`. 15. **Isolation levels and anomalies?** `Concurrency_Notes.md`. 16. **Shared vs exclusive lock?** 17. **Deadlock: detection, prevention?** 18. **2PL, strict 2PL?** 19. **Conflict serializability test?** 20. **Write-ahead log, checkpoint, UNDO/REDO, immediate vs deferred update?**

## Programming
21. **Trigger vs procedure vs function?** 22. **BEFORE vs AFTER trigger?** BEFORE can modify NEW / reject; AFTER for audit. 23. **Cursor?** Row-by-row processing; prefer set-based SQL. 24. **SIGNAL/handlers?** 25. **SQL injection and prevention?** Parameterised queries, least privilege.

## Security
26. **Role-based access control?** Roles hold privileges, users hold roles. 27. **Column privileges, view-based security, DEFINER rights?** 28. **How are passwords stored?** Salted slow hash (bcrypt/Argon2); the lab uses SHA-256 to show the idea.

## MongoDB
29. **Document model vs relational?** Flexible schema, embedded arrays, joins by `$lookup`. 30. **Embed vs reference?** 31. **Aggregation pipeline stages?** 32. **Indexes: single, compound (ESR), text, multikey, unique; explain.** 33. **Validation with `$jsonSchema`.** 34. **Replica set, oplog, change streams.** 35. **CAP / BASE vs ACID?** MongoDB offers multi-document ACID transactions on replica sets since 4.0.

## ML / connectivity
36. **Why train/test split? What is overfitting?** 37. **TF-IDF, Naive Bayes, confusion matrix, R2.** 38. **Why encode categorical variables, scale numeric ones?** 39. **PyMongo vs mysql-connector differences (`%s`, commit).** 40. **REST status codes and idempotent verbs.**

## Neo4j
41. **Property graph?** Nodes, labelled relationships with direction and properties. 42. **When is a graph database better?** Multi-hop questions. 43. **MERGE vs CREATE?** MERGE is idempotent. 44. **Uniqueness constraint syntax?** `CREATE CONSTRAINT .. FOR (p:Patient) REQUIRE p.id IS UNIQUE`. 45. **shortestPath?** `shortestPath((a)-[*..n]-(b))`.

## Examiner follow-ups to expect
"Show the same result with a different query", "what happens if I run it twice?", "which index would help?", "what if the value is NULL?", "what if two users do this at once?", "what is the Oracle syntax?", "explain this output line".
