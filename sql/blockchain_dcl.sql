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
    SELECT Blockchain.createTransaction('aut') INTO tid;
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
    SELECT Blockchain.createTransaction('rut') INTO tid;
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
      ttime TIMESTAMPTZ;
    BEGIN
      -- Create a generic transaction
      SELECT Blockchain.CreateTransaction('gct') INTO tid;
      -- Obtain block_id
      SELECT id INTO bid
        FROM Blockchain.Block
        WHERE curr_hash = recent_hash;
      -- Convert unix time into TIMESTAMPTZ format
      SELECT to_timestamp(transaction_time) INTO ttime;
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
    ttime TIMESTAMPTZ;
  BEGIN
    -- Create a generic transaction
    SELECT Blockchain.CreateTransaction('rct') INTO tid;
    -- Obtain block_id
    SELECT id INTO bid
      FROM Blockchain.Block
      WHERE curr_hash = recent_hash;
    -- Convert unix time into TIMESTAMPTZ format
    SELECT to_timestamp(transaction_time) INTO ttime;
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

CREATE OR REPLACE FUNCTION Blockchain.addChainCollapseTransaction(
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
      ttime TIMESTAMPTZ;
      ccct_id INT;
    BEGIN
      -- Create a generic transaction
      SELECT Blockchain.CreateTransaction('cct') INTO tid;
      -- Obtain block_id
      SELECT id INTO bid
        FROM Blockchain.Block
        WHERE curr_hash = recent_hash;
      -- Obtain ttime in TIMESTAMPTZ format
      SELECT to_timestamp(transaction_time) INTO ttime;
      -- Create ChainCollapseTransaction
      INSERT INTO Blockchain.CombinedChainCollapseTransaction(
        id, invoker, transaction_time, recent_block, signature
        ) VALUES (tid, invoker, ttime, bid, signature);
      -- Check if CombinedChainCollapseTransaction exists
      SELECT id INTO ccct_id
        FROM Blockchain.CombinedChainCollapseTransaction ccct
        JOIN Pool p ON (ccct.id = pool.transaction_id)
        WHERE ccct.start_user = start_user AND
              ccct.mid_user = mid_user AND
              ccct.end_user = end_user AND
              ccct.num_cookies = num_cookies;
      IF (ccct_id IS NULL) THEN
        -- Create a new ccct
        SELECT Blockchain.CreateTransaction('ccct') INTO ccct_id;
        INSERT INTO Blockchain.CombinedChainCollapseTransaction (
          id, start_user, mid_user, end_user, start_user_transaction,
          mid_user_transaction, end_user_transaction, num_cookies
          ) VALUES (ccct_id, start_user, mid_user, end_user, NULL, NULL,
                    NULL, num_cookies);
        -- Insert ccct into pool
        INSERT INTO Blockchain.Pool VALUES (ccct_id);
      END IF;
      -- Update ccct
      IF (invoker = start_user) THEN
        UPDATE Blockchain.CombinedChainCollapseTransaction ccct
        SET start_user_transaction = tid
        WHERE ccct.id = ccct_id;
      ELSEIF (invoker = mid_user) THEN
        UPDATE Blockchain.CombinedChainCollapseTransaction ccct
        SET mid_user_transaction = tid
        WHERE ccct.id = ccct_id;
      ELSE
        UPDATE Blockchain.CombinedChainCollapseTransaction ccct
        SET end_user_transaction = tid
        WHERE ccct.id = ccct_id;
      END IF;
    END
  $$ LANGUAGE plpgsql SECURITY INVOKER;


CREATE OR REPLACE FUNCTION Blockchain.addPairCancelTransaction(
  invoker TEXT,
  other TEXT,
  transaction_time DOUBLE PRECISION,
  recent_hash TEXT,
  num_cookies INT,
  signature TEXT)
  RETURNS VOID AS
  $$
  DECLARE
    tid INT;
    bid INT;
    ttime TIMESTAMPTZ;
    cpct_id INT;
  BEGIN
    -- Create a generic transaction
    SELECT Blockchain.createTransaction('pct') INTO tid;
    -- Obtain block_id
    SELECT id INTO bid
      FROM Blockchain.Block
      WHERE curr_hash = recent_hash;
    -- Obtain ttime in TIMESTAMPTZ format
    SELECT to_timestamp(transaction_time) INTO ttime;
    SELECT id INTO cpct_id
      FROM Blockchain.CombinedPairCancelTransaction cpct
      JOIN Pool p ON (cpct.id = pool.transaction_id)
      WHERE cpct.user_a = other AND
            cpct.user_b = invoker AND
            cpct.num_cookies = num_cookies;
    IF (cpct_id IS NULL) THEN
      -- Create a new cpct
      SELECT Blockchain.CreateTransaction('cpct') INTO cpct_id;
      INSERT INTO Blockchain.CombinedPairCancelTransaction (
        id, user_a_transaction, user_b_transaction, user_a, user_b,
        num_cookies
        ) VALUES (cpct_id, tid, NULL, invoker, other, num_cookies);
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

CREATE OR REPLACE FUNCTION Blockchain.executeGCT(tid INT)
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
     WHERE gct.id = tid;
    -- Check again to see if the user is still valid
    IF ((SELECT Blockchain.isValidUser(invoker)) AND
        (SELECT Blockchain.IsValidUser(receiver))) THEN
      UPDATE Blockchain.Debt
         SET cookies_owed = cookies_owed + num_cookies
       WHERE sender_pubk = invoker AND receiver_pubk = receiver;
    ELSE
      RAISE EXCEPTION SQLSTATE '45001' USING
        MESSAGE = 'Users are no longer valid.';
    END IF;
  END
  $$ LANGUAGE plpgsql SECURITY INVOKER;

CREATE OR REPLACE FUNCTION Blockchain.executeRCT(tid INT)
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
     WHERE rct.id = tid;
    IF ((SELECT Blockchain.isValidUser(invoker)) AND
        (SELECT Blockchain.isValidUser(sender))) THEN
      IF (num_cookies <= (SELECT cookies_owed
                          FROM Blockchain.Debt
                          WHERE sender_pubk = sender AND
                          receiver_pubk = invoker)) THEN
        UPDATE Blockchain.Debt
        SET cookies_owed = cookies_owed - num_cookies
        WHERE sender_pubk = sender AND receiver_pubk = invoker;
      ELSE
        RAISE EXCEPTION SQLSTATE '45000' USING
          MESSAGE = 'Number of cookies owed is less than cookies received.';
      END IF;
    ELSE
      RAISE EXCEPTION SQLSTATE '45001' USING
        MESSAGE = 'Users no longer valid';
    END IF;
  END
  $$ LANGUAGE plpgsql SECURITY INVOKER;

CREATE OR REPLACE FUNCTION Blockchain.executeCCCT(tid INT)
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
          WHERE ccct.id = tid AND
               start_user_transaction IS NOT NULL AND
               mid_user_transaction IS NOT NULL AND
               end_user_transaction IS NOT NULL)) THEN
      -- Obtain transaction information
      SELECT ccct.start_user, ccct.mid_user, ccct.end_user, ccct.num_cookies
        INTO start_user, mid_user, end_user, num_cookies
        FROM Blockchain.CombinedChainCollapseTransaction ccct
       WHERE ccct.id = tid;
      IF ((SELECT Blockchain.isValidUser(start_user)) AND
          (SELECT Blockchain.isValidUser(mid_user)) AND
          (SELECT Blockchain.isValidUser(end_user))) THEN
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
          RAISE EXCEPTION SQLSTATE '45000' USING
            MESSAGE = 'User(s) does not have enough debt.';
        END IF;
      ELSE
        RAISE EXCEPTION SQLSTATE '45001' USING
          MESSAGE = 'Users are no longer valid.';
      END IF;
    ELSE
      RAISE EXCEPTION SQLSTATE '45000' USING
        MESSAGE = 'Transaction incomplete.';
    END IF;
  END
  $$ LANGUAGE plpgsql SECURITY INVOKER;

CREATE OR REPLACE FUNCTION Blockchain.executeCPCT(tid INT)
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
         WHERE cpct.id = tid AND
               user_a_transaction IS NOT NULL AND
               user_b_transaction IS NOT NULL)) THEN
      -- Obtain transaction information
      SELECT cpct.user_a, cpct.user_b, cpct.num_cookies
      INTO user_a, user_b, num_cookies
      FROM Blockchain.CombinedPairCancelTransaction cpct
      WHERE cpct.id = tid;
      IF ((SELECT Blockchain.isValidUser(user_a)) AND
          (SELECT Blockchain.isValidUser(user_b))) THEN
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
          RAISE EXCEPTION SQLSTATE '45000' USING
            MESSAGE = 'User(s) does not have enough debt.';
        END IF;
      ELSE
        RAISE EXCEPTION SQLSTATE '45001' USING
          MESSAGE = 'Users are not longer valid.';
      END IF;
    ELSE
      RAISE EXCEPTION SQLSTATE '45000' USING
        MESSAGE = 'Transaction incomplete.';
    END IF;
  END
  $$ LANGUAGE plpgsql SECURITY INVOKER;

CREATE OR REPLACE FUNCTION Blockchain.executeAUT(tid INT)
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
    SELECT aut.user_pubk INTO new_pubk
      FROM Blockchain.AddUserTransaction aut
      WHERE aut.id = tid;
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
    SELECT user_pubk INTO pubk
      FROM Blockchain.RemoveUserTransaction rut
      WHERE rut.id = id;
    UPDATE Blockchain.CookieUser u
      SET valid = FALSE
    WHERE u.pubk = pubk;
  END
  $$ LANGUAGE plpgsql SECURITY INVOKER;

CREATE OR REPLACE FUNCTION Blockchain.commitBlock(
  new_hash TEXT,
  prev_hash TEXT)
  RETURNS BOOLEAN AS
  $$
  /* Commit every transaction in the pool

  Arguments:
  new_hash: Hash of the new block
  prev_hash: Hash of previous block

  Returns:
  TRUE if a block is committed successfully, FALSE otherwise.
  */
  DECLARE
    bid INT;
    protocol VARCHAR(4);
    insert_time TIMESTAMPTZ;
    tid INT;
    timeout INTERVAL := INTERVAL '12 hours';
  BEGIN
    -- Create a new block
    INSERT INTO Blockchain.Block(curr_hash, prev_hash)
      VALUES (new_hash, prev_hash);
    SELECT id INTO bid
      FROM Blockchain.Block
      ORDER BY id DESC
      LIMIT 1;
    -- Add transactions to the new block if successful
    FOR insert_time, tid IN SELECT p.insert_time, transaction_id
                            FROM Blockchain.Pool p LOOP
      -- Check how long the transaction has been in the pool
      IF (NOW() - insert_time > timeout) THEN
        DELETE FROM Blockchain.Pool WHERE transaction_id = tid;
        CONTINUE;
      END IF;
      -- Obtain protocol
      SELECT t.protocol INTO protocol
        FROM Blockchain.Transaction t
        WHERE t.id = tid;
      BEGIN -- Execute code based on protocol
        IF (protocol = 'gct') THEN
          PERFORM Blockchain.executeGCT(tid);
        ELSEIF (protocol = 'rct') THEN
          PERFORM Blockchain.executeRCT(tid);
        ELSEIF (protocol = 'ccct') THEN
          PERFORM Blockchain.executeCCCT(tid);
        ELSEIF (protocol = 'cpct') THEN
          PERFORM Blockchain.executeCPCT(tid);
        ELSEIF (protocol = 'aut') THEN
          PERFORM Blockchain.executeAUT(tid);
        ELSEIF (protocol = 'rut') THEN
          PERFORM Blockchain.executeRUT(tid);
        END IF;
        -- Insert transaction into the block
        INSERT INTO Blockchain.IncludeTransaction(block, transaction_id)
          VALUES (bid, tid);
        -- Remove transaction from pool
        DELETE FROM Blockchain.Pool WHERE transaction_id = tid;
      EXCEPTION
        WHEN SQLSTATE '45000' THEN
          IF (INTERVAL '12 hours' < (SELECT NOW() - p.insert_time
                                     FROM Blockchain.Pool p
                                     WHERE p.transaction_id = tid)) THEN
            DELETE FROM Blockchain.Transaction WHERE id = tid;
          END IF;
        WHEN SQLSTATE '45001' THEN -- Discard transaction
          DELETE FROM Blockchain.Transaction WHERE id = tid;
      END;
    END LOOP;
    -- Check if any transaction is submitted, rollback if none.
    IF (NOT EXISTS (SELECT * FROM Blockchain.IncludeTransaction
                WHERE block = bid)) THEN
      -- Delete created block
      DELETE FROM Blockchain.Block WHERE id = bid;
      RETURN FALSE;
    END IF;
    RETURN TRUE;
  END
  $$ LANGUAGE plpgsql SECURITY INVOKER;


CREATE OR REPLACE FUNCTION Blockchain.getBlockchain(hash TEXT)
  RETURNS TABLE (block_hash TEXT,
                 transaction_id INT,
                 transaction_protocol VARCHAR(4)) AS
  /* Return all transaction ids and protocols up to "hash"

  Arguments:
  hash: Return blockchain information up to this hash

  Returns:
  A table containing (block_hash, transaction_id, transaction_protocol)
  */
  $$
  SELECT curr_hash, t.id, protocol
  FROM Blockchain.IncludeTransaction it
      JOIN Blockchain.Block b ON (block = b.id)
      JOIN Blockchain.Transaction t ON (transaction_id = t.id)
  WHERE b.id > (SELECT b2.id
                FROM Blockchain.Block b2
                WHERE b2.curr_hash = hash)
  $$ LANGUAGE sql SECURITY INVOKER;


CREATE OR REPLACE FUNCTION Blockchain.getGCT(param_id INT)
  RETURNS TABLE (invoker TEXT,
                 ttime DOUBLE PRECISION,
                 receiver TEXT,
                 recent_block_hash TEXT,
                 num_cookies INT,
                 reason VARCHAR(100),
                 signature TEXT) AS
  /* get all information associated to a GCT.

  Returns:
  A table containing GCT related information
  */
  $$
  SELECT invoker, extract(epoch FROM transaction_time) as ttime,
         receiver, b.curr_hash, num_cookies, reason, signature
  FROM Blockchain.GiveCookieTransaction gct
    JOIN Blockchain.Block b ON (gct.recent_block = b.id)
  WHERE gct.id = param_id
  $$ LANGUAGE sql SECURITY INVOKER;
