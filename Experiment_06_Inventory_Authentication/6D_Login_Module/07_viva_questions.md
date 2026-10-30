# Viva questions - 6D Login module

**Q1. Why store a hash and not the password?** If the table leaks, passwords are not exposed. At login the typed password is hashed with the same function and the digests are compared.

**Q2. What does `SHA2(pwd, 256)` return?** A 64-character hexadecimal string (256 bits). That is why `password_hash` is `CHAR(64)`.

**Q3. Is plain SHA-256 enough for real systems?** No. It is fast and unsalted, so equal passwords give equal hashes and attackers can precompute tables. Use per-user salt plus a slow KDF (bcrypt/scrypt/Argon2) in the application (ADV 1).

**Q4. How does the lock work?** Each wrong password increments `failed_attempts`; at 3 `is_locked = 1`; later attempts, even with the right password, get the locked message and are logged as 'Locked'. A success resets the counter; `unlock_user` (admin) clears the lock.

**Q5. Why the same message for unknown user and wrong password?** To avoid user enumeration.

**Q6. Why is login a transaction with FOR UPDATE?** Two simultaneous wrong guesses must not both read counter 2; the row lock serialises them so the third guess really locks the account, and the counter update and log row commit together.

**Q7. What does `register` validate?** Username not empty, password length >= 8, valid role, username not existing; a UNIQUE index plus an EXIT HANDLER for 1062 protects against races.

**Q8. How are privileges separated?** Roles admin and clerk get EXECUTE on specific procedures; admin additionally reads non-secret columns; nobody can SELECT password_hash.

**Q9. Why does db_clerk's `SELECT * FROM App_User` fail while `SELECT user_id, username, role` works?** `*` includes columns without a SELECT privilege, so the statement is refused (ERROR 1142/1143); a column list restricted to the granted columns is allowed.

**Q10. Why can a clerk call login without any privilege on App_User?** Procedures run with the definer's privileges (SQL SECURITY DEFINER).

**Q11 (follow-up). How do you stop brute force by an attacker who tries many usernames?** Rate limit by IP/session in the application, add a delay or CAPTCHA, monitor `Login_Log` for many Failed rows (ADV 4).

**Q12 (follow-up). What is a pepper?** A secret value kept outside the database and mixed into the hash, so a stolen database alone is not enough to crack the passwords.
