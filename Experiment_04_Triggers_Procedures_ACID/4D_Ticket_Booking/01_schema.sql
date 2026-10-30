-- Experiment 4D - Ticket booking : Task 1 (tables)
-- @DB ticket_4d
/* @ER
erDiagram
    SHOW_SEATS ||--o{ BOOKING : "is booked by"
    SHOW_SEATS {
        int show_id PK
        varchar movie
        time show_time
        int available "CHECK >= 0, maintained by triggers"
    }
    BOOKING {
        int booking_id PK
        int show_id FK
        varchar customer
        int seats "CHECK > 0"
        varchar status "Booked / Cancelled"
    }
*/
DROP DATABASE IF EXISTS ticket_4d;
CREATE DATABASE ticket_4d;
USE ticket_4d;

CREATE TABLE Show_Seats (
    show_id   INT         NOT NULL PRIMARY KEY,
    movie     VARCHAR(30) NOT NULL,
    show_time TIME        NOT NULL,
    available INT         NOT NULL,
    CONSTRAINT chk_show_available CHECK (available >= 0)
) ENGINE=InnoDB;

CREATE TABLE Booking (
    booking_id INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    show_id    INT         NOT NULL,
    customer   VARCHAR(30) NOT NULL,
    seats      INT         NOT NULL,
    status     VARCHAR(10) NOT NULL DEFAULT 'Booked',
    CONSTRAINT fk_booking_show FOREIGN KEY (show_id) REFERENCES Show_Seats(show_id),
    CONSTRAINT chk_booking_seats  CHECK (seats > 0),
    CONSTRAINT chk_booking_status CHECK (status IN ('Booked', 'Cancelled'))
) ENGINE=InnoDB;
