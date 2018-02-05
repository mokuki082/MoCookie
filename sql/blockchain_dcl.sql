CREATE OR REPLACE FUNCTION Blockchain.createTransaction(protocol VARCHAR(4))
  RETURNS INT AS
  $$
  BEGIN
  INSERT INTO Blockchain.Transaction(protocol) VALUES (protocol);
  -- Obtain transaction_id
  RETURN (SELECT id FROM Blockchain.Transaction
          ORDER BY id DESC LIMIT 1);
  END
  $$ LANGUAGE plpgsql SECURITY INVOKER;

CREATE OR REPLACE FUNCTION Blockchain.addUser(pubk TEXT)
  RETURNS VOID AS
  $$
  BEGIN
    INSERT INTO Blockchain.ValidUser(pubk) VALUES (pubk);
  END
  $$ LANGUAGE plpgsql SECURITY INVOKER;

CREATE OR REPLACE FUNCTION Blockchain.removeUser(pubk TEXT)
  RETURNS VOID AS
  $$
  BEGIN
    DELETE FROM Blockchain.ValidUser vu WHERE vu.pubk = pubk;
  END
  $$ LANGUAGE plpgsql SECURITY INVOKER;

CREATE OR REPLACE FUNCTION Blockchain.addGiveCookieTransaction(
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
  $$ LANGUAGE plpgsql SECURITY INVOKER;

CREATE OR REPLACE FUNCTION Blockchain.addReceiveCookieTransaction(
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
$$ LANGUAGE plpgsql SECURITY INVOKER;

CREATE OR REPLACE FUNCTION Blockchain.addCollapseChainTransaction(
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
               FROM Blockchain.CombinedCollapseChainTransaction ccct
               JOIN Pool p ON (ccct.id = pool.transaction_id)
               WHERE ccct.start_user = start_user AND
                     ccct.mid_user = mid_user AND
                     ccct.end_user = end_user AND
                     ccct.num_cookies = num_cookies);
      IF (ccct_id IS NULL) THEN
        -- Create a new ccct
        ccct_id := Blockchain.CreateTransaction('ccct');
        INSERT INTO Blockchain.CombinedCollapseChainTransaction (
          id, start_user, mid_user, end_user, start_user_transaction,
          mid_user_transaction, end_user_transaction, num_cookies
        ) VALUES (ccct_id, start_user, mid_user, end_user, NULL, NULL,
          NULL, num_cookies);
        -- Insert ccct into pool
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
    END
  $$ LANGUAGE plpgsql SECURITY INVOKER;


CREATE OR REPLACE FUNCTION Blockchain.addPairCancelTransaction(
  invoker TEXT,
  other TEXT,
  transaction_time DOUBLE PRECISION,
  recent_block INT,
  num_cookies INT,
  signature TEXT)
  RETURNS VOID AS
  $$
  DECLARE
    tid INT;
    bid INT;
    ttime TIMESTAMP;
    cpct_id INT;
  BEGIN
    -- Create a generic transaction
    tid := Blockchain.createTransaction('pct');
    -- Obtain block_id
    bid := (SELECT id FROM Blockchain.Block
            WHERE curr_hash = recent_hash);
    -- Obtain ttime in timestamp format
    ttime := to_timestamp(transaction_time);
    cpct_id := (SELECT id
             FROM Blockchain.CombinedPairCancelTransaction cpct
             JOIN Pool p ON (cpct.id = pool.transaction_id)
             WHERE cpct.user_a = other AND
                   cpct.user_b = invoker AND
                   cpct.num_cookies = num_cookies);
    IF (cpct_id IS NULL) THEN
      -- Create a new cpct
      cpct_id := Blockchain.CreateTransaction('cpct');
      INSERT INTO Blockchain.CombinedPairCancelTransaction (
        id, user_a_transaction, user_b_transaction, user_a, user_b,
        num_cookies)
        VALUES (cpct_id, tid, NULL, invoker, other, num_cookies);
      -- Insert cpct into the pool
      INSERT INTO Blockchain.Pool VALUES (cpct_id);
    ELSE
      -- Update the cpct
      UPDATE Blockchain.CombinedPairCancelTransaction cpct
      SET user_b_transaction = tid
      WHERE cpct.id = cpct_id;
    END IF;
  END
  $$ LANGUAGE plpgsql SECURITY INVOKER;

CREATE OR REPLACE FUNCTION Blockchain.executeGCT(id INT)
  RETURNS VOID AS
  $$
  DECLARE
    invoker TEXT;
    receiver TEXT;
    num_cookies INT;
  BEGIN
    invoker := (SELECT invoker
                FROM Blockchain.GiveCookieTransaction gct
                WHERE gct.id = id);
    receiver := (SELECT receiver
                 FROM Blockchain.GiveCookieTransaction gct
                 WHERE gct.id = id);
    num_cookies := (SELECT num_cookies
                    FROM Blockchain.GiveCookieTransaction gct
                    WHERE gct.id = id);
    UPDATE Blockchain.Debt
    SET cookies_owed = cookies_owed + num_cookies
    WHERE sender_pubk = invoker AND receiver_pubk = receiver;
  END
  $$ LANGUAGE plpgsql SECURITY INVOKER;

CREATE OR REPLACE FUNCTION Blockchain.executeRCT(id INT)
  RETURNS VOID AS
  $$
  DECLARE
    invoker TEXT;
    sender TEXT;
    num_cookies INT;
  BEGIN
    invoker := (SELECT rct.invoker
                FROM Blockchain.ReceiveCookieTransaction rct
                WHERE rct.id = id);
    sender := (SELECT rct.sender
                 FROM Blockchain.RceiveCookieTransaction rct
                 WHERE rct.id = id);
    num_cookies := (SELECT rct.num_cookies
                    FROM Blockchain.RceiveCookieTransaction rct
                    WHERE rct.id = id);
    IF (num_cookies <= (SELECT cookies_owed
                        FROM Blockchain.Debt
                        WHERE sender_pubk = sender AND
                        receiver_pubk = invoker)) THEN
      UPDATE Blockchain.Debt
      SET cookies_owed = cookies_owed - num_cookies
      WHERE sender_pubk = sender AND receiver_pubk = invoker;
    ELSE
      RAISE EXCEPTION 'Number of cookies owed is less than cookies received.';
    END IF;
  END
  $$ LANGUAGE plpgsql SECURITY INVOKER;

CREATE OR REPLACE FUNCTION Blockchain.executeCCCT(id INT)
  RETURNS VOID AS
  $$
  DECLARE
    start_user TEXT;
    mid_user TEXT;
    end_user TEXT;
    num_cookies INT;
  BEGIN
    -- Check if all three candidates have signed the contract
    IF ((SELECT True
         FROM Blockchain.CombinedChainCollapseTransaction ccct
         WHERE ccct.id = id AND
               start_user_transaction IS NOT NULL AND
               mid_user_transaction IS NOT NULL AND
               end_user_transaction IS NOT NULL)) THEN
      -- Obtain user information
      start_user := (SELECT ccct.start_user
                     FROM Blockchain.CombinedChainCollapseTransaction ccct
                     WHERE ccct.id = id);
      mid_user := (SELECT ccct.mid_user
                   FROM Blockchain.CombinedChainCollapseTransaction ccct
                   WHERE ccct.id = id);
      end_user := (SELECT ccct.end_user
                   FROM Blockchain.CombinedChainCollapseTransaction ccct
                   WHERE ccct.id = id);
      -- Obtain number of cookies they wish to collapse
      num_cookies := (SELECT ccct.num_cookies
                      FROM Blockchain.CombinedChainCollapseTransaction ccct
                      WHERE cccct.id = id);
      -- Check that A owes B (and B owes C) enough cookies
      IF (SELECT d1.num_cookies >= num_cookies AND
                 d2.num_cookies >= num_cookies
          FROM Blockchain.Debt d1 JOIN Blockchain.Debt d2 ON
               (d1.sender_pubk = d2.sender_pubk AND
                d1.receiver_pubk = d2.receiver_pubk)
          WHERE d1.sender_pubk = start_user AND
                d1.receiver_pubk = mid_user AND
                d2.sender_pubk = mid_user AND
                d2.receiver_pubk = end_user) THEN
        -- Decrement the number of cookies A owes B
        UPDATE Blockchain.Debt d
        SET d.num_cookies = d.num_cookies - num_cookies
        WHERE d.sender_pubk = start_user AND
              d.receiver_pubk = mid_user;
        -- Decrement the number of cookies B owes C
        UPDATE Blockchain.Debt d
        SET d.num_cookies = d.num_cookies - num_cookies
        WHERE d.sender_pubk = mid_user AND
              d.receiver_pubk = end_user;
        -- Increment the number of cookies A owes C
        UPDATE Blockchain.Debt d
        SET d.num_cookies = d.num_cookies + num_cookies
        WHERE d.sender_pubk = start_user AND
              d.receiver_pubk = end_user;
      ELSE
        RAISE EXCEPTION 'User(s) does not have enough debt.';
      END IF;
    ELSE
      RAISE EXCEPTION 'Transaction incomplete.';
    END IF;
  END
  $$ LANGUAGE plpgsql SECURITY INVOKER;

CREATE OR REPLACE FUNCTION Blockchain.commitBlock(
  new_hash TEXT,
  prev_hash TEXT)
  RETURNS VOID AS
  $$
  DECLARE
    bid INT;
    protocol VARCHAR(4);
    tid RECORD;
  BEGIN
    -- Create a new block
    INSERT INTO Blockchain.Block(curr_hash, prev_hash)
      VALUES (new_hash, prev_hash);
    bid := (SELECT id FROM Blockchain.Block ORDER BY id DESC LIMIT 1);
    -- Add transactions to the new block if successful
    FOR tid IN SELECT transaction_id FROM Blockchain.Pool LOOP
      protocol := (SELECT protocol
                   FROM Blockchain.Transaction t
                   WHERE t.id = tid);
      BEGIN -- Execute code based on protocol
        IF (protocol = 'gct') THEN
          SELECT Blockchian.executeGCT(tid);
        ELSEIF (protocol = 'rct') THEN
          SELECT Blockchian.executeRCT(tid);
        ELSEIF (protocol = 'ccct') THEN
          SELECT Blockchian.executeCCCT(tid);
        END IF;
        -- Insert transaction into the block
        INSERT INTO Blockchain.IncludeTransaction(block, transaction_id)
          VALUES (bid, tid);
        -- Remove transaction from pool
        DELETE FROM Blockchain.Pool WHERE transaction_id = tid;
      EXCEPTION
        WHEN SQLSTATE 'S0001' THEN NULL;
      END;
    END LOOP;
    -- Check if any transaction is submitted, rollback if none.
    IF (NOT EXISTS (SELECT * FROM Blockchain.IncludeTransaction
                WHERE block = bid)) THEN
      ROLLBACK;
    END IF;
  END
  $$ LANGUAGE plpgsql SECURITY INVOKER;
