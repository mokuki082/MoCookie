CREATE TABLE IF NOT EXISTS CookieUser (
  pubk TEXT PRIMARY KEY,
  valid BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS Transaction (
  id SERIAL PRIMARY KEY,
  invoker TEXT NOT NULL REFERENCES CookieUser(pubk),
  transaction_time TIMESTAMP,
  PRIMARY KEY (invoker, transaction_time)
);

CREATE TABLE IF NOT EXISTS GiveCookieTransaction (
  transaction_id INT REFERENCES Transaction(id) PRIMARY KEY,
  receiver_pubk TEXT REFERENCES CookieUser(pubk) NOT NULL,
  recent_hash TEXT REFERENCES Block(curr_hash) NOT NULL,
  num_cookies INT NOT NULL,
  reason VARCHAR(100),
  signature TEXT NOT NULL,
  -- Constraints
  CONSTRAINT gct_num_cookies_check CHECK (num_cookies > 0)
);

CREATE TABLE IF NOT EXISTS ReceiveCookieTransaction (
  transaction_id INT REFERENCES Transaction(id) PRIMARY KEY,
  sender_pubk TEXT REFERENCES CookieUser(pubk) NOT NULL,
  recent_hash TEXT REFERENCES Block(curr_hash) NOT NULL,
  num_cookies INT NOT NULL,
  cookie_type VARCHAR(100),
  signature TEXT NOT NULL,
  -- Constraints
  CONSTRAINT rct_num_cookies_check CHECK (num_cookies > 0)
);

CREATE TABLE IF NOT EXISTS ChainCollapseTransaction (
  transaction_id INT REFERENCES Transaction(id) PRIMARY KEY,
  recent_hash TEXT REFERENCES Block(curr_hash) NOT NULL,
  signature TEXT NOT NULL,
);

CREATE TABLE IF NOT EXISTS CombinedChainCollapseTransaction (
  transaction_id INT REFERENCES Transaction(id) PRIMARY KEY,
  start_user TEXT REFERENCES CookieUser(pubk) NOT NULL,
  mid_user TEXT REFERENCES CookieUser(pubk) NOT NULL,
  end_user TEXT REFERENCES CookieUser(pubk) NOT NULL,
  start_user_transaction INT REFERENCES ChainCollapseTransaction(id),
  mid_user_transaction INT REFERENCES ChainCollapseTransaction(id),
  end_user_transaction INT REFERENCES ChainCollapseTransaction(id),
  num_cookies INT NOT NULL,
  -- Constraints
  CONSTRAINT ccct_num_cookies_check CHECK (num_cookies > 0)
);

CREATE TABLE IF NOT EXISTS PairCancelTransaction (
  transaction_id INT REFERENCES Transaction(id) PRIMARY KEY,
  recent_hash TEXT REFERENCES Block(curr_hash) NOT NULL,
  signature TEXT NOT NULL,
);

CREATE TABLE IF NOT EXISTS CombinedPairCancelTransaction (
  transaction_id INT REFERENCES Transaction(id) PRIMARY KEY,
  user_a_transaction_id REFERENCES PairCancelTransaction(id),
  user_b_transaction_id REFERENCES PairCancelTransaction(id),
  user_a TEXT REFERENCES CookieUser(pubk) NOT NULL,
  user_b TEXT REFERENCES CookieUser(pubk) NOT NULL,
  num_cookies INT NOT NULL,
  -- Constraints
  CONSTRAINT ccct_num_cookies_check CHECK (num_cookies > 0),
);


CREATE TABLE IF NOT EXISTS Block (
  curr_hash TEXT PRIMARY KEY,
  prev_hash TEXT REFERENCES Block(curr_hash),
  order SERIAL UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS IncludeTransaction (
  block TEXT REFERENCES Block(curr_hash),
  transaction_id INT REFERENCES Transaction(id) NOT NULL,
  PRIMARY KEY(block, transaction_id)
);

CREATE TABLE IF NOT EXISTS Pool (
  transaction_id INT PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS Debt (
  sender_pubk TEXT,
  receiver_pubk TEXT,
  cookies_owed INT DEFAULT 0 NOT NULL,
  PRIMARY KEY(sender_pubk, receiver_pubk)
);
