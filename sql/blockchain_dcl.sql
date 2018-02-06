CREATE OR REPLACE FUNCTION Blockchain.createTransaction(protocol VARCHAR(4))
  RETURNS INT AS
  /* Create a generic transaction

  Returns:
  The transaction_id of the newly created transaction.

  Arguments:
  protocol -- a 3-4 character protocol

  Exception:
  transaction_protocol_check
  */
  $$
  BEGIN
  INSERT INTO Blockchain.Transaction(protocol) VALUES (protocol);
  -- Obtain transaction_id
  RETURN (SELECT id FROM Blockchain.Transaction
          ORDER BY id DESC LIMIT 1);
  END
  $$ LANGUAGE plpgsql SECURITY INVOKER;

CREATE OR REPLACE FUNCTION Blockchain.addAddUserTransaction(new_pubk TEXT)
  RETURNS VOID AS
  /* Add a AddUserTransaction and put it into the pool.

  Arguments:
  new_pubk: public key of the user.
  */
  $$
  DECLARE
    tid INT;
  BEGIN
    tid := Blockchain.createTransaction('aut');
    INSERT INTO Blockchain.AddUserTransaction(id, join_time, user_pubk)
      VALUES (tid, NOW(), new_pubk);
    INSERT INTO Blockchain.Pool(transaction_id) VALUES (tid);
  END
  $$ LANGUAGE plpgsql SECURITY INVOKER;

CREATE OR REPLACE FUNCTION Blockchain.addRemoveUserTransaction(user_pubk TEXT)
  RETURNS VOID AS
  /* Add a RemoveUserTransaction and put it into the pool.

  Arguments:
  user_pubk: public key of the user.
  */
  $$
  DECLARE
    tid INT;
  BEGIN
    tid := Blockchain.createTransaction('rut');
    INSERT INTO Blockchain.RemoveUserTransaction(id, remove_time, user_pubk)
      VALUES (tid, NOW(), user_pubk);
    INSERT INTO Blockchain.Pool(transaction_id) VALUES (tid);
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
    SELECT gct.invoker, gct.receiver, gct.num_cookies
      INTO invoker, receiver, num_cookies
      FROM Blockchain.GiveCookieTransaction gct
     WHERE gct.id = id;
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
    SELECT rct.invoker, rct.sender, rct.num_cookies
      INTO invoker, sender, num_cookies
      FROM Blockchain.ReceiveCookieTransaction rct
     WHERE rct.id = id;
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
      -- Obtain transaction information
      SELECT ccct.start_user, ccct.mid_user, ccct.end_user, ccct.num_cookies
        INTO start_user, mid_user, end_user, num_cookies
        FROM Blockchain.CombinedChainCollapseTransaction ccct
       WHERE ccct.id = id;
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

CREATE OR REPLACE FUNCTION Blockchain.executeCPCT(id INT)
  RETURNS VOID AS
  $$
  DECLARE
    user_a TEXT;
    user_b TEXT;
    num_cookies INT;
  BEGIN
    -- Check if both candidates have signed the contract
    IF ((SELECT True
         FROM Blockchain.CombinedPairCancelTransaction cpct
         WHERE cpct.id = id AND
               user_a_transaction IS NOT NULL AND
               user_b_transaction IS NOT NULL)) THEN
      -- Obtain transaction information
      SELECT cpct.user_a, cpct.user_b, cpct.num_cookies
      INTO user_a, user_b, num_cookies
      FROM Blockchain.CombinedPairCancelTransaction cpct
      WHERE cpct.id = id;
      -- Check that A owes B (and B owes A) enough cookies
      IF (SELECT d1.num_cookies >= num_cookies AND
                 d2.num_cookies >= num_cookies
          FROM Blockchain.Debt d1 JOIN Blockchain.Debt d2 ON
               (d1.sender_pubk = d2.sender_pubk AND
                d1.receiver_pubk = d2.receiver_pubk)
          WHERE d1.sender_pubk = user_a AND
                d1.receiver_pubk = user_b AND
                d2.sender_pubk = user_b AND
                d2.receiver_pubk = user_a) THEN
        -- Decrement the number of cookies A owes B
        UPDATE Blockchain.Debt d
        SET d.num_cookies = d.num_cookies - num_cookies
        WHERE d.sender_pubk = user_a AND
              d.receiver_pubk = user_b;
        -- Decrement the number of cookies B owes C
        UPDATE Blockchain.Debt d
        SET d.num_cookies = d.num_cookies - num_cookies
        WHERE d.sender_pubk = user_b AND
              d.receiver_pubk = user_a;
      ELSE
        RAISE EXCEPTION 'User(s) does not have enough debt.';
      END IF;
    ELSE
      RAISE EXCEPTION 'Transaction incomplete.';
    END IF;
  END
  $$ LANGUAGE plpgsql SECURITY INVOKER;

CREATE OR REPLACE FUNCTION Blockchain.executeAUT(id INT)
  RETURNS VOID AS
  /* Add a user into the database, then add a debt record for this user
  and every other users.

  Arguments:
  new_pubk: public key of the user.
  */
  $$
  DECLARE
    new_pubk TEXT;
    other_pubk TEXT;
  BEGIN
    new_pubk := (SELECT user_pubk FROM Blockchain.AddUserTransaction aut
                 WHERE aut.id = id);
    -- Create User
    INSERT INTO Blockchain.CookieUser(pubk) VALUES (new_pubk);
    -- Create debts
    FOR other_pubk IN SELECT u.pubk
                      FROM Blockchain.CookieUser u
                      WHERE u.pubk != new_pubk AND u.valid LOOP
      INSERT INTO Blockchain.Debt(sender_pubk, receiver_pubk, cookies_owed)
        VALUES (other_pubk, new_pubk, 0);
      INSERT INTO Blockchain.Debt(sender_pubk, receiver_pubk, cookies_owed)
        VALUES (new_pubk, other_pubk, 0);
    END LOOP;
  END
  $$ LANGUAGE plpgsql SECURITY INVOKER;

CREATE OR REPLACE FUNCTION Blockchain.executeRUT(id INT)
  RETURNS VOID AS
  /* Remove a user from the database.

  Arguments:
  pubk: public key of the user.
  */
  $$
  DECLARE
    pubk TEXT;
  BEGIN
    pubk := (SELECT user_pubk FROM Blockchain.RemoveUserTransaction rut
             WHERE rut.id = id);
    UPDATE Blockchain.CookieUser u
      SET valid = FALSE
    WHERE u.pubk = pubk;
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
    insert_time TIMESTAMP;
    tid INT;
    timeout INTERVAL := INTERVAL '12 hours';
  BEGIN
    -- Create a new block
    INSERT INTO Blockchain.Block(curr_hash, prev_hash)
      VALUES (new_hash, prev_hash);
    bid := (SELECT id FROM Blockchain.Block ORDER BY id DESC LIMIT 1);
    -- Add transactions to the new block if successful
    FOR insert_time, tid IN SELECT insert_time, transaction_id
                            FROM Blockchain.Pool LOOP
      -- Check how long the transaction has been in the pool
      IF (NOW() - insert_time > timeout) THEN
        DELETE FROM Blockchain.Pool WHERE transaction_id = tid;
        CONTINUE;
      END IF;
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
        ELSEIF (protocol = 'cpct') THEN
          SELECT Blockchian.executeCPCT(tid);
        ELSEIF (protocol = 'aut') THEN
          SELECT Blockchain.executeAUT(tid);
        ELSEIF (protocol = 'rut') THEN
          SELECT Blockchain.executeRUT(tid);
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