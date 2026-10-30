-- Experiment 4C - Library fines : Task 1 (tables)
-- @DB library_4c
/* @ER
erDiagram
    BOOK ||--o{ ISSUE : "is issued in"
    BOOK {
        varchar book_id PK
        varchar title
        int available "CHECK >= 0, maintained by triggers/procedure"
    }
    ISSUE {
        int issue_id PK
        varchar book_id FK
        varchar member
        date issue_date
        date due_date
        date return_date
        int fine "5 x days late, set by trigger"
    }
*/
DROP DATABASE IF EXISTS library_4c;
CREATE DATABASE library_4c;
USE library_4c;

CREATE TABLE Book (
    book_id   VARCHAR(5)  NOT NULL PRIMARY KEY,
    title     VARCHAR(40) NOT NULL,
    available INT         NOT NULL,
    CONSTRAINT chk_book_available CHECK (available >= 0)
) ENGINE=InnoDB;

CREATE TABLE Issue (
    issue_id    INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    book_id     VARCHAR(5)  NOT NULL,
    member      VARCHAR(30) NOT NULL,
    issue_date  DATE        NOT NULL,
    due_date    DATE        NOT NULL,
    return_date DATE        NULL,
    fine        INT         NOT NULL DEFAULT 0,
    CONSTRAINT fk_issue_book FOREIGN KEY (book_id) REFERENCES Book(book_id)
) ENGINE=InnoDB;
