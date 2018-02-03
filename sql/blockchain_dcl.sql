CREATE OR REPLACE FUNCTION Blockchain.AddUser(pubk TEXT)
  RETURNS VOID AS
  $$
  BEGIN
    INSERT INTO Blockchain.ValidUser(pubk) VALUES (pubk);
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.RemoveUser(pubk TEXT)
  RETURNS VOID AS
  $$
  BEGIN
    DELETE FROM Blockchain.ValidUser vu WHERE vu.pubk = pubk;
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.AddGiveCookieTransaction(
      invoker TEXT,
      transaction_time DOUBLE PRECISION, -- unix time
      receiver TEXT,
      recent_hash TEXT,
      num_cookies INT,
      reason VARCHAR(100),
      signature TEXT)
  RETURNS VOID AS
  $$
    DECLARE
      tid INT;
      bid INT;
      ttime TIMESTAMP;
    BEGIN
      -- Create a generic transaction
      INSERT INTO Blockchain.Transaction(protocol) VALUES ('gct');
      -- Obtain transaction_id
      tid := (SELECT id FROM Blockchain.Transaction
              ORDER BY id LIMIT 1);
      -- Obtain block_id
      bid := (SELECT id FROM Blockchain.Block
              WHERE curr_hash = recent_hash);
      -- Convert unix time into timestamp format
      ttime := to_timestamp(transaction_time);
      -- Create GiveCookieTransaction
      INSERT INTO Blockchain.GiveCookieTransaction(
        id, invoker, transaction_time, receiver, recent_block,
        num_cookies, reason, signature
      ) VALUES (tid, invoker, ttime, receiver, bid, num_cookies, reason,
                signature);
      -- Add transaction into pool
      INSERT INTO Blockchain.Pool VALUES (tid);
    END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.AddReceiveCookieTransaction(
      invoker TEXT,
      transaction_time DOUBLE PRECISION,
      sender TEXT,
      recent_hash TEXT,
      num_cookies INT,
      cookie_type VARCHAR(100),
      signature TEXT)
  RETURNS VOID AS
  $$
  DECLARE
    tid INT;
    bid INT;
    ttime TIMESTAMP;
  BEGIN
    -- Create a generic transaction
    INSERT INTO Blockchain.Transaction(protocol) VALUES ('rct');
    -- Obtain transaction_id
    tid := (SELECT id FROM Blockchain.Transaction
            ORDER BY id LIMIT 1);
    -- Obtain block_id
    bid := (SELECT id FROM Blockchain.Block
            WHERE curr_hash = recent_hash);
    -- Convert unix time into timestamp format
    ttime := to_timestamp(transaction_time);
    -- Create GiveCookieTransaction
    INSERT INTO Blockchain.ReceiveCookieTransaction(
      id, invoker, transaction_time, sender, recent_block,
      num_cookies, cookie_type, signature
    ) VALUES (tid, ttime, sender, bid, num_cookies, cookie_type, signaure);
    -- Add transaction to Pool
    INSERT INTO Blockchain.Pool VALUES (tid);
  END
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.AddCollapseChainTransaction(
      invoker TEXT,
      transaction_time DOUBLE PRECISION,
      recent_hash TEXT,
      start_user TEXT,
      mid_user TEXT,
      end_user TEXT,
      num_cookies INT,
      signature TEXT)
  RETURNS VOID AS
  $$
    BEGIN
      -- Create a generic transaction
      -- Obtain transaction_id
      -- Obtain block_id
      -- Create GiveCookieTransaction
      -- Create CollapseChainTransaction
      -- Check if CombinedCollapseChainTransaction exists
      -- If yes, update the combined transaction
      -- Otherwise create a combined transaction
    END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

--
-- CREATE OR REPLACE FUNCTION Blockchain.AddPairCalcelTransaction(
--   invoker TEXT,
--   other TEXT,
--   transaction_time DOUBLE PRECISION,
--   recent_block INT,
--   signature TEXT
-- );
