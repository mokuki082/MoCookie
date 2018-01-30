CREATE SCHEMA IF NOT EXISTS Blockchain AUTHORIZATION moku;

CREATE TABLE User (
  pubk TEXT PRIMARY KEY
);

CREATE TABLE Transaction (
  id SERIAL PRIMARY KEY,
);

CREATE TABLE GiveCookieTransaction (
  transaction_id INT REFERENCES Transaction(id)
  sender_pubk TEXT NOT NULL,
  receiver_pubk TEXT NOT NULL,
  recent_hash TEXT NOT NULL,
  reason VARCHAR(100),
  signature TEXT NOT NULL,
  PRIMARY KEY(sender_pubk, time_stamp)
);

CREATE TABLE ReceiveCookieTransaction (
  transaction_id INT REFERENCES Transaction(id)
  receiver_pubk TEXT NOT NULL,
  sender_pubk TEXT NOT NULL,
  recent_hash TEXT NOT NULL,
  cookie_type VARCHAR(100),
  signature TEXT NOT NULL,
  PRIMARY KEY(receiver_pubk, time_stamp)
);

CREATE TABLE Block (
  curr_hash TEXT PRIMARY KEY,
  prev_hash TEXT REFERENCES Block(curr_hash) ON ,
  order SERIAL UNIQUE NOT NULL
);

CREATE TABLE IncludeTransaction (
  block TEXT REFERENCES Block(curr_hash),
  transaction_id INT REFERENCES Transaction(id) NOT NULL,
  PRIMARY KEY(block, transaction_id)
);

CREATE TABLE Pool (
  transaction_id INT PRIMARY KEY
);

CREATE TABLE Debt (
  sender_pubk TEXT,
  receiver_pubk TEXT,
  cookies_owed INT DEFAULT 0 NOT NULL,
  PRIMARY KEY(sender_pubk, receiver_pubk)
);
