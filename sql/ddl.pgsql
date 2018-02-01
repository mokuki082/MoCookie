DROP SCHEMA Blockchain CASCADE;
CREATE SCHEMA IF NOT EXISTS Blockchain;

CREATE TABLE IF NOT EXISTS Blockchain.CookieUser (
  pubk TEXT PRIMARY KEY,
  valid BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS Blockchain.Transaction (
  id SERIAL PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS Blockchain.Block (
  curr_hash TEXT PRIMARY KEY,
  prev_hash TEXT NOT NULL, -- TODO: Use trigger to make sure it's either genesis or references previous blocks
  ordering SERIAL UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS Blockchain.GiveCookieTransaction (
  id INT REFERENCES Blockchain.Transaction(id) PRIMARY KEY,
  invoker TEXT REFERENCES Blockchain.CookieUser(pubk) NOT NULL,
  transaction_time TIMESTAMP NOT NULL,
  receiver TEXT REFERENCES Blockchain.CookieUser(pubk) NOT NULL,
  recent_hash TEXT REFERENCES Blockchain.Block(curr_hash) NOT NULL,
  num_cookies INT NOT NULL,
  reason VARCHAR(100),
  signature TEXT NOT NULL,
  -- Key constraint
  CONSTRAINT gct_invoker_ttime_key UNIQUE(invoker, transaction_time),
  -- Check constraint
  CONSTRAINT gct_num_cookies_check CHECK (num_cookies > 0)
);

CREATE TABLE IF NOT EXISTS Blockchain.ReceiveCookieTransaction (
  id INT REFERENCES Blockchain.Transaction(id) PRIMARY KEY,
  invoker TEXT REFERENCES Blockchain.CookieUser(pubk) NOT NULL,
  transaction_time TIMESTAMP NOT NULL,
  sender_pubk TEXT REFERENCES Blockchain.CookieUser(pubk) NOT NULL,
  recent_hash TEXT REFERENCES Blockchain.Block(curr_hash) NOT NULL,
  num_cookies INT NOT NULL,
  cookie_type VARCHAR(100),
  signature TEXT NOT NULL,
  -- Key constraint
  CONSTRAINT rct_invoker_ttime_key UNIQUE(invoker, transaction_time),
  -- Constraints
  CONSTRAINT rct_num_cookies_check CHECK (num_cookies > 0)
);

CREATE TABLE IF NOT EXISTS Blockchain.ChainCollapseTransaction (
  id INT REFERENCES Blockchain.Transaction(id) PRIMARY KEY,
  invoker TEXT REFERENCES Blockchain.CookieUser(pubk) NOT NULL,
  transaction_time TIMESTAMP NOT NULL,
  recent_hash TEXT REFERENCES Blockchain.Block(curr_hash) NOT NULL,
  signature TEXT NOT NULL,
  -- Primary key
  CONSTRAINT cct_invoker_ttime_key UNIQUE(invoker, transaction_time)
);

CREATE TABLE IF NOT EXISTS Blockchain.CombinedChainCollapseTransaction (
  id INT REFERENCES Blockchain.Transaction(id) PRIMARY KEY,
  start_user TEXT REFERENCES Blockchain.CookieUser(pubk) NOT NULL,
  mid_user TEXT REFERENCES Blockchain.CookieUser(pubk) NOT NULL,
  end_user TEXT REFERENCES Blockchain.CookieUser(pubk) NOT NULL,
  start_user_transaction INT REFERENCES Blockchain.ChainCollapseTransaction(id),
  mid_user_transaction INT REFERENCES Blockchain.ChainCollapseTransaction(id),
  end_user_transaction INT REFERENCES Blockchain.ChainCollapseTransaction(id),
  num_cookies INT NOT NULL,
  -- Constraints
  CONSTRAINT ccct_num_cookies_check CHECK (num_cookies > 0)
);

CREATE TABLE IF NOT EXISTS Blockchain.PairCancelTransaction (
  id INT REFERENCES Blockchain.Transaction(id) PRIMARY KEY,
  recent_hash TEXT REFERENCES Blockchain.Block(curr_hash) NOT NULL,
  signature TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS Blockchain.CombinedPairCancelTransaction (
  id INT REFERENCES Blockchain.Transaction(id) PRIMARY KEY,
  user_a_id INT REFERENCES Blockchain.PairCancelTransaction(id),
  user_b_id INT REFERENCES Blockchain.PairCancelTransaction(id),
  user_a TEXT REFERENCES Blockchain.CookieUser(pubk) NOT NULL,
  user_b TEXT REFERENCES Blockchain.CookieUser(pubk) NOT NULL,
  num_cookies INT NOT NULL,
  -- Constraints
  CONSTRAINT ccct_num_cookies_check CHECK (num_cookies > 0)
);

CREATE TABLE IF NOT EXISTS Blockchain.AddUserTransaction (
  id INT REFERENCES Blockchain.Transaction(id) PRIMARY KEY,
  join_time TIMESTAMP NOT NULL,
  user_pubk TEXT REFERENCES Blockchain.CookieUser(pubk) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS Blockchain.RemoveUserTransaction (
  id INT REFERENCES Blockchain.Transaction(id) PRIMARY KEY,
  remove_time TIMESTAMP NOT NULL,
  user_pubk TEXT REFERENCES Blockchain.CookieUser(pubk) UNIQUE NOT NULL
);


CREATE TABLE IF NOT EXISTS Blockchain.IncludeTransaction (
  block TEXT REFERENCES Blockchain.Block(curr_hash),
  transaction_id INT REFERENCES Blockchain.Transaction(id),
  PRIMARY KEY(block, transaction_id)
);

CREATE TABLE IF NOT EXISTS Blockchain.Pool (
  transaction_id INT PRIMARY KEY REFERENCES Blockchain.Transaction(id)
);

CREATE TABLE IF NOT EXISTS Blockchain.Debt (
  sender_pubk TEXT,
  receiver_pubk TEXT,
  cookies_owed INT DEFAULT 0 NOT NULL,
  PRIMARY KEY(sender_pubk, receiver_pubk)
);
