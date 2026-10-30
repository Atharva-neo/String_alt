-- Experiment 1A - Library  |  Task 1 (ER diagram) and Task 2 (CREATE TABLE with constraints)
-- @DB library_1a
/* @ER
erDiagram
    MEMBER ||--o{ ISSUE : "borrows (1 : N)"
    BOOK   ||--o{ ISSUE : "is issued in (1 : N)"
    BOOK {
        varchar book_id PK
        varchar title
        varchar author
        decimal price "CHECK > 0"
        int copies
    }
    MEMBER {
        varchar member_id PK
        varchar name
        varchar dept
        varchar phone UK "UNIQUE"
    }
    ISSUE {
        int issue_id PK
        varchar book_id FK
        varchar member_id FK
        date issue_date
        date return_date "CHECK >= issue_date"
    }
*/

DROP DATABASE IF EXISTS library_1a;
CREATE DATABASE library_1a;
USE library_1a;

-- Book and Member are independent (parent) tables
CREATE TABLE Book (
    book_id VARCHAR(10)   NOT NULL,
    title   VARCHAR(60)   NOT NULL,
    author  VARCHAR(40)   NOT NULL,
    price   DECIMAL(8,2)  NOT NULL,
    copies  INT           NOT NULL DEFAULT 1,
    CONSTRAINT pk_book       PRIMARY KEY (book_id),
    CONSTRAINT chk_book_price CHECK (price > 0)
) ENGINE=InnoDB;

CREATE TABLE Member (
    member_id VARCHAR(10) NOT NULL,
    name      VARCHAR(50) NOT NULL,
    dept      VARCHAR(20),
    phone     VARCHAR(15) NOT NULL,
    CONSTRAINT pk_member PRIMARY KEY (member_id),
    CONSTRAINT uq_member_phone UNIQUE (phone)
) ENGINE=InnoDB;

-- Issue is the child (junction) table: one row per borrowing event
CREATE TABLE Issue (
    issue_id    INT         NOT NULL AUTO_INCREMENT,
    book_id     VARCHAR(10) NOT NULL,
    member_id   VARCHAR(10) NOT NULL,
    issue_date  DATE        NOT NULL,
    return_date DATE        NULL,
    CONSTRAINT pk_issue PRIMARY KEY (issue_id),
    CONSTRAINT fk_issue_book   FOREIGN KEY (book_id)   REFERENCES Book(book_id),
    CONSTRAINT fk_issue_member FOREIGN KEY (member_id) REFERENCES Member(member_id),
    CONSTRAINT chk_issue_dates CHECK (return_date >= issue_date)
) ENGINE=InnoDB;
