CREATE OR REPLACE FUNCTION Blockchain.CreateTransaction(protocol VARCHAR(4))
  RETURNS INT AS
  $$
  BEGIN
  INSERT INTO Blockchain.Transaction(protocol) VALUES (protocol);
  -- Obtain transaction_id
  RETURN (SELECT id FROM Blockchain.Transaction
          ORDER BY id DESC LIMIT 1);
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

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
      tid := Blockchain.CreateTransaction('gct');
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
    tid := Blockchain.CreateTransaction('rct');
    -- Obtain block_id
    bid := (SELECT id FROM Blockchain.Block
            WHERE curr_hash = recent_hash);
    -- Convert unix time into timestamp format
    ttime := to_timestamp(transaction_time);
    -- Create GiveCookieTransaction
    INSERT INTO Blockchain.ReceiveCookieTransaction(
      id, invoker, transaction_time, sender, recent_block,
      num_cookies, cookie_type, signature
    ) VALUES (tid, invoker, ttime, sender, bid, num_cookies, cookie_type,
              signature);
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
    DECLARE
      tid INT;
      bid INT;
      ttime TIMESTAMP;
      ccct_id INT;
    BEGIN
      -- Create a generic transaction
      tid := Blockchain.CreateTransaction('cct');
      -- Obtain block_id
      bid := (SELECT id FROM Blockchain.Block
              WHERE curr_hash = recent_hash);
      -- Obtain ttime in timestamp format
      ttime := to_timestamp(transaction_time);
      -- Create CollapseChainTransaction
      INSERT INTO Blockchain.CombinedCollapseChainTransaction(
        id, invoker, transaction_time, recent_block, signature
      ) VALUES (tid, invoker, ttime, bid, signature);
      -- Check if CombinedCollapseChainTransaction exists
      ccct_id := (SELECT id
               FROM Blockchain.CombinedCollapseChainTransaction cct
               JOIN Pool p ON (cct.id = pool.transaction_id)
               WHERE cct.start_user = start_user AND
                     cct.mid_user = mid_user AND
                     cct.end_user = end_user AND
                     cct.num_cookies = num_cookies);
      IF (ccct_id IS NULL) THEN
        -- Create a new ccct
        ccct_id := Blockchain.CreateTransaction('ccct');
        INSERT INTO Blockchain.CombinedCollapseChainTransaction (
          id, start_user, mid_user, end_user, start_user_transaction,
          mid_user_transaction, end_user_transaction, num_cookies
        ) VALUES (ccct_id, start_user, mid_user, end_user, NULL, NULL,
          NULL, num_cookies);
        INSERT INTO Blockchain.Pool VALUES (ccct_id);
      END IF;
      -- Update ccct
      IF (invoker = start_user) THEN
        UPDATE Blockchain.CombinedCollapseChainTransaction ccct
        SET start_user_transaction = tid
        WHERE ccct.id = ccct_id;
      ELSEIF (invoker = mid_user) THEN
        UPDATE Blockchain.CombinedCollapseChainTransaction ccct
        SET mid_user_transaction = tid
        WHERE ccct.id = ccct_id;
      ELSE
        UPDATE Blockchain.CombinedCollapseChainTransaction ccct
        SET end_user_transaction = tid
        WHERE ccct.id = ccct_id;
      END IF;
      INSERT INTO Blockchain.Pool VALUES (tid);
    END
  $$ LANGUAGE plpgsql SECURITY DEFINER;


-- CREATE OR REPLACE FUNCTION Blockchain.AddPairCalcelTransaction(
--   invoker TEXT,
--   other TEXT,
--   transaction_time DOUBLE PRECISION,
--   recent_block INT,
--   signature TEXT
-- );
