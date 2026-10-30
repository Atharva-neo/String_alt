-- Experiment 2D - Flight booking : schema
-- @DB flight_2d
/* @ER
erDiagram
    PASSENGER ||--o{ BOOKING : makes
    FLIGHT    ||--o{ BOOKING : "is booked in"
    FLIGHT {
        varchar flight_no PK
        varchar airline
        varchar source
        varchar destination
        int seats
    }
    PASSENGER {
        int pid PK
        varchar pname
        int age
    }
    BOOKING {
        int booking_id PK
        int pid FK
        varchar flight_no FK
        date travel_date
        int fare
    }
*/
DROP DATABASE IF EXISTS flight_2d;
CREATE DATABASE flight_2d;
USE flight_2d;

CREATE TABLE Flight (
    flight_no   VARCHAR(8) NOT NULL PRIMARY KEY,
    airline     VARCHAR(20) NOT NULL,
    source      VARCHAR(20) NOT NULL,
    destination VARCHAR(20) NOT NULL,
    seats       INT NOT NULL,
    CONSTRAINT chk_f_seats CHECK (seats > 0)
) ENGINE=InnoDB;
CREATE TABLE Passenger (
    pid   INT NOT NULL PRIMARY KEY,
    pname VARCHAR(40) NOT NULL,
    age   INT NOT NULL
) ENGINE=InnoDB;
CREATE TABLE Booking (
    booking_id  INT NOT NULL PRIMARY KEY,
    pid         INT NOT NULL,
    flight_no   VARCHAR(8) NOT NULL,
    travel_date DATE NOT NULL,
    fare        INT NOT NULL,
    CONSTRAINT fk_b_pass   FOREIGN KEY (pid)       REFERENCES Passenger(pid),
    CONSTRAINT fk_b_flight FOREIGN KEY (flight_no) REFERENCES Flight(flight_no),
    CONSTRAINT chk_b_fare CHECK (fare > 0)
) ENGINE=InnoDB;
