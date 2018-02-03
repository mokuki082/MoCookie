DROP SCHEMA Blockchain CASCADE;
CREATE SCHEMA IF NOT EXISTS Blockchain;

CREATE TABLE IF NOT EXISTS Blockchain.ValidUser (
  /* Represents a user in the system.*/
  pubk TEXT PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS Blockchain.InvalidUser(
  pubk TEXT PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS Blockchain.Transaction (
  /* Generic transaction class.

  Constraints:
    transaction_protocol_check -- Check that protocol is recognized
  */
  id SERIAL PRIMARY KEY,
  protocol VARCHAR(5) NOT NULL,
  CONSTRAINT transaction_protocol_check CHECK (protocol IN
    ('gct', 'rct', 'cct', 'ccct', 'pct', 'cpct', 'aut', 'rut'))
);

CREATE TABLE IF NOT EXISTS Blockchain.Block (
  /* Represents a block in the blockchain.

  Triggers:
    block_prev_hash_fkey -- Check that prev_hash is either all 0s or references
      the previous curr_hash.
  */
  id SERIAL PRIMARY KEY,
  curr_hash TEXT UNIQUE,
  prev_hash TEXT
);

CREATE TABLE IF NOT EXISTS Blockchain.GiveCookieTransaction (
  /* Represents a gc transaction

  Constraints:
    gct_invoker_ttime_key: Ensure no duplicated transaction.
    gct_num_cookies_check: Number of cookies cannot be 0 or negative.
  Trigger:
    gct_protocol_check: Ensure all transactions are mutually exclusive.
  */
  id INT PRIMARY KEY REFERENCES Blockchain.Transaction(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  invoker TEXT REFERENCES Blockchain.ValidUser(pubk) NOT NULL,
  transaction_time TIMESTAMP NOT NULL,
  receiver TEXT REFERENCES Blockchain.ValidUser(pubk) NOT NULL,
  recent_block INT REFERENCES Blockchain.Block(id)
    ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
  num_cookies INT NOT NULL,
  reason VARCHAR(100),
  signature TEXT NOT NULL,
  -- Key constraint
  CONSTRAINT gct_invoker_ttime_key UNIQUE(invoker, transaction_time),
  -- Check constraint
  CONSTRAINT gct_num_cookies_check CHECK (num_cookies > 0)
);

CREATE TABLE IF NOT EXISTS Blockchain.ReceiveCookieTransaction (
  /* Represents a rc transaction

  Constraints:
    rct_invoker_ttime_key: Ensure no duplicated transaction.
    rct_num_cookies_check: Number of cookies cannot be 0 or negative.
  Trigger:
    rct_protocol_check: Ensure all transactions are mutually exclusive.
  */
  id INT PRIMARY KEY REFERENCES Blockchain.Transaction(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  invoker TEXT REFERENCES Blockchain.ValidUser(pubk) NOT NULL,
  transaction_time TIMESTAMP NOT NULL,
  sender TEXT REFERENCES Blockchain.ValidUser(pubk) NOT NULL,
  recent_block INT REFERENCES Blockchain.Block(id)
    ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
  num_cookies INT NOT NULL,
  cookie_type VARCHAR(100),
  signature TEXT NOT NULL,
  -- Key constraint
  CONSTRAINT rct_invoker_ttime_key UNIQUE(invoker, transaction_time),
  -- Constraints
  CONSTRAINT rct_num_cookies_check CHECK (num_cookies > 0)
);

CREATE TABLE IF NOT EXISTS Blockchain.ChainCollapseTransaction (
  /* Represents a cc transaction

  Constraints:
    cct_invoker_ttime_key: Ensure no duplicated transaction.
  Trigger:
    cct_protocol_check: Ensure all transactions are mutually exclusive.
  */
  id INT PRIMARY KEY REFERENCES Blockchain.Transaction(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  invoker TEXT REFERENCES Blockchain.ValidUser(pubk) NOT NULL,
  transaction_time TIMESTAMP NOT NULL,
  recent_block INT REFERENCES Blockchain.Block(id)
    ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
  signature TEXT NOT NULL,
  -- Primary key
  CONSTRAINT cct_invoker_ttime_key UNIQUE(invoker, transaction_time)
);

CREATE TABLE IF NOT EXISTS Blockchain.CombinedChainCollapseTransaction (
  /* Represents a ccc transaction

  Constraints:
    ccct_num_cookies_check: Number of cookies cannot be 0 or negative.
    ccct_user_check: All three users are different.
  Trigger:
    ccct_protocol_check: Ensure all transactions are mutually exclusive.
  */
  id INT PRIMARY KEY REFERENCES Blockchain.Transaction(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  start_user TEXT REFERENCES Blockchain.ValidUser(pubk) NOT NULL,
  mid_user TEXT REFERENCES Blockchain.ValidUser(pubk) NOT NULL,
  end_user TEXT REFERENCES Blockchain.ValidUser(pubk) NOT NULL,
  start_user_transaction INT REFERENCES Blockchain.ChainCollapseTransaction(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  mid_user_transaction INT REFERENCES Blockchain.ChainCollapseTransaction(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  end_user_transaction INT REFERENCES Blockchain.ChainCollapseTransaction(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  num_cookies INT NOT NULL,
  -- Constraints
  CONSTRAINT ccct_num_cookies_check CHECK (num_cookies > 0),
  CONSTRAINT ccct_user_check CHECK (start_user != mid_user AND
                                    mid_user != end_user AND
                                    start_user != end_user)
);

CREATE TABLE IF NOT EXISTS Blockchain.PairCancelTransaction (
  /* Represents a pc transaction

  Constraints:
    pct_invoker_ttime_key: Ensure no duplicated transaction.
  Trigger:
    pct_protocol_check: Ensure all transactions are mutually exclusive.
  */
  id INT PRIMARY KEY REFERENCES Blockchain.Transaction(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  invoker TEXT REFERENCES Blockchain.ValidUser(pubk) NOT NULL,
  transaction_time TIMESTAMP NOT NULL,
  recent_block INT REFERENCES Blockchain.Block(id)
    ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
  signature TEXT NOT NULL,
  -- Constraints
  CONSTRAINT pct_invoker_ttime_key UNIQUE(invoker, transaction_time)
);

CREATE TABLE IF NOT EXISTS Blockchain.CombinedPairCancelTransaction (
  /* Represents a cpc transaction

  Constraints:
    cpct_num_cookies_check: Number of cookies cannot be 0 or negative.
    cpct_user_check: User a and b are different
  Trigger:
    cpct_protocol_check: Ensure all transactions are mutually exclusive.
  */
  id INT PRIMARY KEY REFERENCES Blockchain.Transaction(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  user_a_id INT REFERENCES Blockchain.PairCancelTransaction(id),
  user_b_id INT REFERENCES Blockchain.PairCancelTransaction(id),
  user_a TEXT REFERENCES Blockchain.ValidUser(pubk)
    ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
  user_b TEXT REFERENCES Blockchain.ValidUser(pubk)
    ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
  num_cookies INT NOT NULL,
  -- Constraints
  CONSTRAINT cpct_num_cookies_check CHECK (num_cookies > 0),
  CONSTRAINT cpct_user_check CHECK (user_a != user_b)
);

CREATE TABLE IF NOT EXISTS Blockchain.AddUserTransaction (
  /* Represents a au transaction.

  Trigger:
    aut_protocol_check: Ensure all transactions are mutually exclusive.
  */
  id INT PRIMARY KEY REFERENCES Blockchain.Transaction(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  join_time TIMESTAMP NOT NULL,
  user_pubk TEXT REFERENCES Blockchain.ValidUser(pubk) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS Blockchain.RemoveUserTransaction (
  /* Represents a ru transaction.

  Trigger:
    rut_protocol_check: Ensure all transactions are mutually exclusive.
  */
  id INT PRIMARY KEY REFERENCES Blockchain.Transaction(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  remove_time TIMESTAMP NOT NULL,
  user_pubk TEXT REFERENCES Blockchain.ValidUser(pubk) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS Blockchain.IncludeTransaction (
  /* Shows the transactions in a block. */
  block TEXT REFERENCES Blockchain.Block(curr_hash),
  transaction_id INT REFERENCES Blockchain.Transaction(id),
  PRIMARY KEY(block, transaction_id)
);

CREATE TABLE IF NOT EXISTS Blockchain.Pool (
  /* Shows the transactions that are currently in the pool. */
  transaction_id INT PRIMARY KEY REFERENCES Blockchain.Transaction(id)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Blockchain.Debt (
  /* Shows the debt between two users

  Constraint:
    debt_cookies_owed_check -- cookies_owed cannot be negative.
  */
  sender_pubk TEXT REFERENCES Blockchain.ValidUser(pubk),
  receiver_pubk TEXT REFERENCES Blockchain.ValidUser(pubk),
  cookies_owed INT DEFAULT 0 NOT NULL,
  PRIMARY KEY(sender_pubk, receiver_pubk),
  -- Constraints:
  CONSTRAINT debt_cookies_owed_check CHECK (cookies_owed >= 0)
);
