# Viva questions - 4D Ticket booking

**Q1. Why three triggers instead of one?** MySQL triggers are tied to one event and timing: BEFORE INSERT guard, AFTER INSERT reserve, AFTER UPDATE restore.

**Q2. Why is the overbooking check in a BEFORE trigger?** It must stop the row before it is stored; BEFORE can SIGNAL and abort the INSERT.

**Q3. What prevents two customers from booking the last seat at once?** The guard's SELECT is a plain (non-locking) read, so two transactions can both pass it. The AFTER INSERT trigger's UPDATE of Show_Seats then takes the row lock: the second transaction waits, and when it gets the lock `CHECK (available >= 0)` rejects the overselling UPDATE and the INSERT is undone. A cleaner design reads the row with `SELECT ... FOR UPDATE` first (Experiment 5B).

**Q4. What happens on `CALL book_ticket(1,'Zoya',9)`?** The guard raises 'Not enough seats available', the handler ROLLBACKs and RESIGNALs the error; nothing is stored.

**Q5. Show each ACID property from your outputs.** A: Task 5/10/11 leave no trace; C: invariant available + booked = capacity and CHECK/trigger rules; I: second connection sees no uncommitted bookings; D: committed data survives restart.

**Q6. What does the server do when a session dies in a transaction?** It rolls the transaction back (InnoDB undo log) and releases its locks - that is how Task 11 shows atomicity.

**Q7. Why must cancellation check `OLD.status <> 'Cancelled'`?** Otherwise cancelling twice would restore the seats twice and create phantom seats.

**Q8. What does SAVEPOINT give in Task 10?** The second booking is undone while the first remains, and the seat counter maintained by the trigger is rolled back with it.

**Q9. How is revenue computed?** `SUM(seats) x 200` over Booked rows only.

**Q10. Why is `show_report` a procedure with a cursor and not a plain SELECT?** To practise row-by-row processing; the same data is available with one GROUP BY query.

**Q11 (follow-up). Why does a failed trigger undo the whole INSERT?** The trigger runs inside the statement; an error aborts the statement atomically.

**Q12 (follow-up). Could `available` become inconsistent?** Only if someone updates Show_Seats directly; protect with privileges so applications use `book_ticket` only.
