# Explanation - 7D Employee directory (MongoDB)

```mermaid
classDiagram
    class employees { emp_id : Int
      name : String
      dept : IT/HR/Sales
      salary : Int
      skills : String[]
      address : address }
    class address { city : String
      pin : String }
    employees *-- address : embedded (1:1)
```

`address` is an embedded sub-document (1:1, always read with the employee); `skills` is an array of strings.

| Task | Technique | Result |
|---|---|---|
| 2 | `"address.city": "Pune"` + `skills: "SQL"` | Anil |
| 3 | `$all` | Anil (Python and SQL) |
| 4 | `$not` + range / `$nin` | inclusive range: nobody (all salaries are inside [40000,60000]); exclusive: Anil (60000), Chirag (40000) |
| 5 | projection `{name:1,"address.city":1,_id:0}` + sort | 4 rows |
| 6 | `$group` avg/max by dept | IT 57500/60000, Sales 45000, HR 40000 |
| 7 | `$group` by `address.city` | Pune 2, Sangli 1, Kolhapur 1 |
| 8 | `$push` | Anil, Bharti get MongoDB (a second run would add it again - use `$addToSet` to avoid) |
| 9 | `$set` with dot notation | Chirag -> Satara (only `city` changes, `pin` stays) |
| 10 | `$rename` | `salary` -> `monthly_salary` everywhere |
| 11 | index on `address.city` | COLLSCAN -> IXSCAN |
| 12 | `deleteMany({dept:"Sales"})` | Deepa deleted, 3 remain |

`$in`/`$nin` test a list of discrete values, `$not` negates an operator expression (works with ranges). Order used: aggregation before `crud.js`, because Task 10 renames the `salary` field that Task 6 aggregates.
